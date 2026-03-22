#!/usr/bin/env node
import { basename, join } from 'path';
import { memoryRoot, parseArgs, routeTypeToDir, writeText, readText } from './common.js';

function titleFromFile(file) {
  return basename(file, '.md')
    .split(/[-_]/g)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

export async function runCli({ cwd = process.cwd(), args = {}, silent = false } = {}) {
  const type = args.type;
  const file = args.file;
  const title = args.title;

  if (!type || !file) throw new Error('topic-create.js: --type and --file are required');

  const base = memoryRoot(cwd);
  const dir = routeTypeToDir(base, type);
  const normalized = file.endsWith('.md') ? file : `${file}.md`;
  const path = join(dir, normalized);

  if (!readText(path)) {
    const finalTitle = title || titleFromFile(normalized);
    const content = `# ${finalTitle}\n\n## Notes\n- \n`;
    writeText(path, content);
  }

  if (!silent) console.log(path);
  return { stdout: `${path}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node topic-create.js --type semantic|procedural|episodic --file <name> [--title "Human Title"] [--cwd /path]');
    process.exit(0);
  }
  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
