# Contributing

## Development

```bash
node bin/workmem.js init /tmp/workmem-demo
node bin/workmem.js doctor /tmp/workmem-demo
```

## Principles

- Keep the scaffold simple and file-based
- Prefer markdown over hidden binary or database state
- Optimize for session continuity, not semantic search
- Avoid tool-specific lock-in when a shared convention works

## Pull requests

Please keep changes focused. For new commands or templates, update `README.md` and include a concrete usage example.
