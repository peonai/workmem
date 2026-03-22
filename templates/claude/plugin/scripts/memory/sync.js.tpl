#!/usr/bin/env node
import { join } from 'path';
import { appendText, latestEpisodicPath, memoryRoot, parseArgs, readText, writeText } from './common.js';

function collectBullets(sectionText) {
  return sectionText
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.startsWith('- '))
    .map((line) => line.slice(2).trim())
    .filter(Boolean);
}

function getSection(text, heading) {
  const pattern = new RegExp(`## ${heading}\\n([\\s\\S]*?)(?=\\n## |$)`);
  const match = text.match(pattern);
  return match ? match[1].trim() : '';
}

function ensureLine(text, line) {
  const bullet = `- ${line}`;
  if (text.includes(bullet)) return text;
  return `${text.trimEnd()}\n${bullet}\n`;
}

export async function runCli({ cwd = process.cwd(), silent = false } = {}) {
  const base = memoryRoot(cwd);
  const episodicPath = latestEpisodicPath(base);
  const episodic = readText(episodicPath) || '';
  const workLog = collectBullets(getSection(episodic, 'Work Log'));
  const findings = collectBullets(getSection(episodic, 'Findings'));
  const followUps = collectBullets(getSection(episodic, 'Follow-ups'));

  const activePath = join(base, 'semantic', 'active-context.md');
  const decisionsPath = join(base, 'semantic', 'decisions.md');
  const proceduralPath = join(base, 'procedural', 'common-workflows.md');

  let active = readText(activePath) || '# Active Context\n';
  let decisions = readText(decisionsPath) || '# Decisions\n\n## Entries\n';
  let procedural = readText(proceduralPath) || '# Common Workflows\n';

  for (const item of followUps) {
    if (/(next|follow-up|todo|later|need|add|continue|下一步|后续|待办|继续|补)/i.test(item)) active = ensureLine(active, item);
  }
  for (const item of findings) {
    if (/(constraint|decision|fact|architecture|ready|exists|uses|depends|requires|risk|约定|限制|决策|架构|事实|依赖|需要)/i.test(item)) decisions = ensureLine(decisions, item);
  }
  for (const item of [...workLog, ...findings]) {
    if (/(workflow|steps|command|build|release|test|deploy|setup|debug|script|流程|命令|构建|发布|测试|部署|调试)/i.test(item)) procedural = ensureLine(procedural, item);
  }

  writeText(activePath, active);
  writeText(decisionsPath, decisions);
  writeText(proceduralPath, procedural);
  appendText(episodicPath, '\n- synced promotion candidates into semantic/procedural memory\n');

  const stdout = JSON.stringify({ activePath, decisionsPath, proceduralPath, episodicPath }, null, 2);
  if (!silent) console.log(stdout);
  return { stdout: `${stdout}\n` };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node sync.js [--cwd /path]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd() }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
