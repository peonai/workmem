# workmem

Shared project memory scaffolding for Claude Code, Codex, Gemini, OpenCode, and other coding agents.

`workmem` gives your projects a lightweight, file-based working memory layer so coding agents stop restarting from zero every session.

## Why it exists

Coding agents are great at execution, but terrible at continuity. Without a durable place to keep project state, lessons, and pending tasks, every new session starts from scratch.

`workmem` standardizes that layer across tools without locking you into one AI vendor.

## What it creates

```text
your-project/
├── AGENTS.md                  # shared entry point for all agents
├── CLAUDE.md                  # Claude Code entry (created or updated)
├── CODEX.md                   # Codex entry (created or updated)
├── GEMINI.md                  # Gemini entry (created or updated)
├── OPENCODE.md                # OpenCode entry (created or updated)
└── .agent/
    └── memory/
        ├── START.md
        ├── current/
        │   ├── CURRENT.md
        │   └── TODOS.md
        ├── learnings/
        │   └── LEARNINGS.md
        ├── procedures/
        │   └── PROCEDURES.md
        └── archive/
```

## How it works

1. `workmem init` asks which agents you use
2. Creates `.agent/memory/` with shared templates
3. Creates `AGENTS.md` as the shared memory entry point
4. For each selected agent, creates or updates its native entry file (`CLAUDE.md`, `GEMINI.md`, etc.) to reference `AGENTS.md`

This means agents actually read the memory layer through their normal startup path. No extra configuration needed.

## Supported agents

| Agent | Entry file |
|-------|-----------|
| Claude Code | `CLAUDE.md` |
| Codex | `CODEX.md` |
| Gemini | `GEMINI.md` |
| OpenCode | `OPENCODE.md` |

## Install

```bash
npm install -g workmem
```

Or use with `npx`:

```bash
npx workmem init .
```

## Quick start

Initialize in a project (interactive agent selection):

```bash
workmem init
```

Or specify agents directly:

```bash
workmem init --agents claude,codex
```

Check scaffold health:

```bash
workmem doctor
```

Add more agents later:

```bash
workmem add-agent --agents opencode
```

Save a snapshot before a risky change:

```bash
workmem snapshot --name pre-release
```

## What `workmem init` does

1. Creates `.agent/memory/` directory structure with starter templates
2. Creates `AGENTS.md` with shared memory rules and read order
3. For each selected agent:
   - If the entry file (e.g. `CLAUDE.md`) does not exist, creates it with a workmem reference
   - If it already exists, appends a workmem reference (idempotent, won't duplicate)
4. Does not modify any source code, configs, or git settings
5. Does not install dependencies or contact external services

## Recommended workflow

1. Run `workmem init` once per project
2. Start your coding agent — it reads its entry file, which points to `AGENTS.md`
3. Keep `.agent/memory/current/CURRENT.md` updated when project state changes
4. Keep unfinished work in `.agent/memory/current/TODOS.md`
5. Write stable lessons into `.agent/memory/learnings/LEARNINGS.md`
6. Write reusable commands and flows into `.agent/memory/procedures/PROCEDURES.md`
7. Snapshot before large refactors, migrations, or releases

## Multi-agent projects

`workmem` is designed for projects where multiple agents work on the same codebase.

- All agents share one `.agent/memory/` directory
- All agents read `AGENTS.md` for shared rules
- Each agent keeps its own entry file for tool-specific instructions
- No conflicts, no duplication

## Git management

`workmem` generates a `.agent/memory/.gitignore` that separates shared and personal layers:

| Layer | Path | Git | Why |
|-------|------|-----|-----|
| Shared | `.agent/memory/START.md` | ✅ commit | Project context for the whole team |
| Shared | `.agent/memory/learnings/` | ✅ commit | Stable project lessons everyone benefits from |
| Shared | `.agent/memory/procedures/` | ✅ commit | Reusable workflows and commands |
| Shared | `AGENTS.md` | ✅ commit | Shared entry point |
| Personal | `.agent/memory/current/` | ❌ gitignored | Individual working state and todos |
| Personal | `.agent/memory/archive/` | ❌ gitignored | Personal snapshots |

We recommend committing `.agent/memory/` to your repo so team members and their agents share the same project knowledge.

## Design principles

- Markdown only, no hidden databases
- No external services or network calls
- Shared memory layer with per-agent entry points
- Optimized for session continuity, not semantic search
- `.agent/` as an extensible namespace for agent tooling
- Idempotent — safe to run multiple times

## What this is not

- Not a vector database
- Not a semantic search engine
- Not a chat transcript archive
- Not a replacement for project documentation

It is a practical working memory scaffold for day-to-day coding sessions.

## Command reference

### `workmem init`

Create the scaffold and wire up agent entry files.

```bash
workmem init [target-dir] [--agents claude,codex,gemini,opencode]
```

### `workmem add-agent`

Add new agent entry files without re-initializing.

```bash
workmem add-agent [target-dir] --agents <list>
```

### `workmem snapshot`

Archive the current memory state.

```bash
workmem snapshot [target-dir] [--name label]
```

### `workmem doctor`

Check whether the scaffold and core files are present.

```bash
workmem doctor [target-dir]
```

## Roadmap

- Richer `doctor` diagnostics
- Stack-aware starter templates
- Import helpers for existing project notes
- `workmem clean` for archiving stale entries

## License

MIT
