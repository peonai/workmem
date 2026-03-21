# AGENTS.md

⚠️ **This project uses [workmem](https://github.com/peonai/workmem) for project memory. Follow the rules below BEFORE doing anything else.**

## Every session — mandatory read order

1. `.agent/memory/START.md` — project context and rules
2. `.agent/memory/current/CURRENT.md` — current state
3. `.agent/memory/current/TODOS.md` — pending tasks
4. `.agent/memory/learnings/LEARNINGS.md` — recent entries first

Do NOT skip this. Do NOT rely on auto-memory or system-level memory instead.

## During work

- Project state changed → update `CURRENT.md`
- Unfinished work → update `TODOS.md`
- Reusable lesson learned → append to `LEARNINGS.md`
- Stable workflow discovered → append to `.agent/memory/procedures/PROCEDURES.md`

## Rules

- Keep notes short and operational
- Do not dump chat transcripts into memory files
- Do not create random files outside `.agent/memory/`
- Archive old material into `.agent/memory/archive/` instead of deleting
- **Never use system-level auto-memory as a substitute for workmem**
- **Always read workmem files before starting work, even if you think you remember the context**

## Supported agents

{{AGENT_LIST}}
