#!/usr/bin/env node
import { latestEpisodicPath, memoryRoot, parseArgs, readText } from './common.js';

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

export async function runCli({ cwd = process.cwd(), args = {}, silent = false } = {}) {
  const base = memoryRoot(cwd);
  const episodicPath = latestEpisodicPath(base);
  const episodic = readText(episodicPath) || '';
  const workLog = collectBullets(getSection(episodic, 'Work Log'));
  const findings = collectBullets(getSection(episodic, 'Findings'));
  const followUps = collectBullets(getSection(episodic, 'Follow-ups'));

  const semanticCandidates = findings.filter((item) => /(constraint|decision|fact|architecture|ready|exists|uses|depends|requires|risk|约定|限制|决策|架构|事实|依赖|需要)/i.test(item));
  const proceduralCandidates = [...workLog, ...findings].filter((item) => /(workflow|steps|command|build|release|test|deploy|setup|debug|script|流程|命令|构建|发布|测试|部署|调试)/i.test(item));
  const activeContextCandidates = [...followUps, ...workLog].filter((item) => /(next|follow-up|todo|later|need|add|continue|下一步|后续|待办|继续|补)/i.test(item));

  const payload = { episodic: episodicPath, semanticCandidates, proceduralCandidates, activeContextCandidates };
  let stdout = '';

  if (args.format === 'json') {
    stdout = JSON.stringify(payload, null, 2);
  } else {
    const lines = [
      '# Memory Review Plan',
      '',
      `Source episodic note: \`${episodicPath.replace(base + '/', '')}\``,
      '',
      '## Candidate promotions',
      '',
      '### semantic',
      ...(semanticCandidates.length ? semanticCandidates.map((item) => `- ${item}`) : ['- none detected']),
      '',
      '### procedural',
      ...(proceduralCandidates.length ? proceduralCandidates.map((item) => `- ${item}`) : ['- none detected']),
      '',
      '### active context / follow-up',
      ...(activeContextCandidates.length ? activeContextCandidates.map((item) => `- ${item}`) : ['- none detected']),
      ''
    ];
    stdout = lines.join('\n');
  }

  if (!silent) process.stdout.write(stdout);
  return { stdout };
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;

if (isMain) {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log('Usage: node review.js [--cwd /path] [--format markdown|json]');
    process.exit(0);
  }

  runCli({ cwd: args.cwd || process.cwd(), args }).catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  });
}
