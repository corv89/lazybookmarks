import { debugLog } from './debug-log.js';

/**
 * Build a compact fingerprint of the current folder structure.
 * @param {Map} stats - Per-folder stats from bookmark-store
 * @returns {object} Plain object mapping folderId → bookmarkCount
 */
export function buildFingerprint(stats) {
  const fp = {};
  for (const [id, s] of stats) {
    fp[id] = s.bookmarkCount;
  }
  return fp;
}

/**
 * @param {object} current
 * @param {object} stored
 * @returns {boolean}
 */
function fingerprintMatches(current, stored) {
  const currentIds = Object.keys(current);
  const storedIds = Object.keys(stored);
  if (currentIds.length !== storedIds.length) return false;
  for (const id of currentIds) {
    if (!(id in stored)) return false;
    if (Math.abs(current[id] - stored[id]) > 5) return false;
  }
  return true;
}

/**
 * Load a cached taxonomy if the fingerprint still matches.
 * Returns null on any error or mismatch (fail-safe).
 * @param {object} currentFP
 * @returns {Promise<object|null>}
 */
export async function loadCachedTaxonomy(currentFP) {
  try {
    const result = await chrome.storage.local.get('lb_taxonomy_cache_v2');
    const entry = result['lb_taxonomy_cache_v2'];
    if (!entry?.fingerprint || !entry?.taxonomy?.categories) {
      debugLog('cache', { hit: false, reason: 'missing-or-malformed' });
      return null;
    }
    if (!fingerprintMatches(currentFP, entry.fingerprint)) {
      debugLog('cache', { hit: false, reason: 'fingerprint-mismatch' });
      return null;
    }
    debugLog('cache', {
      hit: true,
      foldersLoaded: entry.taxonomy.categories.length,
      ageMs: Date.now() - entry.createdAt,
    });
    return entry.taxonomy;
  } catch (err) {
    debugLog('cache', { hit: false, reason: 'error', error: err.message });
    return null;
  }
}

/**
 * Persist taxonomy to chrome.storage.local. Fire-and-forget — errors are
 * swallowed (quota exceeded, etc.) so the pipeline is never affected.
 * @param {object} currentFP
 * @param {object} taxonomy
 */
export async function saveTaxonomy(currentFP, taxonomy) {
  try {
    await chrome.storage.local.set({
      lb_taxonomy_cache_v2: {
        fingerprint: currentFP,
        taxonomy,
        createdAt: Date.now(),
      },
    });
    debugLog('cache', { saved: true, folders: taxonomy.categories.length });
  } catch (err) {
    debugLog('cache', { saved: false, error: err.message });
  }
}
