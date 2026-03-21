#!/usr/bin/env node
import { mkdirSync, existsSync, readFileSync, writeFileSync, readdirSync, cpSync } from 'fs';
import { join, dirname, resolve, basename } from 'path';
import { fileURLToPath } from 'url';
import { Command } from 'commander';
import { checkbox, input } from '@inquirer/prompts';

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

// ── helpers ──

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

function projectName(target) {
  return target.split('/').filter(Boolean).pop() || 'project';
}

function injectMarkerBlock(filePath, createTitle, injection) {
  const dir = dirname(filePath);
  if (dir !== '.') ensureDir(dir);

  if (!existsSync(filePath)) {
    writeFileSync(filePath, `# ${createTitle}\n${injection}`, 'utf8');
    return 'created';
  }
  const content = readFileSync(filePath, 'utf8');
  if (content.includes(WORKMEM_MARKER)) return 'exists';
  // Detect existing workmem content (e.g. from a previous init without marker)
  if (content.includes('.agent/memory/') && content.includes('workmem')) {
    console.log(`  ⚠ ${filePath} already has workmem references but no marker.`);
    console.log(`    Skipping to avoid duplicates. Add "${WORKMEM_MARKER}" manually if you want to re-inject.`);
    return 'exists';
  }
  writeFileSync(filePath, content.trimEnd() + '\n' + injection, 'utf8');
  return 'updated';
}

// ── agent selection ──

async function selectAgents() {
  const choices = [
    ...Object.entries(KNOWN_AGENTS).map(([key, info]) => ({
      name: `${info.label} (${info.entryFile})`,
      value: key,
    })),
    { name: 'Custom (specify your own entry file)', value: '__custom__' },
  ];

  const selected = await checkbox({
    message: 'Select agents to set up:',
    choices,
    required: true,
  });

  const agents = [];
  let customEntries = [];

  for (const item of selected) {
    if (item === '__custom__') {
      const raw = await input({
        message: 'Enter custom entry file path (e.g. .trae/memory.md):',
        validate: (v) => v.trim() ? true : 'File path is required',
      });
      customEntries.push(raw.trim());
    } else {
      agents.push(item);
    }
  }

  return { agents, customEntries };
}

function parseAgentFlag(raw) {
  if (!raw) return null;
  return String(raw).split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);
}

// ── scaffold ──

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

  const gitignorePath = join(base, '.gitignore');
  if (!existsSync(gitignorePath)) {
    writeFileSync(gitignorePath, `# Personal working state — do not commit\ncurrent/\narchive/\n`, 'utf8');
  }
}

function ensureAgentsEntry(target, allLabels, vars) {
  const agentsFile = join(target, 'AGENTS.md');
  const tpl = join(TEMPLATES, 'shared', 'AGENTS.md.tpl');
  const tplContent = render(readFileSync(tpl, 'utf8'), vars);
  const injection = `\n${WORKMEM_MARKER}\n${tplContent.trim()}\n`;

  const result = injectMarkerBlock(agentsFile, 'AGENTS', injection);
  if (result === 'created') {
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
  if (result === 'created') console.log(`  created ${info.entryFile}`);
  else if (result === 'updated') console.log(`  updated ${info.entryFile}`);
  else console.log(`  ${info.entryFile} already has workmem reference`);
}

function injectCustomEntry(target, entryFile) {
  const entryPath = join(target, entryFile);
  const label = basename(entryFile, '.md');
  const injection = `\n${WORKMEM_MARKER}\n## Project Memory (workmem)\n\nThis project uses a shared working memory layer. Read \`AGENTS.md\` before starting work.\n`;

  const result = injectMarkerBlock(entryPath, label, injection);
  if (result === 'created') console.log(`  created ${entryFile}`);
  else if (result === 'updated') console.log(`  updated ${entryFile}`);
  else console.log(`  ${entryFile} already has workmem reference`);
}

function printSummary(target) {
  console.log(`\nShared files (commit to git):`);
  console.log(`  .agent/memory/START.md`);
  console.log(`  .agent/memory/learnings/`);
  console.log(`  .agent/memory/procedures/`);
  console.log(`  AGENTS.md`);
  console.log(`\nPersonal files (gitignored):`);
  console.log(`  .agent/memory/current/`);
  console.log(`  .agent/memory/archive/`);
}

// ── commands ──

const program = new Command();

program
  .name('workmem')
  .description('Shared project memory scaffolding for coding agents.')
  .version('1.0.0');

program
  .command('init')
  .description('Initialize workmem scaffold in a project')
  .argument('[target-dir]', 'target directory', '.')
  .option('--agents <list>', 'comma-separated agent names')
  .option('--custom <path>', 'custom entry file path (e.g. .trae/memory.md)')
  .action(async (targetDir, opts) => {
    const target = resolve(targetDir);
    let agents = [], customEntries = [];

    if (opts.custom) {
      customEntries.push(opts.custom.trim());
    }

    if (opts.agents) {
      agents = parseAgentFlag(opts.agents);
    } else if (!opts.custom) {
      const result = await selectAgents();
      agents = result.agents;
      customEntries.push(...result.customEntries);
    }

    const allLabels = [
      ...agents.map((a) => KNOWN_AGENTS[a]?.label || a),
      ...customEntries.map((e) => basename(e, '.md')),
    ];
    const vars = { PROJECT_NAME: projectName(target), AGENT_LIST: allLabels.join(', ') };

    ensureMemoryScaffold(target, vars);
    ensureAgentsEntry(target, allLabels, vars);
    for (const agent of agents) injectAgentEntry(target, agent);
    for (const entry of customEntries) injectCustomEntry(target, entry);

    console.log(`\nInitialized workmem in ${join(target, '.agent', 'memory')}`);
    console.log(`Agents: ${allLabels.join(', ')}`);
    printSummary(target);
  });

program
  .command('add-agent')
  .description('Add agent entry files to an existing scaffold')
  .argument('[target-dir]', 'target directory', '.')
  .option('--agents <list>', 'comma-separated agent names')
  .option('--custom <path>', 'custom entry file path (e.g. .trae/memory.md)')
  .action(async (targetDir, opts) => {
    const target = resolve(targetDir);
    let agents = [], customEntries = [];

    if (opts.custom) {
      customEntries.push(opts.custom.trim());
    }

    if (opts.agents) {
      agents = parseAgentFlag(opts.agents);
    } else if (!opts.custom) {
      const result = await selectAgents();
      agents = result.agents;
      customEntries.push(...result.customEntries);
    }

    for (const agent of agents) injectAgentEntry(target, agent);
    for (const entry of customEntries) injectCustomEntry(target, entry);

    const labels = [
      ...agents.map((a) => KNOWN_AGENTS[a]?.label || a),
      ...customEntries.map((e) => basename(e, '.md')),
    ];
    console.log(`Added agents: ${labels.join(', ')}`);
  });

program
  .command('snapshot')
  .description('Archive current memory state')
  .argument('[target-dir]', 'target directory', '.')
  .option('--name <label>', 'snapshot label')
  .action((targetDir, opts) => {
    const target = resolve(targetDir);
    const base = join(target, '.agent', 'memory');
    const archive = join(base, 'archive');
    ensureDir(archive);
    const name = opts.name || new Date().toISOString().replace(/[:.]/g, '-');
    const snapDir = join(archive, name);
    ensureDir(snapDir);
    for (const rel of ['START.md', 'current', 'learnings', 'procedures']) {
      const src = join(base, rel);
      if (existsSync(src)) cpSync(src, join(snapDir, rel), { recursive: true });
    }
    console.log(`Snapshot saved: ${snapDir}`);
  });

program
  .command('doctor')
  .description('Check scaffold health')
  .argument('[target-dir]', 'target directory', '.')
  .action((targetDir) => {
    const target = resolve(targetDir);
    const base = join(target, '.agent', 'memory');
    const required = [
      'START.md',
      'current/CURRENT.md',
      'current/TODOS.md',
      'learnings/LEARNINGS.md',
      'procedures/PROCEDURES.md',
    ];
    let ok = true;
    for (const rel of required) {
      const full = join(base, rel);
      if (!existsSync(full)) {
        ok = false;
        console.log(`  missing: .agent/memory/${rel}`);
      }
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
    console.log(ok ? 'doctor: OK' : 'doctor: issues found');
    process.exitCode = ok ? 0 : 1;
  });

program.parse();
