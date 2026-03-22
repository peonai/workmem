#!/usr/bin/env node
import { mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { pathToFileURL } from 'url';

const cwd = process.cwd();
const base = join(cwd, '.claude', 'plugins', 'workmem', 'scripts', 'memory');
const usageFile = join(cwd, '.agent', 'memory', '.runtime', 'mcp-usage.json');

const modules = {
  read: await import(pathToFileURL(join(base, 'read.js')).href),
  write: await import(pathToFileURL(join(base, 'write.js')).href),
  promote: await import(pathToFileURL(join(base, 'promote.js')).href),
  reindex: await import(pathToFileURL(join(base, 'reindex.js')).href),
  review: await import(pathToFileURL(join(base, 'review.js')).href),
  sync: await import(pathToFileURL(join(base, 'sync.js')).href),
  topicCreate: await import(pathToFileURL(join(base, 'topic-create.js')).href),
  archive: await import(pathToFileURL(join(base, 'archive.js')).href),
  compact: await import(pathToFileURL(join(base, 'compact.js')).href),
};

function send(message) {
  process.stdout.write(JSON.stringify(message) + '\n');
}

function ok(id, result) {
  send({ jsonrpc: '2.0', id, result });
}

function fail(id, message) {
  send({ jsonrpc: '2.0', id, error: { code: -32000, message } });
}

function textResult(text) {
  return { content: [{ type: 'text', text }] };
}

function logToolUsage(name) {
  mkdirSync(dirname(usageFile), { recursive: true });
  let usage = { lastUsedAt: null, tools: [] };
  try {
    usage = JSON.parse(readFileSync(usageFile, 'utf8'));
  } catch {}
  const tools = Array.isArray(usage.tools) ? usage.tools.filter((tool) => tool !== name) : [];
  tools.unshift(name);
  const next = {
    lastUsedAt: new Date().toISOString(),
    tools: tools.slice(0, 12),
  };
  writeFileSync(usageFile, JSON.stringify(next, null, 2));
}

async function callMemoryScript(kind, args = {}, stdinText = '') {
  const mod = modules[kind];
  if (!mod || typeof mod.runCli !== 'function') {
    throw new Error(`Unknown memory operation: ${kind}`);
  }
  return await mod.runCli({ cwd, args, stdinText, silent: true });
}

const tools = [
  {
    name: 'workmem_read',
    description: 'Read workmem index, latest episodic note, or a specific topic file.',
    inputSchema: {
      type: 'object',
      properties: {
        kind: { type: 'string', enum: ['index', 'latest-episodic', 'topic', 'list'] },
        type: { type: 'string', enum: ['semantic', 'procedural', 'episodic'] },
        file: { type: 'string' },
        lines: { type: 'number' }
      },
      required: ['kind']
    }
  },
  {
    name: 'workmem_write',
    description: 'Append or replace content in a workmem topic file.',
    inputSchema: {
      type: 'object',
      properties: {
        type: { type: 'string', enum: ['semantic', 'procedural', 'episodic'] },
        file: { type: 'string' },
        mode: { type: 'string', enum: ['append', 'replace'] },
        text: { type: 'string' }
      },
      required: ['type', 'file', 'text']
    }
  },
  {
    name: 'workmem_promote',
    description: 'Promote durable text from episodic notes into semantic or procedural memory.',
    inputSchema: {
      type: 'object',
      properties: {
        to: { type: 'string', enum: ['semantic', 'procedural'] },
        file: { type: 'string' },
        text: { type: 'string' }
      },
      required: ['to', 'file', 'text']
    }
  },
  {
    name: 'workmem_review',
    description: 'Generate a promotion plan from the latest episodic note.',
    inputSchema: {
      type: 'object',
      properties: {
        format: { type: 'string', enum: ['markdown', 'json'] }
      }
    }
  },
  {
    name: 'workmem_sync',
    description: 'Run a heuristic sync from latest episodic note into semantic/procedural memory.',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'workmem_reindex',
    description: 'Rebuild MEMORY.md from the current topic tree.',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'workmem_topic_create',
    description: 'Create a new semantic, procedural, or episodic topic file.',
    inputSchema: {
      type: 'object',
      properties: {
        type: { type: 'string', enum: ['semantic', 'procedural', 'episodic'] },
        file: { type: 'string' },
        title: { type: 'string' }
      },
      required: ['type', 'file']
    }
  },
  {
    name: 'workmem_archive',
    description: 'Archive a topic file into legacy memory.',
    inputSchema: {
      type: 'object',
      properties: {
        source: { type: 'string' },
        note: { type: 'string' }
      },
      required: ['source']
    }
  },
  {
    name: 'workmem_compact',
    description: 'Trim high-churn memory files down to recent bullets.',
    inputSchema: {
      type: 'object',
      properties: {
        keep: { type: 'number' }
      }
    }
  }
];

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', async (chunk) => {
  buffer += chunk;
  const lines = buffer.split('\n');
  buffer = lines.pop() || '';

  for (const line of lines) {
    if (!line.trim()) continue;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch {
      continue;
    }

    const { id, method, params } = msg;

    try {
      if (method === 'initialize') {
        ok(id, {
          protocolVersion: '2024-11-05',
          capabilities: { tools: {} },
          serverInfo: { name: 'workmem-mcp', version: '{{VERSION}}' }
        });
        continue;
      }

      if (method === 'notifications/initialized') {
        continue;
      }

      if (method === 'tools/list') {
        ok(id, { tools });
        continue;
      }

      if (method === 'tools/call') {
        const name = params?.name;
        const args = params?.arguments || {};

        const run = async (kind, stdinText = '') => {
          const out = await callMemoryScript(kind, args, stdinText);
          logToolUsage(name);
          ok(id, textResult(out.stdout));
        };

        if (name === 'workmem_read') { await run('read'); continue; }
        if (name === 'workmem_write') { await run('write', args.text || ''); continue; }
        if (name === 'workmem_promote') { await run('promote', args.text || ''); continue; }
        if (name === 'workmem_review') { await run('review'); continue; }
        if (name === 'workmem_sync') { await run('sync'); continue; }
        if (name === 'workmem_reindex') { await run('reindex'); continue; }
        if (name === 'workmem_topic_create') { await run('topicCreate'); continue; }
        if (name === 'workmem_archive') { await run('archive'); continue; }
        if (name === 'workmem_compact') { await run('compact'); continue; }

        fail(id, `Unsupported tool: ${name}`);
        continue;
      }

      fail(id, `Unsupported method: ${method}`);
    } catch (error) {
      fail(id, error instanceof Error ? error.message : String(error));
    }
  }
});
