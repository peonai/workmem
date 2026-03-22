#!/usr/bin/env node
import { appendFileSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';

export function ensureDir(path) {
  mkdirSync(path, { recursive: true });
}

export function today() {
  return new Date().toISOString().slice(0, 10);
}

export function memoryRoot(cwd) {
  return join(cwd, '.agent', 'memory');
}

export function latestEpisodicPath(base) {
  const dir = join(base, 'episodic');
  if (!existsSync(dir)) return join(dir, `${today()}.md`);
  const files = readdirSync(dir).filter((name) => name.endsWith('.md')).sort();
  return join(dir, files.length ? files[files.length - 1] : `${today()}.md`);
}

export function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith('--')) {
      out._.push(arg);
      continue;
    }
    const key = arg.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      out[key] = true;
      continue;
    }
    out[key] = next;
    i += 1;
  }
  return out;
}

export function readStdin() {
  try {
    return readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

export function readText(path) {
  return existsSync(path) ? readFileSync(path, 'utf8') : null;
}

export function ensureParent(path) {
  ensureDir(dirname(path));
}

export function writeText(path, content) {
  ensureParent(path);
  writeFileSync(path, content, 'utf8');
}

export function appendText(path, content) {
  ensureParent(path);
  appendFileSync(path, content, 'utf8');
}

export function listMarkdown(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((name) => name.endsWith('.md'))
    .map((name) => ({
      name,
      path: join(dir, name),
      size: statSync(join(dir, name)).size,
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function readPreview(path, maxLines = 40) {
  const text = readText(path);
  if (!text) return null;
  return text.split(/\r?\n/).slice(0, maxLines).join('\n');
}

export function routeTypeToDir(base, type) {
  if (type === 'semantic') return join(base, 'semantic');
  if (type === 'procedural') return join(base, 'procedural');
  if (type === 'episodic') return join(base, 'episodic');
  throw new Error(`Unsupported type: ${type}`);
}
