---
name: maintain-workmem
description: Keep `.agent/memory/` aligned with project reality. Use when resuming work, completing a meaningful task, capturing a reusable lesson, or wrapping up a session.
---

The workmem files are the project memory source of truth for this repo.

Priority rule:
- when workmem MCP tools are available, prefer them over direct file editing for memory reads, writes, promotion, topic creation, archiving, compaction, and reindexing
- direct file editing is the fallback path, not the default path

Memory model:
1. `.agent/memory/MEMORY.md` - compact index and routing layer
2. `.agent/memory/semantic/*.md` - durable facts, decisions, constraints, architecture notes
3. `.agent/memory/procedural/*.md` - repeatable workflows and commands
4. `.agent/memory/episodic/YYYY-MM-DD.md` - dated progress notes, debugging trails, temporary findings
5. `.agent/memory/snapshots/` - backups before cleanup or major rewrites
6. `.agent/memory/legacy/` - retired or replaced files

Read order:
1. `.agent/memory/MEMORY.md`
2. files referenced by the index that matter for the current task
3. the latest episodic note when recent context matters

Write rules:
- Keep `MEMORY.md` concise; it should route, not duplicate everything
- Update an existing topic file when possible
- Create a new topic file when a subject is large, recurring, or clearly separate
- Move durable knowledge out of episodic notes into semantic/procedural files
- Do not dump chat transcripts into memory

Routing guide:
- fact / constraint / architecture note -> `semantic/*.md`
- repeatable command / release flow / debugging recipe -> `procedural/*.md`
- what happened today / current debugging trail / loose findings -> `episodic/YYYY-MM-DD.md`
- superseded material -> `legacy/`

Preferred MCP tools:
- `workmem_read`
- `workmem_write`
- `workmem_promote`
- `workmem_review`
- `workmem_sync`
- `workmem_reindex`
- `workmem_topic_create`
- `workmem_archive`
- `workmem_compact`

Built-in local helpers are the fallback path through Bash:
- `node .claude/plugins/workmem/scripts/memory/read.js --help`
- `node .claude/plugins/workmem/scripts/memory/write.js --help`
- `node .claude/plugins/workmem/scripts/memory/promote.js --help`
- `node .claude/plugins/workmem/scripts/memory/reindex.js --help`
- `node .claude/plugins/workmem/scripts/memory/review.js --help`
- `node .claude/plugins/workmem/scripts/memory/sync.js --help`
- `node .claude/plugins/workmem/scripts/memory/topic-create.js --help`
- `node .claude/plugins/workmem/scripts/memory/archive.js --help`
- `node .claude/plugins/workmem/scripts/memory/compact.js --help`

Default memory maintenance sequence:
1. call `workmem_read` to load the current memory state
2. call `workmem_sync` to push fresh notes into the right buckets
3. call `workmem_reindex` to refresh `MEMORY.md`

Optional follow-up tools when needed:
4. call `workmem_promote` for precise moves when you want control
5. call `workmem_topic_create` when a new subject deserves its own page
6. call `workmem_archive` for stale or superseded topic files
7. call `workmem_compact` when active memory starts bloating

Only fall back to direct file edits or Bash helpers when MCP tools are unavailable or clearly insufficient.

Completion rule:
- if you changed project memory in this task, the default sequence `workmem_read -> workmem_sync -> workmem_reindex` is the expected path
- reading through MCP alone does not satisfy the rule

Before considering work complete, check whether one of these changed:
- active direction or next step
- a durable project fact or constraint
- an important decision or tradeoff
- a reusable workflow
- today’s running notes

If yes, update the relevant files, promote durable knowledge out of episodic notes, and keep `MEMORY.md` in sync with the new structure.
