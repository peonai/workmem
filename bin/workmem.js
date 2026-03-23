#!/usr/bin/env node
import { mkdirSync, existsSync, readFileSync, writeFileSync, cpSync, readdirSync, statSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { Command } from 'commander';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');
const TEMPLATES = join(ROOT, 'templates');
const PKG = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));

const SUPPORTED_BACKENDS = {
  claude: {
    label: 'Claude Code',
    pluginDir: '.claude/plugins/workmem',
    claudeMd: 'CLAUDE.md',
  },
};

const WORKMEM_MARKER = '<!-- workmem-managed -->';

function ensureDir(path) {
  mkdirSync(path, { recursive: true });
}

function render(text, vars) {
  return text.replace(/\{\{\s*([A-Z_]+)\s*\}\}/g, (_, key) => vars[key] ?? '');
}

function readTemplate(relPath) {
  return readFileSync(join(TEMPLATES, relPath), 'utf8');
}

function writeTemplateIfMissing(srcRelPath, destPath, vars) {
  if (existsSync(destPath)) return false;
  ensureDir(dirname(destPath));
  writeFileSync(destPath, render(readTemplate(srcRelPath), vars), 'utf8');
  return true;
}

function writeManagedFile(srcRelPath, destPath, vars) {
  ensureDir(dirname(destPath));
  writeFileSync(destPath, render(readTemplate(srcRelPath), vars), 'utf8');
}

function projectName(target) {
  return target.split('/').filter(Boolean).pop() || 'project';
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function injectManagedBlock(filePath, createTitle, body) {
  const block = `\n${WORKMEM_MARKER}\n${body.trim()}\n`;
  ensureDir(dirname(filePath));

  if (!existsSync(filePath)) {
    writeFileSync(filePath, `# ${createTitle}\n${block}`, 'utf8');
    return 'created';
  }

  const content = readFileSync(filePath, 'utf8');
  if (content.includes(WORKMEM_MARKER)) {
    const updated = content.replace(
      new RegExp(`${WORKMEM_MARKER}[\\s\\S]*$`),
      `${WORKMEM_MARKER}\n${body.trim()}\n`
    );
    writeFileSync(filePath, updated, 'utf8');
    return 'updated';
  }

  writeFileSync(filePath, `${content.trimEnd()}\n${block}`, 'utf8');
  return 'updated';
}

function latestEpisodicFile(base) {
  const episodicDir = join(base, 'episodic');
  if (!existsSync(episodicDir)) return null;

  const files = readdirSync(episodicDir)
    .filter((name) => name.endsWith('.md'))
    .sort();

  return files.length ? join(episodicDir, files[files.length - 1]) : null;
}

function ensureCoreMemoryScaffold(target, vars) {
  const base = join(target, '.agent', 'memory');
  for (const dir of ['episodic', 'semantic', 'procedural', 'snapshots', 'legacy']) {
    ensureDir(join(base, dir));
  }

  writeTemplateIfMissing('core/MEMORY.md.tpl', join(base, 'MEMORY.md'), vars);
  writeTemplateIfMissing('core/semantic/project.md.tpl', join(base, 'semantic', 'project.md'), vars);
  writeTemplateIfMissing('core/semantic/active-context.md.tpl', join(base, 'semantic', 'active-context.md'), vars);
  writeTemplateIfMissing('core/semantic/decisions.md.tpl', join(base, 'semantic', 'decisions.md'), vars);
  writeTemplateIfMissing('core/procedural/common-workflows.md.tpl', join(base, 'procedural', 'common-workflows.md'), vars);
  writeTemplateIfMissing('core/episodic/daily.md.tpl', join(base, 'episodic', `${today()}.md`), vars);
  writeTemplateIfMissing('core/GITIGNORE.tpl', join(base, '.gitignore'), vars);
}

function ensureClaudeIntegration(target, vars, opts) {
  const pluginDir = join(target, opts.pluginDir);
  const claudeMdPath = join(target, opts.claudeMdPath);

  const claudeBody = render(readTemplate('claude/CLAUDE.md.tpl'), vars);
  injectManagedBlock(claudeMdPath, 'Claude Code project instructions', claudeBody);

  writeManagedFile('claude/plugin/.claude-plugin/plugin.json.tpl', join(pluginDir, '.claude-plugin', 'plugin.json'), vars);
  writeManagedFile('claude/plugin/hooks/hooks.json.tpl', join(pluginDir, 'hooks', 'hooks.json'), vars);
  writeManagedFile('claude/plugin/skills/maintain-workmem/SKILL.md.tpl', join(pluginDir, 'skills', 'maintain-workmem', 'SKILL.md'), vars);
  writeManagedFile('claude/plugin/mcp/server.js.tpl', join(pluginDir, 'mcp', 'server.js'), vars);
  writeManagedFile('claude/plugin/mcp/mcp.json.tpl', join(pluginDir, 'mcp', 'mcp.json'), vars);
  writeManagedFile('claude/plugin/scripts/session-start.js.tpl', join(pluginDir, 'scripts', 'session-start.js'), vars);
  writeManagedFile('claude/plugin/scripts/user-prompt-submit.js.tpl', join(pluginDir, 'scripts', 'user-prompt-submit.js'), vars);
  writeManagedFile('claude/plugin/scripts/lifecycle-memory-review.js.tpl', join(pluginDir, 'scripts', 'lifecycle-memory-review.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/common.js.tpl', join(pluginDir, 'scripts', 'memory', 'common.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/extractor.js.tpl', join(pluginDir, 'scripts', 'memory', 'extractor.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/schema.js.tpl', join(pluginDir, 'scripts', 'memory', 'schema.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/read.js.tpl', join(pluginDir, 'scripts', 'memory', 'read.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/write.js.tpl', join(pluginDir, 'scripts', 'memory', 'write.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/promote.js.tpl', join(pluginDir, 'scripts', 'memory', 'promote.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/reindex.js.tpl', join(pluginDir, 'scripts', 'memory', 'reindex.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/review.js.tpl', join(pluginDir, 'scripts', 'memory', 'review.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/sync.js.tpl', join(pluginDir, 'scripts', 'memory', 'sync.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/topic-create.js.tpl', join(pluginDir, 'scripts', 'memory', 'topic-create.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/archive.js.tpl', join(pluginDir, 'scripts', 'memory', 'archive.js'), vars);
  writeManagedFile('claude/plugin/scripts/memory/compact.js.tpl', join(pluginDir, 'scripts', 'memory', 'compact.js'), vars);
}

function printInitSummary(target, backend, opts) {
  const pluginDir = join(target, opts.pluginDir);
  console.log(`\nInitialized workmem for ${SUPPORTED_BACKENDS[backend].label}`);
  console.log(`Memory root: ${join(target, '.agent', 'memory')}`);
  console.log(`Claude plugin: ${pluginDir}`);
  console.log(`\nMemory model:`);
  console.log(`  - MEMORY.md = compact index and routing layer`);
  console.log(`  - semantic/*.md = durable knowledge and decisions`);
  console.log(`  - procedural/*.md = reusable workflows`);
  console.log(`  - episodic/YYYY-MM-DD.md = dated session notes`);
  console.log(`\nNext step:`);
  console.log(`  claude --plugin-dir ${pluginDir}`);
  console.log(`\nLocal memory scripts:`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'read.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'write.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'promote.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'reindex.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'review.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'sync.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'topic-create.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'archive.js')} --help`);
  console.log(`  - node ${join(pluginDir, 'scripts', 'memory', 'compact.js')} --help`);
  console.log(`\nMCP config:`);
  console.log(`  - claude --mcp-config ${join(pluginDir, 'mcp', 'mcp.json')}`);
}

function doctorCore(target) {
  const base = join(target, '.agent', 'memory');
  const requiredFiles = [
    'MEMORY.md',
    'semantic/project.md',
    'semantic/active-context.md',
    'semantic/decisions.md',
    'procedural/common-workflows.md',
    '.gitignore',
  ];
  const requiredDirs = ['episodic', 'semantic', 'procedural', 'snapshots', 'legacy'];

  let ok = true;

  for (const rel of requiredDirs) {
    const full = join(base, rel);
    if (!existsSync(full) || !statSync(full).isDirectory()) {
      ok = false;
      console.log(`  missing dir: .agent/memory/${rel}`);
    }
  }

  for (const rel of requiredFiles) {
    if (!existsSync(join(base, rel))) {
      ok = false;
      console.log(`  missing: .agent/memory/${rel}`);
    }
  }

  const latest = latestEpisodicFile(base);
  if (!latest) {
    ok = false;
    console.log('  missing: .agent/memory/episodic/*.md');
  }

  return ok;
}

function doctorClaude(target, opts) {
  const required = [
    join(opts.claudeMdPath),
    join(opts.pluginDir, '.claude-plugin', 'plugin.json'),
    join(opts.pluginDir, 'hooks', 'hooks.json'),
    join(opts.pluginDir, 'skills', 'maintain-workmem', 'SKILL.md'),
    join(opts.pluginDir, 'mcp', 'server.js'),
    join(opts.pluginDir, 'mcp', 'mcp.json'),
    join(opts.pluginDir, 'scripts', 'session-start.js'),
    join(opts.pluginDir, 'scripts', 'user-prompt-submit.js'),
    join(opts.pluginDir, 'scripts', 'lifecycle-memory-review.js'),
    join(opts.pluginDir, 'scripts', 'memory', 'common.js'),
    join(opts.pluginDir, 'scripts', 'memory', 'read.js'),
    join(opts.pluginDir, 'scripts', 'memory', 'write.js'),
    join(opts.pluginDir, 'scripts', 'memory', 'promote.js'),
    join(opts.pluginDir, 'scripts', 'memory', 'reindex.js'),
  ];

  let ok = true;
  for (const rel of required) {
    if (!existsSync(join(target, rel))) {
      ok = false;
      console.log(`  missing: ${rel}`);
    }
  }

  const claudeMdPath = join(target, opts.claudeMdPath);
  if (existsSync(claudeMdPath)) {
    const content = readFileSync(claudeMdPath, 'utf8');
    if (!content.includes(WORKMEM_MARKER)) {
      ok = false;
      console.log(`  ${opts.claudeMdPath}: exists but has no workmem-managed block`);
    }
  }

  return ok;
}

function parseBackend(raw) {
  const backend = String(raw || 'claude').trim().toLowerCase();
  if (!SUPPORTED_BACKENDS[backend]) {
    throw new Error(`Unsupported backend: ${backend}. Currently supported: ${Object.keys(SUPPORTED_BACKENDS).join(', ')}`);
  }
  return backend;
}

const program = new Command();
program
  .name('workmem')
  .description('Project memory scaffolding with a Claude Code plugin backend.')
  .version(PKG.version);

program
  .command('init')
  .description('Initialize the semantic/procedural/episodic memory scaffold plus Claude Code plugin integration')
  .argument('[target-dir]', 'target directory', '.')
  .option('--backend <name>', 'integration backend (currently only: claude)', 'claude')
  .option('--plugin-dir <path>', 'relative Claude plugin directory', SUPPORTED_BACKENDS.claude.pluginDir)
  .option('--claude-md <path>', 'relative Claude Code project instructions file', SUPPORTED_BACKENDS.claude.claudeMd)
  .action((targetDir, opts) => {
    const target = resolve(targetDir);
    const backend = parseBackend(opts.backend);
    const vars = {
      PROJECT_NAME: projectName(target),
      BACKEND_LABEL: SUPPORTED_BACKENDS[backend].label,
      PLUGIN_DIR: opts.pluginDir,
      CLAUDE_MD_PATH: opts.claudeMd,
      VERSION: PKG.version,
      TODAY: today(),
    };

    ensureCoreMemoryScaffold(target, vars);
    if (backend === 'claude') {
      ensureClaudeIntegration(target, vars, { pluginDir: opts.pluginDir, claudeMdPath: opts.claudeMd });
    }

    printInitSummary(target, backend, { pluginDir: opts.pluginDir });
  });

program
  .command('snapshot')
  .description('Archive the current workmem state into snapshots/')
  .argument('[target-dir]', 'target directory', '.')
  .option('--name <label>', 'snapshot label')
  .action((targetDir, opts) => {
    const target = resolve(targetDir);
    const base = join(target, '.agent', 'memory');
    const snapshots = join(base, 'snapshots');
    ensureDir(snapshots);
    const name = opts.name || new Date().toISOString().replace(/[:.]/g, '-');
    const snapDir = join(snapshots, name);
    ensureDir(snapDir);

    for (const rel of ['MEMORY.md', 'episodic', 'semantic', 'procedural']) {
      const src = join(base, rel);
      if (existsSync(src)) cpSync(src, join(snapDir, rel), { recursive: true });
    }

    console.log(`Snapshot saved: ${snapDir}`);
  });

program
  .command('doctor')
  .description('Check memory scaffold and Claude Code integration health')
  .argument('[target-dir]', 'target directory', '.')
  .option('--backend <name>', 'integration backend (currently only: claude)', 'claude')
  .option('--plugin-dir <path>', 'relative Claude plugin directory', SUPPORTED_BACKENDS.claude.pluginDir)
  .option('--claude-md <path>', 'relative Claude Code project instructions file', SUPPORTED_BACKENDS.claude.claudeMd)
  .action((targetDir, opts) => {
    const target = resolve(targetDir);
    const backend = parseBackend(opts.backend);

    let ok = doctorCore(target);
    if (backend === 'claude') {
      ok = doctorClaude(target, { pluginDir: opts.pluginDir, claudeMdPath: opts.claudeMd }) && ok;
    }

    console.log(ok ? 'doctor: OK' : 'doctor: issues found');
    process.exitCode = ok ? 0 : 1;
  });

program.parse();
