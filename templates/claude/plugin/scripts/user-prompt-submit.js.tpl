#!/usr/bin/env node
import { readFileSync } from 'fs';

function readJsonFromStdin() {
  try {
    const raw = readFileSync(0, 'utf8').trim();
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

const input = readJsonFromStdin();
const prompt = String(input.prompt || '').toLowerCase();

const continuation = /(continue|resume|pick up|where were we|继续|接着|继续做|接着做|上次|延续)/;
const wrapUp = /(wrap up|ship it|done|finished|complete|completed|总结|收工|今天差不多了|完成了|搞定了|结束)/;
const memoryHeavy = /(remember|memory|context|todo|todos|summary|summarize|recap|计划|待办|上下文|记忆|总结|复盘)/;
const decisionLike = /(decision|tradeoff|constraint|architecture|workflow|流程|约定|限制|架构|决策)/;

const hints = [];

if (continuation.test(prompt)) {
  hints.push('This looks like a continuation. Start from `.agent/memory/MEMORY.md`, then use workmem MCP tools to read the active context and latest episodic note when possible.');
}

if (wrapUp.test(prompt)) {
  hints.push('This looks like wrap-up/completion. Before finalizing, use workmem MCP tools to review memory and perform at least one write-class memory operation (sync, promote, write, reindex, topic creation, archive, or compact). Hand-editing memory files is fallback only.');
}

if (memoryHeavy.test(prompt)) {
  hints.push('This prompt depends on project memory. Prefer workmem over Claude auto-memory, and prefer workmem MCP tools over manual file editing when the tools are available. If memory must be updated in this task, you must use at least one write-class workmem MCP tool rather than stopping after reads.');
}

if (decisionLike.test(prompt)) {
  hints.push('If this changes a durable decision, constraint, or workflow, use a write-class workmem MCP tool to update or create the right semantic/procedural topic instead of leaving it only in today\'s notes.');
}

if (hints.length === 0) process.exit(0);

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext: hints.join('\n\n')
  }
}));
