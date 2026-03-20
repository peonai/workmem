# AGENTS.md

This project uses a shared working memory layer managed by [workmem](https://github.com/peonai/workmem).

## Before starting work

Read these files in order:

1. `.agent/memory/START.md` — project context and rules
2. `.agent/memory/current/CURRENT.md` — current state
3. `.agent/memory/current/TODOS.md` — pending tasks
4. `.agent/memory/learnings/LEARNINGS.md` — recent entries

## During work

- Update `CURRENT.md` when the project state changes
- Update `TODOS.md` for unfinished work
- Append reusable lessons to `LEARNINGS.md`
- Append stable workflows to `.agent/memory/procedures/PROCEDURES.md`

## Rules

- Keep notes short and operational
- Do not dump chat transcripts into memory files
- Do not create random files outside `.agent/memory/`
- Archive old material into `.agent/memory/archive/` instead of deleting

## Supported agents

{{AGENT_LIST}}
