#!/usr/bin/env node
import { basename, join } from 'path';
import { memoryRoot, parseArgs, readText, writeText, ensureDir } from './common.js';

export async function runCli({ cwd = process.cwd(), args = {}, silent = false } = {}) {
  const source = args.source;
  const note = args.note || 'archived by workmem';
  if (!source) throw new Error('archive.js: --source is required');

  const base = memoryRoot(cwd);
  const sourcePath = join(base, source);
  const content = readText(sourcePath);
  if (content == null) throw new Error(`archive.js: source not found: ${source}`);

  const legacyDir = join(base, 'legacy');
  ensureDir(legacyDir);
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const targetPath = join(legacyDir, `${stamp}-${basename(source)}`);
  const wrapped = `${content.trimEnd()}\n\n---\nArchived from \`${source}\`\nNote: ${note}\n`;
  writeText(targetPath, wrapped);

  if (!silent) console.log(targetPath);
  return { stdout: `${targetPath}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node archive.js --source semantic/foo.md [--note "why"] [--cwd /path]');
    process.exit(0);
  }
  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
