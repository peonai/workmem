#!/usr/bin/env node
import { join } from 'path';
import { listMarkdown, memoryRoot, parseArgs, readText, writeText } from './common.js';

function trimBullets(text, keep = 12) {
  const lines = text.split(/\r?\n/);
  const bullets = lines.filter((line) => line.trim().startsWith('- '));
  if (bullets.length <= keep) return { changed: false, text };

  const kept = bullets.slice(-keep);
  const heading = lines.filter((line) => !line.trim().startsWith('- '));
  return {
    changed: true,
    text: `${heading.join('\n').trimEnd()}\n${kept.join('\n')}\n`,
  };
}

export async function runCli({ cwd = process.cwd(), args = {}, silent = false } = {}) {
  const base = memoryRoot(cwd);
  const keep = Number(args.keep || 12);
  const latestEpisodic = listMarkdown(join(base, 'episodic')).map((f) => f.name).sort().slice(-1)[0];
  const touched = [];

  for (const rel of [
    join('semantic', 'active-context.md'),
    join('semantic', 'decisions.md'),
    join('procedural', 'common-workflows.md'),
  ]) {
    const path = join(base, rel);
    const text = readText(path);
    if (!text) continue;
    const result = trimBullets(text, keep);
    if (result.changed) {
      writeText(path, result.text);
      touched.push(rel);
    }
  }

  const stdout = JSON.stringify({ keep, latestEpisodic, touched }, null, 2);
  if (!silent) console.log(stdout);
  return { stdout: `${stdout}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node compact.js [--keep 12] [--cwd /path]');
    process.exit(0);
  }
  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
