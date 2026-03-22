#!/usr/bin/env node
import { join } from 'path';
import { appendText, latestEpisodicPath, memoryRoot, parseArgs, readStdin, routeTypeToDir } from './common.js';

export async function runCli({ cwd = process.cwd(), args = {}, stdinText = '', silent = false } = {}) {
  const to = args.to;
  const file = args.file;
  const text = args.text || stdinText || readStdin();

  if (!to || !file || !text.trim()) throw new Error('promote.js: --to, --file, and input text are required');

  const base = memoryRoot(cwd);
  const dest = join(routeTypeToDir(base, to), file.endsWith('.md') ? file : `${file}.md`);
  appendText(dest, `${text.endsWith('\n') ? text : `${text}\n`}`);

  const source = args.from || 'latest-episodic';
  if (source === 'latest-episodic') {
    const episodic = latestEpisodicPath(base);
    appendText(episodic, `\n- promoted to ${to}/${file.endsWith('.md') ? file : `${file}.md`}\n`);
  }

  if (!silent) console.log(dest);
  return { stdout: `${dest}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: echo "bullet" | node promote.js --to semantic|procedural --file <topic.md> [--from latest-episodic] [--cwd /path]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
