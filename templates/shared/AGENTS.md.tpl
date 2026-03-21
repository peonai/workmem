# AGENTS.md

⚠️ **This project uses [workmem](https://github.com/peonai/workmem). Follow the rules below — they are not optional.**

## Session start — read first

1. `.agent/memory/WORKMEM.md` — current state, todos, learnings, procedures (all in one file)

Only read `.agent/memory/START.md` on first encounter with this project (static context).

Do NOT skip this. Do NOT rely on auto-memory or system-level memory instead.

## Session end — mandatory checklist

Before ending your session, review `.agent/memory/WORKMEM.md` and update if any of these apply:

- [ ] **Current State** changed (finished a feature, shifted focus)
- [ ] **TODOs** changed (new tasks, completed tasks)
- [ ] **Learnings** to add (hit a non-obvious bug, discovered a gotcha)
- [ ] **Procedures** to add (found a repeatable workflow)

If nothing changed, you don't need to update. But you must check.

## workmem vs auto-memory

- **workmem** (`.agent/memory/`): project-scoped, shared across agents, version-controlled. Source of truth for project state.
- **auto-memory** (system-level): agent-scoped, not shared, not in git. Only for personal preferences — never for project knowledge.

## Rules

- Keep notes short and operational
- Do not dump chat transcripts into memory files
- Do not create random files outside `.agent/memory/`
- Archive old material into `.agent/memory/archive/` instead of deleting
- **Never use system-level auto-memory as a substitute for workmem**

## Supported agents

{{AGENT_LIST}}
