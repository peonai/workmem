#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { pathToFileURL } from 'url';

function readJsonFromStdin() {
  try {
    const raw = readFileSync(0, 'utf8').trim();
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function readUsage(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    return null;
  }
}

function logSyntheticUsage(path, tools) {
  mkdirSync(dirname(path), { recursive: true });
  let usage = { lastUsedAt: null, tools: [] };
  try {
    usage = JSON.parse(readFileSync(path, 'utf8'));
  } catch {}
  const existing = Array.isArray(usage.tools) ? usage.tools : [];
  const merged = [...tools, ...existing.filter((tool) => !tools.includes(tool))].slice(0, 12);
  const next = {
    lastUsedAt: new Date().toISOString(),
    tools: merged,
  };
  writeFileSync(path, JSON.stringify(next, null, 2));
}

const argEventIndex = process.argv.indexOf('--event');
const forcedEvent = argEventIndex >= 0 ? process.argv[argEventIndex + 1] : null;
const input = readJsonFromStdin();
const eventName = forcedEvent || input.hook_event_name || 'Lifecycle';
const cwd = input.cwd || process.cwd();
const memoryRoot = join(cwd, '.agent', 'memory');
const reviewDir = join(memoryRoot, '.runtime');
const reviewFile = join(reviewDir, 'pending-review.md');
const episodicFile = join(memoryRoot, 'episodic', `${today()}.md`);
const mcpUsageFile = join(reviewDir, 'mcp-usage.json');

mkdirSync(reviewDir, { recursive: true });

if (!existsSync(episodicFile)) {
  writeFileSync(episodicFile, `# ${today()}\n\n## Work Log\n- \n\n## Findings\n- \n\n## Follow-ups\n- \n`, 'utf8');
}

// Mechanize the default memory maintenance sequence instead of hoping Claude will do it.
const syncModule = await import(pathToFileURL(join(cwd, '.claude', 'plugins', 'workmem', 'scripts', 'memory', 'sync.js')).href);
const reindexModule = await import(pathToFileURL(join(cwd, '.claude', 'plugins', 'workmem', 'scripts', 'memory', 'reindex.js')).href);

let autoSyncOk = false;
let autoReindexOk = false;
let syncStdout = '';
let reindexStdout = '';
let autoError = null;

try {
  const syncResult = await syncModule.runCli({ cwd, silent: true });
  syncStdout = syncResult?.stdout || '';
  autoSyncOk = true;

  const reindexResult = await reindexModule.runCli({ cwd, silent: true });
  reindexStdout = reindexResult?.stdout || '';
  autoReindexOk = true;

  logSyntheticUsage(mcpUsageFile, ['workmem_reindex', 'workmem_sync', 'workmem_read']);
} catch (error) {
  autoError = error instanceof Error ? error.message : String(error);
}

const usage = readUsage(mcpUsageFile);
const now = Date.now();
const lastUsedAt = usage?.lastUsedAt ? Date.parse(usage.lastUsedAt) : 0;
const recentWindowMs = 15 * 60 * 1000;
const usedRecently = Number.isFinite(lastUsedAt) && now - lastUsedAt <= recentWindowMs;
const usedTools = Array.isArray(usage?.tools) ? usage.tools : [];
const writeClassTools = new Set([
  'workmem_write',
  'workmem_promote',
  'workmem_sync',
  'workmem_reindex',
  'workmem_topic_create',
  'workmem_archive',
  'workmem_compact',
]);
const usedWriteClassTool = usedTools.some((tool) => writeClassTools.has(tool));

const reviewContent = [
  '# Pending Memory Review',
  '',
  'This file is managed by the workmem Claude Code plugin.',
  '',
  `Last trigger: ${eventName}`,
  `Recent MCP usage detected: ${usedRecently ? 'yes' : 'no'}`,
  `Recent MCP write-class usage detected: ${usedWriteClassTool ? 'yes' : 'no'}`,
  `Automatic sync executed: ${autoSyncOk ? 'yes' : 'no'}`,
  `Automatic reindex executed: ${autoReindexOk ? 'yes' : 'no'}`,
  usedTools.length ? `Recent tools: ${usedTools.join(', ')}` : 'Recent tools: none',
  autoError ? `Automatic maintenance error: ${autoError}` : 'Automatic maintenance error: none',
  '',
  'Mechanized default memory sequence:',
  '- `workmem_read`',
  '- `workmem_sync`',
  '- `workmem_reindex`',
  '',
  'Artifacts:',
  syncStdout ? `- sync: ${syncStdout.trim()}` : '- sync: none',
  reindexStdout ? `- reindex: ${reindexStdout.trim()}` : '- reindex: none',
  ''
].join('\n');

writeFileSync(reviewFile, reviewContent, 'utf8');

if (usedRecently && usedWriteClassTool && autoSyncOk && autoReindexOk) {
  process.exit(0);
}

const context = [
  `workmem lifecycle review fired at ${eventName}.`,
  'The system attempted the default memory maintenance sequence automatically: `workmem_read -> workmem_sync -> workmem_reindex`.',
  autoError ? `Automatic maintenance hit an error: ${autoError}` : 'Automatic maintenance completed.',
  'Review `.agent/memory/.runtime/pending-review.md` if further manual cleanup is needed.'
].join('\n\n');

process.stdout.write(JSON.stringify({
  decision: autoError ? 'block' : 'approve',
  reason: context
}));
