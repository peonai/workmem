#!/usr/bin/env node
import { existsSync, readFileSync, readdirSync } from 'fs';
import { join } from 'path';

function readJsonFromStdin() {
  try {
    const raw = readFileSync(0, 'utf8').trim();
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function readPreview(path, maxLines = 12) {
  if (!existsSync(path)) return null;
  const lines = readFileSync(path, 'utf8')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .slice(0, maxLines);
  return lines.length ? lines.join('\n') : null;
}

function latestMarkdownFile(dir) {
  if (!existsSync(dir)) return null;
  const files = readdirSync(dir)
    .filter((name) => name.endsWith('.md'))
    .sort();
  return files.length ? join(dir, files[files.length - 1]) : null;
}

const input = readJsonFromStdin();
const cwd = input.cwd || process.cwd();
const base = join(cwd, '.agent', 'memory');

const sections = [
  'workmem plugin is active for this project.',
  'Use `.agent/memory/MEMORY.md` as the routing layer, then read only the topic files needed for the task.',
  'Prefer workmem over Claude auto-memory for repo-specific continuity.',
  'When workmem MCP tools are available, use them as the default memory interface instead of manually editing markdown files.',
  'If this session updates memory, use the default maintenance sequence: workmem_read -> workmem_sync -> workmem_reindex.',
  'Promote durable knowledge from episodic notes into semantic/procedural files as the project evolves.'
];

const indexPreview = readPreview(join(base, 'MEMORY.md'), 16);
const activePreview = readPreview(join(base, 'semantic', 'active-context.md'), 12);
const latestEpisodic = latestMarkdownFile(join(base, 'episodic'));
const episodicPreview = latestEpisodic ? readPreview(latestEpisodic, 12) : null;

if (indexPreview) sections.push(`MEMORY.md preview:\n${indexPreview}`);
if (activePreview) sections.push(`semantic/active-context.md preview:\n${activePreview}`);
if (episodicPreview && latestEpisodic) {
  const label = latestEpisodic.split('/').pop();
  sections.push(`latest episodic preview (${label}):\n${episodicPreview}`);
}

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'SessionStart',
    additionalContext: sections.join('\n\n')
  }
}));
