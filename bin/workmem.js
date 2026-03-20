#!/usr/bin/env node
import { mkdirSync, existsSync, readFileSync, writeFileSync, readdirSync, cpSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { createInterface } from 'readline';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');
const TEMPLATES = join(ROOT, 'templates');

const KNOWN_AGENTS = {
  claude:   { entryFile: 'CLAUDE.md',   label: 'Claude Code' },
  codex:    { entryFile: 'CODEX.md',    label: 'Codex' },
  gemini:   { entryFile: 'GEMINI.md',   label: 'Gemini' },
  opencode: { entryFile: 'OPENCODE.md', label: 'OpenCode' },
};

const WORKMEM_MARKER = '<!-- workmem -->';

function help() {
  console.log(`workmem

Shared project memory scaffolding for coding agents.

Usage:
  workmem init [target-dir] [--agents claude,codex,gemini,opencode]
  workmem add-agent [target-dir] --agents <list>
  workmem snapshot [target-dir] [--name label]
  workmem doctor [target-dir]

Examples:
  workmem init .
  workmem init . --agents claude,codex
  workmem add-agent . --agents opencode
  workmem snapshot . --name pre-release
  npx workmem init .`);
}

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      const next = argv[i + 1];
      if (!next || next.startsWith('-')) out[key] = true;
      else { out[key] = next; i++; }
    } else {
      out._.push(arg);
    }
  }
  return out;
}

function ensureDir(path) {
  mkdirSync(path, { recursive: true });
}

function render(text, vars) {
  return text.replace(/\{\{\s*([A-Z_]+)\s*\}\}/g, (_, key) => vars[key] || '');
}

function writeTemplate(src, dest, vars) {
  if (existsSync(dest)) return;
  const content = readFileSync(src, 'utf8');
  writeFileSync(dest, render(content, vars), 'utf8');
}

function parseAgents(raw) {
  if (!raw) return null;
  return String(raw).split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
}

function projectName(target) {
  return target.split('/').filter(Boolean).pop() || 'project';
}

function ask(question) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => { rl.close(); resolve(answer.trim()); });
  });
}

async function promptAgents() {
  const names = Object.keys(KNOWN_AGENTS);
  console.log('Available agents:');
  names.forEach((name, i) => {
    console.log(`  ${i + 1}. ${KNOWN_AGENTS[name].label} (${name})`);
  });
  const answer = await ask(`Select agents (comma-separated numbers or names, default: all): `);
  if (!answer) return names;
  const selected = [];
  for (const part of answer.split(',').map((s) => s.trim())) {
    const num = parseInt(part, 10);
    if (!isNaN(num) && num >= 1 && num <= names.length) {
      selected.push(names[num - 1]);
    } else if (names.includes(part.toLowerCase())) {
      selected.push(part.toLowerCase());
    }
  }
  return selected.length ? [...new Set(selected)] : names;
}

function ensureMemoryScaffold(target, vars) {
  const base = join(target, '.agent', 'memory');
  for (const dir of ['current', 'learnings', 'procedures', 'archive']) {
    ensureDir(join(base, dir));
  }
  writeTemplate(join(TEMPLATES, 'shared', 'START.md.tpl'), join(base, 'START.md'), vars);
  writeTemplate(join(TEMPLATES, 'shared', 'CURRENT.md.tpl'), join(base, 'current', 'CURRENT.md'), vars);
  writeTemplate(join(TEMPLATES, 'shared', 'TODOS.md.tpl'), join(base, 'current', 'TODOS.md'), vars);
  writeTemplate(join(TEMPLATES, 'shared', 'LEARNINGS.md.tpl'), join(base, 'learnings', 'LEARNINGS.md'), vars);
  writeTemplate(join(TEMPLATES, 'shared', 'PROCEDURES.md.tpl'), join(base, 'procedures', 'PROCEDURES.md'), vars);
}

function ensureAgentsEntry(target, agents, vars) {
  const agentsFile = join(target, 'AGENTS.md');
  if (!existsSync(agentsFile)) {
    const tpl = join(TEMPLATES, 'shared', 'AGENTS.md.tpl');
    if (existsSync(tpl)) {
      writeTemplate(tpl, agentsFile, vars);
    } else {
      writeFileSync(agentsFile, render(readFileSync(join(TEMPLATES, 'shared', 'AGENTS.md.tpl.fallback'), 'utf8'), vars), 'utf8');
    }
  }
}

function injectAgentEntry(target, agentName) {
  const info = KNOWN_AGENTS[agentName];
  if (!info) { console.log(`skip unknown agent: ${agentName}`); return; }

  const entryPath = join(target, info.entryFile);
  const injection = `\n${WORKMEM_MARKER}\n## Project Memory (workmem)\n\nThis project uses a shared working memory layer. Read \`AGENTS.md\` before starting work.\n`;

  if (!existsSync(entryPath)) {
    writeFileSync(entryPath, `# ${info.label}\n${injection}`, 'utf8');
    console.log(`  created ${info.entryFile}`);
  } else {
    const content = readFileSync(entryPath, 'utf8');
    if (content.includes(WORKMEM_MARKER)) {
      console.log(`  ${info.entryFile} already has workmem reference`);
      return;
    }
    writeFileSync(entryPath, content.trimEnd() + '\n' + injection, 'utf8');
    console.log(`  updated ${info.entryFile}`);
  }
}

async function init(targetDir, agentsList) {
  const target = resolve(targetDir || '.');
  const agents = agentsList || await promptAgents();
  const vars = { PROJECT_NAME: projectName(target), AGENT_LIST: agents.join(', ') };

  ensureMemoryScaffold(target, vars);
  ensureAgentsEntry(target, agents, vars);
  for (const agent of agents) {
    injectAgentEntry(target, agent);
  }

  console.log(`\nInitialized workmem in ${join(target, '.agent', 'memory')}`);
  console.log(`Agents: ${agents.join(', ')}`);
}

function addAgent(targetDir, agents) {
  const target = resolve(targetDir || '.');
  const vars = { PROJECT_NAME: projectName(target), AGENT_LIST: agents.join(', ') };
  for (const agent of agents) {
    injectAgentEntry(target, agent);
  }
  console.log(`Added agents: ${agents.join(', ')}`);
}

function snapshot(targetDir, label) {
  const target = resolve(targetDir || '.');
  const base = join(target, '.agent', 'memory');
  const archive = join(base, 'archive');
  ensureDir(archive);
  const name = label || new Date().toISOString().replace(/[:.]/g, '-');
  const snapDir = join(archive, name);
  ensureDir(snapDir);
  for (const rel of ['START.md', 'current', 'learnings', 'procedures']) {
    const src = join(base, rel);
    if (existsSync(src)) cpSync(src, join(snapDir, rel), { recursive: true });
  }
  console.log(`Snapshot saved: ${snapDir}`);
}

function doctor(targetDir) {
  const target = resolve(targetDir || '.');
  const base = join(target, '.agent', 'memory');
  const required = [
    'START.md',
    'current/CURRENT.md',
    'current/TODOS.md',
    'learnings/LEARNINGS.md',
    'procedures/PROCEDURES.md'
  ];
  let ok = true;
  for (const rel of required) {
    const full = join(base, rel);
    if (!existsSync(full)) { ok = false; console.log(`missing: .agent/memory/${rel}`); }
  }
  const agentsFile = join(target, 'AGENTS.md');
  if (!existsSync(agentsFile)) { ok = false; console.log('missing: AGENTS.md'); }
  for (const [name, info] of Object.entries(KNOWN_AGENTS)) {
    const entry = join(target, info.entryFile);
    if (existsSync(entry)) {
      const content = readFileSync(entry, 'utf8');
      if (content.includes(WORKMEM_MARKER)) {
        console.log(`${info.entryFile}: workmem linked`);
      } else {
        console.log(`${info.entryFile}: exists but workmem NOT linked`);
      }
    }
  }
  console.log(ok ? 'doctor: OK' : 'doctor: issues found');
  process.exitCode = ok ? 0 : 1;
}

const args = parseArgs(process.argv.slice(2));
const command = args._[0];

if (!command || command === 'help' || command === '--help' || command === '-h') {
  help();
} else if (command === 'init') {
  await init(args._[1] || '.', parseAgents(args.agents));
} else if (command === 'add-agent') {
  if (!args.agents) { console.error('--agents required'); process.exit(1); }
  addAgent(args._[1] || '.', parseAgents(args.agents));
} else if (command === 'snapshot') {
  snapshot(args._[1] || '.', args.name);
} else if (command === 'doctor') {
  doctor(args._[1] || '.');
} else {
  help();
  process.exit(1);
}
