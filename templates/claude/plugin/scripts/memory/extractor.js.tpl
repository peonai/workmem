#!/usr/bin/env node
import { join } from 'path';
import { readText } from './common.js';

function safeJsonParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function trimLines(text, maxLines = 80) {
  return (text || '').split(/\r?\n/).slice(0, maxLines).join('\n');
}

export function extractorConfigFromEnv(env = process.env) {
  return {
    url: env.WORKMEM_LLM_URL || '',
    apiKey: env.WORKMEM_LLM_API_KEY || '',
    model: env.WORKMEM_LLM_MODEL || '',
  };
}

export function hasExtractorConfig(env = process.env) {
  const cfg = extractorConfigFromEnv(env);
  return Boolean(cfg.url && cfg.apiKey && cfg.model);
}

export function buildExtractorPrompt({ cwd, episodic, packageJson, readme, entrySource }) {
  return [
    'You extract structured repo memory for workmem.',
    'Return JSON only. No markdown. No commentary.',
    'Schema:',
    JSON.stringify({
      project: {
        purpose: '',
        users: '',
        stack: '',
        runtime: '',
        dependencies: [],
        constraints: [],
        references: [],
      },
      activeContext: {
        now: '',
        next: '',
        risks: '',
        openThreads: [],
        shortReminders: [],
      },
      decisions: [],
      procedures: [],
    }),
    '',
    'Rules:',
    '- Be concise and repo-specific',
    '- Do not invent facts not supported by the provided context',
    '- Use empty strings or empty arrays when unknown',
    '- Prefer stable project facts over speculative guesses',
    '',
    `Repo path: ${cwd}`,
    '',
    'package.json:',
    trimLines(packageJson, 120),
    '',
    'README.md:',
    trimLines(readme, 120),
    '',
    'Entry source:',
    trimLines(entrySource, 160),
    '',
    'Latest episodic note:',
    trimLines(episodic, 120),
  ].join('\n');
}

export async function extractStructuredMemory({ cwd, episodicPath, entryPoint }) {
  const cfg = extractorConfigFromEnv();
  if (!cfg.url || !cfg.apiKey || !cfg.model) return null;

  const packageJson = readText(join(cwd, 'package.json')) || '';
  const readme = readText(join(cwd, 'README.md')) || '';
  const episodic = readText(episodicPath) || '';
  const entrySource = entryPoint ? (readText(join(cwd, entryPoint)) || '') : '';
  const prompt = buildExtractorPrompt({ cwd, episodic, packageJson, readme, entrySource });

  const response = await fetch(cfg.url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${cfg.apiKey}`,
    },
    body: JSON.stringify({
      model: cfg.model,
      input: prompt,
    }),
  });

  if (!response.ok) {
    throw new Error(`extractor request failed: ${response.status}`);
  }

  const payload = await response.json();
  
  // Support multiple response formats:
  // - OpenAI Responses API: payload.output_text or payload.output[0].content[0].text
  // - OpenAI Chat Completions: payload.choices[0].message.content
  // - Anthropic Messages: payload.content[0].text
  const text = 
    payload.output_text || 
    payload.output?.[0]?.content?.[0]?.text || 
    payload.choices?.[0]?.message?.content || 
    payload.content?.[0]?.text || 
    '';
  
  const parsed = safeJsonParse(typeof text === 'string' ? text.trim() : '');
  if (!parsed) throw new Error('extractor returned non-JSON output');
  return parsed;
}
