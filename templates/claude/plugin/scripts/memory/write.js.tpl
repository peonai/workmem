#!/usr/bin/env node
import { basename, join } from 'path';
import { appendText, memoryRoot, parseArgs, readStdin, readText, routeTypeToDir, writeText } from './common.js';

export async function runCli({ cwd = process.cwd(), args = {}, stdinText = '', silent = false } = {}) {
  const type = args.type;
  const file = args.file;
  const mode = args.mode || 'append';
  const input = args.text || stdinText || readStdin();

  if (!type || !file) throw new Error('write.js: --type and --file are required');

  const base = memoryRoot(cwd);
  const dir = routeTypeToDir(base, type);
  const normalizedFile = basename(file);
  const path = join(dir, normalizedFile.endsWith('.md') ? normalizedFile : `${normalizedFile}.md`);

  if (mode === 'replace') {
    writeText(path, input.endsWith('\n') ? input : `${input}\n`);
  } else {
    const prefix = readText(path) ? '\n' : '';
    appendText(path, `${prefix}${input.endsWith('\n') ? input : `${input}\n`}`);
  }

  if (!silent) console.log(path);
  return { stdout: `${path}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: echo "text" | node write.js --type semantic|procedural|episodic --file <name> [--mode append|replace] [--cwd /path]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
