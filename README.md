# workmem

Claude Code-first project memory scaffolding with a plugin-backed integration layer.

`workmem` is no longer a handful of fixed markdown files glued onto `CLAUDE.md`.
The new direction is closer to a real agent memory system:
- a compact index
- semantic memory
- procedural memory
- episodic notes
- snapshots and legacy buckets
- Claude Code hooks + skill as the execution layer

The goal is simple: make Claude Code improve with use instead of re-learning the same repo over and over.

## Why this redesign

A plain `CLAUDE.md` is just context. It helps, but it does not guarantee Claude will proactively maintain project memory.

Claude Code plugins can bundle:
- hooks
- skills
- agents
- MCP servers

So `workmem` now uses the Claude extension model properly:
- **repo-local memory files** as source of truth
- **Claude Code plugin hooks** to inject memory context deterministically
- **Claude skill** to maintain and evolve memory structure over time

## What it creates

```text
your-project/
├── .agent/
│   └── memory/
│       ├── MEMORY.md
│       ├── .gitignore
│       ├── episodic/
│       │   └── YYYY-MM-DD.md
│       ├── semantic/
│       │   ├── active-context.md
│       │   ├── decisions.md
│       │   └── project.md
│       ├── procedural/
│       │   └── common-workflows.md
│       ├── snapshots/
│       └── legacy/
├── CLAUDE.md
└── .claude/
    └── plugins/
        └── workmem/
            ├── .claude-plugin/
            │   └── plugin.json
            ├── hooks/
            │   └── hooks.json
            ├── skills/
            │   └── maintain-workmem/
            │       └── SKILL.md
            └── scripts/
                ├── session-start.js
                └── user-prompt-submit.js
```

## Memory model

### `MEMORY.md`
The routing layer.
Keep it short. It points Claude to the right topic files and explains how the memory tree is organized.

### `semantic/*.md`
Durable knowledge:
- project facts
- architecture notes
- constraints
- decisions
- conventions

### `procedural/*.md`
Reusable workflows:
- build/test/release commands
- migration flows
- debugging playbooks
- recurring maintenance steps

### `episodic/YYYY-MM-DD.md`
What happened today:
- progress notes
- temporary findings
- debugging trail
- loose observations before promotion

### `snapshots/`
Backups before cleanup, compaction, or risky memory refactors.

### `legacy/`
Retired or superseded files.

## How it works

### Core memory layer
The repo keeps its memory in `.agent/memory/`.
Claude should not try to stuff everything into one file. `MEMORY.md` stays compact while topic files expand as needed.

### Claude Code adapter
The local plugin currently does more than just nudge Claude:
1. **SessionStart hook** injects a compact reminder + previews of `MEMORY.md`, active context, and the latest episodic note
2. **UserPromptSubmit hook** adds targeted reminders for continuation, wrap-up, and memory-heavy prompts
3. **TaskCompleted / Stop / SessionEnd hooks** create a deterministic memory-review checkpoint so Claude gets pushed to reconcile project memory before declaring work done
4. **maintain-workmem skill** teaches Claude how to route knowledge into semantic / procedural / episodic memory and keep the index clean
5. **local memory helper scripts** provide stable read / write / promote / reindex / review / sync / topic-create / archive / compact entry points that Claude can use through Bash
6. **local MCP server** exposes the same operations as first-class tools, so Claude can call workmem without shell glue

This is much closer to a self-evolving project memory loop inside Claude Code.

## Install

```bash
npm install -g workmem
```

Or use with `npx`:

```bash
npx workmem init .
```

## Quick start

Initialize in a project:

```bash
workmem init
```

Then run Claude Code with the local plugin scaffolded by `workmem`:

```bash
claude --plugin-dir ./.claude/plugins/workmem
```

Check scaffold health:

```bash
workmem doctor
```

Save a snapshot before a risky change:

```bash
workmem snapshot --name pre-refactor
```

## Command reference

### `workmem init`

Create the memory scaffold plus Claude Code plugin integration.

```bash
workmem init [target-dir] [--backend claude] [--plugin-dir .claude/plugins/workmem] [--claude-md CLAUDE.md]
```

### `workmem doctor`

Check whether the memory scaffold and Claude plugin files are present.

```bash
workmem doctor [target-dir] [--backend claude]
```

### `workmem snapshot`

Archive the current memory state into `snapshots/`.

```bash
workmem snapshot [target-dir] [--name label]
```

## Design principles

- markdown-only memory, easy to audit
- repo-local source of truth
- keep the index short, grow by topic files
- promote knowledge from episodic -> semantic / procedural
- Claude Code plugin as deterministic execution layer
- future backends should be adapters, not a rewrite of the memory tree

## Current scope

Right now `workmem` is intentionally focused on **Claude Code**.

Support for Codex, Gemini, OpenCode, and other agents is paused while the Claude backend is hardened.
The memory tree is kept generic on purpose so other adapters can be added back later without redoing project data.

## Local helper scripts

The Claude plugin now ships deterministic memory helpers:

```bash
node .claude/plugins/workmem/scripts/memory/read.js --help
node .claude/plugins/workmem/scripts/memory/write.js --help
node .claude/plugins/workmem/scripts/memory/promote.js --help
node .claude/plugins/workmem/scripts/memory/reindex.js --help
node .claude/plugins/workmem/scripts/memory/review.js --help
node .claude/plugins/workmem/scripts/memory/sync.js --help
node .claude/plugins/workmem/scripts/memory/topic-create.js --help
node .claude/plugins/workmem/scripts/memory/archive.js --help
node .claude/plugins/workmem/scripts/memory/compact.js --help
```

They are intentionally simple:
- `read.js` reads the index, latest episodic note, or a topic file
- `write.js` appends or replaces content in a routed memory file
- `promote.js` moves durable notes from episodic flow into semantic/procedural topics
- `reindex.js` refreshes `MEMORY.md` from the current topic tree
- `review.js` extracts candidate promotions from the latest episodic note
- `sync.js` starts with deterministic heuristics, and can optionally upgrade the result with an LLM extractor when `WORKMEM_LLM_URL`, `WORKMEM_LLM_API_KEY`, and `WORKMEM_LLM_MODEL` are set
- `topic-create.js` creates a new topic file when a subject outgrows the existing pages
- `archive.js` moves stale topics into `legacy/`
- `compact.js` trims noisy active files so the memory set stays usable

## Roadmap

- richer promotion heuristics from episodic -> semantic / procedural
- stronger MCP-backed memory operations on top of the local scripts
- richer doctor diagnostics
- marketplace-ready plugin packaging
- more adapters after the Claude backend is stable

## License

MIT
on heuristics from episodic -> semantic / procedural
- stronger MCP-backed memory operations on top of the local scripts
- richer doctor diagnostics
- marketplace-ready plugin packaging
- more adapters after the Claude backend is stable

## License

MIT
