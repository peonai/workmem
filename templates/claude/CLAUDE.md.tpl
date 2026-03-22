## workmem

This project uses `workmem` as the repo-local memory system.

Source of truth:
- `.agent/memory/MEMORY.md` - index and routing layer
- `.agent/memory/semantic/*.md` - durable project knowledge and decisions
- `.agent/memory/procedural/*.md` - reusable workflows
- `.agent/memory/episodic/YYYY-MM-DD.md` - dated session notes

If the local workmem plugin is enabled, follow its hooks and skill.
If the plugin is not enabled, manually read and maintain the files above.

Rules:
- project knowledge belongs in workmem, not only in Claude auto-memory
- if workmem MCP tools are available, use them as the default path for memory operations
- when memory changes, default to `workmem_read -> workmem_sync -> workmem_reindex`
- only edit `.agent/memory/` files directly when MCP tools are unavailable or clearly insufficient for the task
- keep `MEMORY.md` short; move details into topic files
- promote stable knowledge from episodic notes into semantic/procedural files
- create new topic files when a subject no longer fits cleanly in an existing one
