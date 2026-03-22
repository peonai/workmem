# Changelog

## 2.6.0

- strengthen Claude-facing instructions so workmem MCP tools become the default memory path instead of a nice-to-have
- make direct markdown editing an explicit fallback path for memory maintenance
- bias session hooks and the maintain-workmem skill toward MCP-first behavior

## 2.5.0

- add lifecycle-complete memory tools: `topic-create`, `archive`, and `compact`
- expose the full workmem lifecycle over MCP, not just read/write/promotion
- make it possible to create, retire, and trim memory topics without leaving Claude tools
- move the system closer to a complete local memory operating model for Claude Code

## 2.4.0

- add a local stdio MCP server and generated `mcp.json` config for Claude Code
- expose workmem operations as MCP tools: read, write, promote, review, sync, reindex
- refactor helper scripts so the MCP server can import and call them directly
- make Claude integration less dependent on Bash glue

## 2.3.0

- add `review.js` and `sync.js` to turn pending-review from a reminder into a concrete promotion workflow
- update lifecycle review output with suggested commands
- update the Claude skill to recommend `review -> promote/sync -> reindex` as the default wrap-up loop
- push the Claude Code backend closer to semi-automatic memory promotion

## 2.2.0

- add TaskCompleted / Stop / SessionEnd lifecycle hooks to force a deterministic memory review checkpoint
- add local memory helper scripts for read / write / promote / reindex operations
- update the Claude skill to use the helper scripts when they provide a more reliable path than hand-editing
- push the Claude Code backend closer to a self-evolving project memory loop

## 2.1.0

- redesign the memory tree around `MEMORY.md` plus `episodic/`, `semantic/`, `procedural/`, `snapshots/`, and `legacy/`
- stop treating each memory area as a single markdown file
- update the Claude Code plugin prompts and skill to route knowledge by memory type
- seed a daily episodic note during `init`
- make `snapshot` archive the active memory buckets into `snapshots/`
- move the project closer to a self-evolving Claude Code memory system

## 2.0.0

- redesign `workmem` around a **core memory layer + Claude Code backend**
- remove built-in multi-agent entry-file wiring for Codex / Gemini / OpenCode
- add Claude Code local plugin scaffold under `.claude/plugins/workmem`
- add SessionStart and UserPromptSubmit hook templates
- add `maintain-workmem` Claude skill
- keep `.agent/memory/` as the repo-local source of truth for future backends
- simplify CLI around `init`, `doctor`, and `snapshot`

## 1.0.0

- Initial public release
- `workmem init` for shared project memory scaffolding
- `workmem doctor` for scaffold health checks
- Built-in agent guides for Claude Code, Codex, Gemini, and OpenCode
- Shared templates for current state, todos, learnings, and procedures
