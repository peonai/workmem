#!/usr/bin/env node
import { existsSync } from 'fs';
import { join } from 'path';
import { latestEpisodicPath, memoryRoot, parseArgs, readText, writeText } from './common.js';

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

function replaceSection(text, heading, bodyLines) {
  const body = bodyLines.join('\n');
  const block = `## ${heading}\n${body}`;
  const pattern = new RegExp(`## ${heading}\\n[\\s\\S]*?(?=\\n## |$)`);
  if (pattern.test(text)) {
    return text.replace(pattern, `${block}\n`);
  }
  return `${text.trimEnd()}\n\n${block}\n`;
}

function parsePackageJson(cwd) {
  try {
    return JSON.parse(readText(join(cwd, 'package.json')) || '{}');
  } catch {
    return {};
  }
}

function parseReadme(cwd) {
  const readme = readText(join(cwd, 'README.md')) || '';
  const lines = readme.split(/\r?\n/).map((line) => line.trim());
  const title = (lines.find((line) => line.startsWith('# ')) || '').replace(/^#\s+/, '');
  const description = lines.find((line) => line && !line.startsWith('#') && !line.startsWith('```')) || '';
  return { title, description };
}

function detectEntryPoint(cwd, pkg) {
  if (pkg.main) return pkg.main;
  const candidates = ['src/index.js', 'index.js', 'src/main.js'];
  return candidates.find((rel) => existsSync(join(cwd, rel))) || '';
}

function detectAppKind(cwd, entryPoint) {
  if (!entryPoint) return 'CLI app';
  const source = readText(join(cwd, entryPoint)) || '';
  if (/createServer|express\(|fastify\(|koa\(/.test(source)) return 'HTTP server';
  if (/React|react-dom|jsx|tsx/.test(source)) return 'frontend app';
  return 'CLI app';
}

function repoFacts(cwd) {
  const pkg = parsePackageJson(cwd);
  const readme = parseReadme(cwd);
  const entryPoint = detectEntryPoint(cwd, pkg);
  const deps = [
    ...Object.keys(pkg.dependencies || {}),
    ...Object.keys(pkg.devDependencies || {}),
  ];
  const appKind = detectAppKind(cwd, entryPoint);

  const stackParts = [];
  stackParts.push(pkg.type === 'module' ? 'Node.js (ESM)' : 'Node.js');
  stackParts.push(appKind);
  if (deps.length === 0) stackParts.push('no external dependencies');

  return {
    name: pkg.name || '',
    purpose: readme.description || (readme.title ? `${readme.title} application` : ''),
    users: 'Developers working in this repo',
    stack: stackParts.join(', '),
    runtime: entryPoint ? `${appKind} (${entryPoint})` : appKind,
    deps: deps.length ? deps.join(', ') : 'none',
    constraints: pkg.private === true ? ['Private package (not published to npm)'] : [],
    references: ['README.md', 'package.json', entryPoint].filter(Boolean),
    entryPoint,
  };
}

function deriveActiveContext(workLog, followUps, facts) {
  const latestWork = workLog[workLog.length - 1] || '';
  const nextStep = followUps[0] || (facts.entryPoint ? `Expand functionality in ${facts.entryPoint}` : 'Define the next meaningful feature');
  const risks = facts.deps === 'none' ? 'None currently' : 'Keep dependency sprawl under control';
  const openThreads = [];
  if (facts.entryPoint) openThreads.push(`Main entry point is ${facts.entryPoint}`);
  if (followUps.length > 1) openThreads.push(...followUps.slice(1));

  return {
    now: latestWork || (facts.entryPoint ? `Initial scaffolding is in place (${facts.entryPoint})` : 'Initial scaffolding is in place'),
    next: nextStep,
    risks,
    openThreads,
    shortReminders: [],
  };
}

function mergeDecisionEntries(existingText, newItems) {
  const existingEntries = collectBullets(getSection(existingText, 'Entries'));
  const merged = [...existingEntries];
  for (const item of newItems) {
    if (!merged.includes(item)) merged.push(item);
  }
  return replaceSection(existingText, 'Entries', merged.length ? merged.map((item) => `- ${item}`) : ['-']);
}

function mergeProcedureSections(existingText, newItems) {
  const sections = ['Development', 'Testing', 'Build', 'Release', 'Maintenance'];
  let nextText = existingText;
  for (const section of sections) {
    const current = collectBullets(getSection(nextText, section));
    const merged = [...current];
    for (const item of newItems) {
      if (!merged.includes(item)) merged.push(item);
    }
    nextText = replaceSection(nextText, section, merged.length ? merged.map((item) => `- ${item}`) : ['-']);
  }
  return nextText;
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
  const projectPath = join(base, 'semantic', 'project.md');

  const facts = repoFacts(cwd);
  const activeContext = deriveActiveContext(workLog, followUps, facts);

  let project = readText(projectPath) || '# Project\n';
  project = replaceSection(project, 'What this project is', [
    `- Name: ${facts.name}`,
    `- Purpose: ${facts.purpose}`,
    `- Primary users: ${facts.users}`,
  ]);
  project = replaceSection(project, 'Durable facts', [
    `- Main stack: ${facts.stack}`,
    `- Deployment/runtime: ${facts.runtime}`,
    `- Key external dependencies: ${facts.deps}`,
  ]);
  project = replaceSection(project, 'Important constraints', facts.constraints.length ? facts.constraints.map((item) => `- ${item}`) : ['-']);
  project = replaceSection(project, 'References', facts.references.length ? facts.references.map((item) => `- ${item}`) : ['-']);

  let active = readText(activePath) || '# Active Context\n';
  active = replaceSection(active, 'Current focus', [
    `- Now: ${activeContext.now}`,
    `- Next: ${activeContext.next}`,
    `- Risks: ${activeContext.risks}`,
  ]);
  active = replaceSection(active, 'Open threads', activeContext.openThreads.length ? activeContext.openThreads.map((item) => `- ${item}`) : ['-']);
  active = replaceSection(active, 'Short-term reminders', activeContext.shortReminders.length ? activeContext.shortReminders.map((item) => `- ${item}`) : ['-']);

  let decisions = readText(decisionsPath) || '# Decisions\n\n## Entries\n-\n';
  const decisionItems = findings.filter((item) => /(constraint|decision|fact|architecture|ready|exists|uses|depends|requires|risk|约定|限制|决策|架构|事实|依赖|需要)/i.test(item));
  decisions = mergeDecisionEntries(decisions, decisionItems);

  let procedural = readText(proceduralPath) || '# Common Workflows\n';
  const workflowItems = [...workLog, ...findings].filter((item) => /(workflow|steps|command|build|release|test|deploy|setup|debug|script|流程|命令|构建|发布|测试|部署|调试)/i.test(item));
  procedural = mergeProcedureSections(procedural, workflowItems);

  writeText(projectPath, project);
  writeText(activePath, active);
  writeText(decisionsPath, decisions);
  writeText(proceduralPath, procedural);

  const stdout = JSON.stringify({ activePath, decisionsPath, proceduralPath, projectPath, episodicPath }, null, 2);
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
