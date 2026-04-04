/**
 * AI debug logging module.
 * Posts entries to BroadcastChannel for live viewing and persists to
 * chrome.storage.session for after-the-fact inspection.
 * No DOM dependencies — works in any extension context.
 */

import { CHANNEL_NAME, STORAGE_KEY } from './debug-constants.js';

const MAX_ENTRIES = 50;

let nextId = 0;
let channel;

try {
  channel = new BroadcastChannel(CHANNEL_NAME);
} catch {
  // BroadcastChannel unavailable in restricted contexts
}

// Write queue to avoid read-modify-write races under rapid calls
let pendingEntries = [];
let flushScheduled = false;

function flushToStorage() {
  flushScheduled = false;
  const batch = pendingEntries;
  pendingEntries = [];
  chrome.storage.session.get(STORAGE_KEY).then(result => {
    const log = result[STORAGE_KEY] || [];
    log.push(...batch);
    if (log.length > MAX_ENTRIES) log.splice(0, log.length - MAX_ENTRIES);
    chrome.storage.session.set({ [STORAGE_KEY]: log });
  }).catch(() => {});
}

/**
 * Log a debug entry.
 * @param {'prompt'|'response'|'error'|'phase'|'quota'|'stream'} type
 * @param {*} data
 * @returns {number} entry id
 */
export function debugLog(type, data) {
  const id = nextId++;
  const entry = { id, timestamp: Date.now(), type, data };

  if (channel) channel.postMessage(entry);

  // 'stream' entries are live-only — not persisted to storage.
  // On reload, debug.html shows clean prompt → response pairs with no frozen
  // empty stream placeholders.
  if (type !== 'stream') {
    pendingEntries.push(entry);
    if (!flushScheduled) {
      flushScheduled = true;
      queueMicrotask(flushToStorage);
    }
  }

  return id;
}

/**
 * Update a live 'stream' entry's text in the debug page.
 * Broadcast-only — not persisted to storage.
 * @param {number} id - Entry id returned from debugLog('stream', ...)
 * @param {string} text - Trimmed cumulative text from the stream so far
 */
export function debugPatch(id, text) {
  if (channel) channel.postMessage({ __patch__: true, id, text });
}
