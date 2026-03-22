#!/usr/bin/env node
export function normalizeArray(value) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string' && item.trim()).map((item) => item.trim()) : [];
}

export function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

export function normalizeExtractedMemory(payload) {
  const project = payload?.project || {};
  const activeContext = payload?.activeContext || {};
  return {
    project: {
      purpose: normalizeString(project.purpose),
      users: normalizeString(project.users),
      stack: normalizeString(project.stack),
      runtime: normalizeString(project.runtime),
      dependencies: normalizeArray(project.dependencies),
      constraints: normalizeArray(project.constraints),
      references: normalizeArray(project.references),
    },
    activeContext: {
      now: normalizeString(activeContext.now),
      next: normalizeString(activeContext.next),
      risks: normalizeString(activeContext.risks),
      openThreads: normalizeArray(activeContext.openThreads),
      shortReminders: normalizeArray(activeContext.shortReminders),
    },
    decisions: normalizeArray(payload?.decisions),
    procedures: normalizeArray(payload?.procedures),
  };
}
