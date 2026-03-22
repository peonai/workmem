#!/usr/bin/env node
import { join } from 'path';
import { latestEpisodicPath, listMarkdown, memoryRoot, parseArgs, readPreview, readText, routeTypeToDir } from './common.js';

export async function runCli({ cwd = process.cwd(), args = {}, silent = false } = {}) {
  const base = memoryRoot(cwd);
  const lines = Number(args.lines || 40);
  const kind = args.kind || 'index';
  let stdout = '';

  if (kind === 'index') {
    stdout = readText(join(base, 'MEMORY.md')) || '';
  } else if (kind === 'latest-episodic') {
    stdout = readText(latestEpisodicPath(base)) || '';
  } else if (kind === 'list') {
    const type = args.type || 'semantic';
    stdout = JSON.stringify(listMarkdown(routeTypeToDir(base, type)), null, 2);
  } else if (kind === 'topic') {
    const type = args.type;
    const file = args.file;
    if (!type || !file) throw new Error('read.js: --type and --file are required for --kind topic');
    stdout = readPreview(join(routeTypeToDir(base, type), file), lines) || '';
  } else {
    throw new Error(`read.js: unsupported --kind ${kind}`);
  }

  if (!silent) process.stdout.write(stdout);
  return { stdout };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node read.js --kind index|latest-episodic|topic|list --type semantic|procedural|episodic --file <name> [--lines 40] [--cwd /path]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
