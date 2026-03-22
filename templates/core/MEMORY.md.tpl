# MEMORY

This file is the index for `.agent/memory/`.
Keep it concise. It should help Claude decide what to read next, not try to contain everything.

## Read This First
- `semantic/active-context.md` for current direction
- `semantic/project.md` for durable project facts
- `semantic/decisions.md` for important decisions and constraints
- `procedural/common-workflows.md` for repeatable commands and flows
- `episodic/{{TODAY}}.md` for today's running notes

## Routing Rules
- Durable facts, architecture, constraints, preferences -> `semantic/*.md`
- Repeatable workflows, build/test/release recipes -> `procedural/*.md`
- Session progress, debugging trails, temporary observations -> `episodic/YYYY-MM-DD.md`
- Old or replaced material -> `legacy/`
- Backups before cleanup or compaction -> `snapshots/`

## Active Topics
- `semantic/project.md` - what this project is and why it exists
- `semantic/active-context.md` - what is actively being worked on now
- `semantic/decisions.md` - important decisions, constraints, and tradeoffs
- `procedural/common-workflows.md` - commands and routines worth reusing

## Maintenance Rules
- Prefer updating topic files over growing this index
- Create new topic files when a subject becomes large enough to deserve its own page
- Keep episodic notes chronological and lightweight
- Promote stable lessons from episodic notes into semantic/procedural files
