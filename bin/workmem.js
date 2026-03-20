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

All commands default to the current directory if target-dir is omitted.

Examples:
  workmem init
  workmem init --agents claude,codex
  workmem add-agent --agents opencode
  workmem snapshot --name pre-release
  workmem doctor`);
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

  // gitignore for personal-layer files
  const gitignorePath = join(base, '.gitignore');
  if (!existsSync(gitignorePath)) {
    writeFileSync(gitignorePath, `# Personal working state — do not commit\ncurrent/\narchive/\n`, 'utf8');
  }
}

function injectMarkerBlock(filePath, createTitle, injection) {
  if (!existsSync(filePath)) {
    writeFileSync(filePath, `# ${createTitle}\n${injection}`, 'utf8');
    return 'created';
  }
  const content = readFileSync(filePath, 'utf8');
  if (content.includes(WORKMEM_MARKER)) {
    return 'exists';
  }
  writeFileSync(filePath, content.trimEnd() + '\n' + injection, 'utf8');
  return 'updated';
}

function ensureAgentsEntry(target, agents, vars) {
  const agentsFile = join(target, 'AGENTS.md');
  const tpl = join(TEMPLATES, 'shared', 'AGENTS.md.tpl');
  const tplContent = render(readFileSync(tpl, 'utf8'), vars);

  // Extract the workmem-specific block from the template
  const injection = `\n${WORKMEM_MARKER}\n${tplContent.trim()}\n`;

  const result = injectMarkerBlock(agentsFile, 'AGENTS', injection);
  if (result === 'created') {
    // For new files, write the template directly (cleaner than title + injection)
    writeFileSync(agentsFile, tplContent, 'utf8');
    console.log(`  created AGENTS.md`);
  } else if (result === 'updated') {
    console.log(`  updated AGENTS.md`);
  } else {
    console.log(`  AGENTS.md already has workmem reference`);
  }
}

function injectAgentEntry(target, agentName) {
  const info = KNOWN_AGENTS[agentName];
  if (!info) { console.log(`  skip unknown agent: ${agentName}`); return; }

  const entryPath = join(target, info.entryFile);
  const injection = `\n${WORKMEM_MARKER}\n## Project Memory (workmem)\n\nThis project uses a shared working memory layer. Read \`AGENTS.md\` before starting work.\n`;

  const result = injectMarkerBlock(entryPath, info.label, injection);
  if (result === 'created') {
    console.log(`  created ${info.entryFile}`);
  } else if (result === 'updated') {
    console.log(`  updated ${info.entryFile}`);
  } else {
    console.log(`  ${info.entryFile} already has workmem reference`);
  }
}

async function init(targetDir, agentsList) {
  const target = resolve(targetDir);
  const agents = agentsList || await promptAgents();
  const vars = { PROJECT_NAME: projectName(target), AGENT_LIST: agents.join(', ') };

  ensureMemoryScaffold(target, vars);
  ensureAgentsEntry(target, agents, vars);
  for (const agent of agents) {
    injectAgentEntry(target, agent);
  }

  console.log(`\nInitialized workmem in ${join(target, '.agent', 'memory')}`);
  console.log(`Agents: ${agents.join(', ')}`);
  console.log(`\nShared files (commit to git):`);
  console.log(`  .agent/memory/START.md`);
  console.log(`  .agent/memory/learnings/`);
  console.log(`  .agent/memory/procedures/`);
  console.log(`  AGENTS.md`);
  console.log(`\nPersonal files (gitignored):`);
  console.log(`  .agent/memory/current/`);
  console.log(`  .agent/memory/archive/`);
}

function addAgent(targetDir, agents) {
  const target = resolve(targetDir);
  for (const agent of agents) {
    injectAgentEntry(target, agent);
  }
  console.log(`Added agents: ${agents.join(', ')}`);
}

function snapshot(targetDir, label) {
  const target = resolve(targetDir);
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
  const target = resolve(targetDir);
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
    if (!existsSync(full)) {
      ok = false;
      console.log(`  missing: .agent/memory/${rel}`);
    }
  }
  // Check AGENTS.md
  const agentsFile = join(target, 'AGENTS.md');
  if (!existsSync(agentsFile)) {
    ok = false;
    console.log(`  missing: AGENTS.md`);
  } else if (!readFileSync(agentsFile, 'utf8').includes(WORKMEM_MARKER)) {
    console.log(`  AGENTS.md exists but has no workmem reference`);
  }
  // Check agent entry files
  for (const [name, info] of Object.entries(KNOWN_AGENTS)) {
    const entryPath = join(target, info.entryFile);
    if (existsSync(entryPath)) {
      const content = readFileSync(entryPath, 'utf8');
      if (content.includes(WORKMEM_MARKER)) {
        console.log(`  ${info.entryFile}: workmem linked`);
      } else {
        console.log(`  ${info.entryFile}: exists but no workmem reference`);
      }
    }
  }
  // Check gitignore
  const gi = join(base, '.gitignore');
  if (!existsSync(gi)) {
    console.log(`  warning: .agent/memory/.gitignore missing`);
  }
  console.log(ok ? 'doctor: OK' : 'doctor: issues found');
  process.exitCode = ok ? 0 : 1;
}

const args = parseArgs(process.argv.slice(2));
const command = args._[0];
const targetDir = args._[1] || '.';

if (!command || command === 'help' || command === '--help' || command === '-h') {
  help();
} else if (command === 'init') {
  init(targetDir, parseAgents(args.agents));
} else if (command === 'add-agent') {
  const agents = parseAgents(args.agents);
  if (!agents || !agents.length) {
    console.error('Usage: workmem add-agent [target-dir] --agents <list>');
    process.exit(1);
  }
  addAgent(targetDir, agents);
} else if (command === 'snapshot') {
  snapshot(targetDir, args.name);
} else if (command === 'doctor') {
  doctor(targetDir);
} else {
  help();
  process.exit(1);
}
