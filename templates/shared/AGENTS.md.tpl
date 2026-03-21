# AGENTS.md

⚠️ **This project uses [workmem](https://github.com/peonai/workmem) for project memory. Follow the rules below BEFORE doing anything else.**

## Every session — mandatory read order

1. `.agent/memory/current/CURRENT.md` — what's happening now
2. `.agent/memory/current/TODOS.md` — pending tasks
3. `.agent/memory/learnings/LEARNINGS.md` — recent entries first

Only read `.agent/memory/START.md` on first encounter with this project (it has static context).

Do NOT skip this. Do NOT rely on auto-memory or system-level memory instead.

## When to update workmem

| Trigger | Action |
|---------|--------|
| Finished a feature/fix | Update `CURRENT.md` (active focus) |
| Left something unfinished | Add to `TODOS.md` with priority |
| Hit a non-obvious bug/gotcha | Append to `LEARNINGS.md` |
| Discovered a repeatable workflow | Append to `PROCEDURES.md` |
| Session ending | Review all 4 files, update if stale |

## workmem vs auto-memory

- **workmem** (`.agent/memory/`): project-scoped, shared across agents, version-controlled with the repo. This is the source of truth for project state.
- **auto-memory** (system-level): agent-scoped, not shared, not in git. Useful for personal preferences, not for project knowledge.

If something matters to the project, it goes in workmem. Period.

## Rules

- Keep notes short and operational
- Do not dump chat transcripts into memory files
- Do not create random files outside `.agent/memory/`
- Archive old material into `.agent/memory/archive/` instead of deleting
- **Never use system-level auto-memory as a substitute for workmem**
- **Always read workmem files before starting work, even if you think you remember the context**

## Supported agents

{{AGENT_LIST}}
