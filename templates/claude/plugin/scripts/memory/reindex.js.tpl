#!/usr/bin/env node
import { join } from 'path';
import { listMarkdown, memoryRoot, parseArgs, writeText } from './common.js';

export async function runCli({ cwd = process.cwd(), silent = false } = {}) {
  const base = memoryRoot(cwd);
  const latestEpisodic = listMarkdown(join(base, 'episodic')).map((f) => f.name).sort().slice(-1)[0] || 'YYYY-MM-DD.md';
  const semantic = listMarkdown(join(base, 'semantic')).map((f) => `- \`semantic/${f.name}\``).join('\n') || '- `semantic/`';
  const procedural = listMarkdown(join(base, 'procedural')).map((f) => `- \`procedural/${f.name}\``).join('\n') || '- `procedural/`';

  const content = `# MEMORY\n\nThis file is the index for .agent/memory/.\nKeep it concise. It should help Claude decide what to read next, not try to contain everything.\n\n## Read This First\n- \`semantic/active-context.md\` for current direction\n- \`semantic/project.md\` for durable project facts\n- \`semantic/decisions.md\` for important decisions and constraints\n- \`procedural/common-workflows.md\` for repeatable commands and flows\n- \`episodic/${latestEpisodic}\` for today's running notes\n\n## Routing Rules\n- Durable facts, architecture, constraints, preferences -> \`semantic/*.md\`\n- Repeatable workflows, build/test/release recipes -> \`procedural/*.md\`\n- Session progress, debugging trails, temporary observations -> \`episodic/YYYY-MM-DD.md\`\n- Old or replaced material -> \`legacy/\`\n- Backups before cleanup or compaction -> \`snapshots/\`\n\n## Active Topics\n${semantic}\n${procedural}\n`;

  const outPath = join(base, 'MEMORY.md');
  writeText(outPath, content);
  if (!silent) console.log(outPath);
  return { stdout: `${outPath}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node reindex.js [--cwd /path]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd() }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
