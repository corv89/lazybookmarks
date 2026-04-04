/**
 * Context-independent AI bookmark organizer.
 * No DOM, no chrome.tabs, no chrome.action — portable to any execution context.
 * Depends only on: ai/language-model.js, ai/prompts.js, and data passed as arguments.
 */

import { checkAvailability, createSession, cloneSession, promptJSON, getQuota, measureUsage, destroySession } from './language-model.js';
import { debugLog } from './debug-log.js';
import { buildFingerprint, loadCachedTaxonomy, saveTaxonomy } from './taxonomy-cache.js';
import {
  SYSTEM_PROMPT,
  TAXONOMY_SCHEMA,
  buildClusterSchema,
  buildClassificationSchema,
  buildTaxonomyPrompt,
  buildClassificationPrompt,
  buildClusterPrompt,
} from './prompts.js';

const BATCH_SIZE = 1;

function extractDomainPatterns(bookmarks, threshold = 0.2) {
  const counts = new Map();
  for (const b of bookmarks) {
    try {
      const host = new URL(b.url).hostname.replace(/^www\./, '');
      counts.set(host, (counts.get(host) ?? 0) + 1);
    } catch {}
  }
  const total = bookmarks.length;
  return [...counts.entries()]
    .filter(([, n]) => n / total >= threshold)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([d]) => d);
}

function extractSiblings(nodeById, folderId) {
  const node = nodeById.get(folderId);
  if (!node?.parentId) return [];
  const parent = nodeById.get(node.parentId);
  if (!parent?.children) return [];
  return parent.children
    .filter(c => c.id !== folderId && c.children !== undefined)
    .map(c => c.title)
    .slice(0, 5);
}

const STOPWORDS = new Set(['the','a','an','and','or','of','to','in','for','is','on','with','at','by','from','this','that','it','as','are','was','be','has','have']);

function computeTFIDF(folderBookmarksMap, allBookmarks) {
  const tokenize = t => (t || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').split(/\s+/).filter(w => w.length > 2 && !STOPWORDS.has(w));
  const df = new Map();
  const N = allBookmarks.length || 1;
  for (const b of allBookmarks) {
    for (const t of new Set(tokenize(b.title))) df.set(t, (df.get(t) ?? 0) + 1);
  }
  const idf = t => Math.log(N / (1 + (df.get(t) ?? 0)));
  const result = new Map();
  for (const [folderId, bookmarks] of folderBookmarksMap) {
    if (bookmarks.length === 0) { result.set(folderId, []); continue; }
    const tf = new Map();
    for (const b of bookmarks) for (const t of tokenize(b.title)) tf.set(t, (tf.get(t) ?? 0) + 1);
    const keywords = [...tf.entries()]
      .map(([t, f]) => ({ t, score: (f / bookmarks.length) * idf(t) }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 6)
      .map(e => e.t);
    result.set(folderId, keywords);
  }
  return result;
}

function sampleExemplars(bookmarks, count = 2) {
  return [...bookmarks]
    .sort((a, b) => (b.dateAdded ?? 0) - (a.dateAdded ?? 0))
    .slice(0, count)
    .map(b => {
      let host = b.url;
      try { host = new URL(b.url).hostname.replace(/^www\./, ''); } catch {}
      return { title: (b.title || 'Untitled').slice(0, 40), url: host };
    });
}

const CATCHALL_NAMES = new Set([
  'unsorted', 'misc', 'temp', 'todo', 'read later',
  'unfiled', 'uncategorized', 'inbox', 'new', 'stuff',
]);

const UNTITLED_PATTERNS = [
  '', 'untitled', 'new tab', 'about:blank',
];

/**
 * Find uncategorized bookmarks using heuristics (no AI involved).
 *
 * A bookmark is uncategorized if ANY condition holds:
 * 1. Root orphan: parentId is in rootFolderIds AND parent has >15 direct children
 * 2. Catch-all folder: parent named "Unsorted"/"Misc"/"Temp" etc. (case-insensitive)
 * 3. Untitled: no title, or title === url, or matches "Untitled"/"New Tab"
 *
 * @param {Array} flat - Flat bookmark array from bookmark-store
 * @param {Map} nodeById - Node lookup map from bookmark-store
 * @param {Map} stats - Per-folder stats from bookmark-store
 * @param {Set} rootFolderIds - Root folder IDs (from getRootFolderIds)
 * @returns {Array} Uncategorized bookmarks
 */
export function getUncategorizedBookmarks(flat, nodeById, stats, rootFolderIds) {
  return flat.filter(bookmark => {
    const parent = nodeById.get(bookmark.parentId);
    if (!parent) return false;

    // Rule 1: Bookmarks bar / Other bookmarks are always uncategorized containers
    if (rootFolderIds.has(bookmark.parentId)) return true;

    // Rule 2: Catch-all folder
    if (parent.title && CATCHALL_NAMES.has(parent.title.toLowerCase().trim())) {
      return true;
    }

    // Rule 3: Untitled or title matches URL
    const title = (bookmark.title || '').toLowerCase().trim();
    if (UNTITLED_PATTERNS.includes(title) || title === bookmark.url) {
      return true;
    }

    return false;
  });
}

function buildFolderPath(nodeById, folderId, rootFolderIds) {
  const parts = [];
  let current = nodeById.get(folderId);
  while (current) {
    if (current.title && !rootFolderIds?.has(current.id)) parts.unshift(current.title);
    current = current.parentId ? nodeById.get(current.parentId) : null;
  }
  return parts.join(' / ') || folderId;
}

/**
 * Return a taxonomy slice containing the top-N most relevant folders
 * for a given bookmark batch, scored by keyword overlap.
 *
 * @param {object} taxonomy - Full taxonomy from Phase 1
 * @param {Array} batch - Current bookmark batch
 * @param {Map} tfidfMap - Map<folderId, string[]> from computeTFIDF()
 * @param {number} topN - Max folders to include (default 15)
 * @param {number} minN - Minimum folders regardless of score (default 5)
 * @returns {object} Pruned taxonomy { categories: [...] }
 */
function pruneTaxonomy(taxonomy, batch, tfidfMap, topN = 15, minN = 5) {
  const tokenize = t => (t || '').toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !STOPWORDS.has(w));

  const batchTokens = new Set(batch.flatMap(b => tokenize(b.title)));

  const scored = taxonomy.categories.map(c => {
    const keywords = tfidfMap.get(c.folderId) ?? [];
    const overlap = keywords.filter(k => batchTokens.has(k)).length;
    return { category: c, overlap };
  });

  // Stable sort: overlap DESC, then folderId ASC (deterministic tie-breaking)
  scored.sort((a, b) =>
    b.overlap - a.overlap ||
    a.category.folderId.localeCompare(b.category.folderId)
  );

  const count = Math.min(Math.max(topN, minN), scored.length);
  return { categories: scored.slice(0, count).map(s => s.category) };
}

/**
 * Run the full two-phase AI organization pipeline.
 *
 * @param {{ tree: Array, stats: Map, flat: Array, nodeById: Map }} bookmarkData
 * @param {Array} pendingQueue - Queued new bookmarks from background.js
 * @param {object} callbacks
 * @param {Function} callbacks.onPhaseChange - ('taxonomy' | 'classify' | 'done')
 * @param {Function} callbacks.onProgress - (current, total)
 * @param {Function} callbacks.onSuggestion - (suggestion) emitted per-batch
 * @param {Function} callbacks.onError - (error)
 * @param {Function} [callbacks.onQuotaWarning] - (quotaInfo)
 * @param {Function} [callbacks.onDownloadProgress] - (e) download progress event
 * @param {AbortSignal} [callbacks.signal]
 * @param {Set} rootFolderIds - Root folder IDs
 */
export async function organizeBookmarks(bookmarkData, pendingQueue, callbacks, rootFolderIds) {
  const { tree, stats, flat, nodeById } = bookmarkData;
  const signal = callbacks.signal;

  // Merge smart-scan results + pending queue, deduplicate by id
  const uncategorized = getUncategorizedBookmarks(flat, nodeById, stats, rootFolderIds);
  const seen = new Set(uncategorized.map(b => b.id));
  for (const pending of pendingQueue) {
    if (!seen.has(pending.id)) {
      uncategorized.push(pending);
      seen.add(pending.id);
    }
  }

  // Drop non-web URLs (chrome://, about:, file://, etc.) — constrained decoding
  // can stall on these since they match no folder and the model struggles to emit __skip__.
  const webUncategorized = uncategorized.filter(b => /^https?:\/\//i.test(b.url));

  if (webUncategorized.length === 0) {
    callbacks.onPhaseChange('done');
    return;
  }

  let session;
  try {
    callbacks.onProgress(0, webUncategorized.length);

    // If model is still downloading, signal the UI before blocking on create()
    const status = await checkAvailability();
    if (status === 'downloading' || status === 'downloadable') {
      callbacks.onPhaseChange('download');
    }

    session = await createSession(SYSTEM_PROMPT, {
      signal,
      onDownloadProgress: callbacks.onDownloadProgress,
    });

    // --- Fingerprint (always computed, cheap) ---
    const currentFP = buildFingerprint(stats);

    // --- Enrichment data (always computed, no LLM) ---
    const allBookmarks = flat.filter(b => b.url);
    const folderBookmarksMap = new Map();
    for (const [id, node] of nodeById) {
      if (node.children !== undefined) {
        folderBookmarksMap.set(id, allBookmarks.filter(b => b.parentId === id));
      }
    }
    const tfidfMap = computeTFIDF(folderBookmarksMap, allBookmarks);

    // --- Phase 1: Taxonomy (warm or cold path) ---
    let taxonomy = await loadCachedTaxonomy(currentFP);

    if (!taxonomy) {
      // Cold path: run Phase 1
      callbacks.onPhaseChange('taxonomy');

      const enrichedFolders = [...folderBookmarksMap.keys()].filter(folderId => !rootFolderIds.has(folderId)).map(folderId => {
        const bookmarks = folderBookmarksMap.get(folderId);
        return {
          folderId,
          folderPath: buildFolderPath(nodeById, folderId, rootFolderIds),
          bookmarkCount: bookmarks.length,
          domains: extractDomainPatterns(bookmarks),
          siblings: extractSiblings(nodeById, folderId),
          tfidfKeywords: tfidfMap.get(folderId) ?? [],
          exemplars: sampleExemplars(bookmarks, 2),
        };
      });

      const taxonomyPrompt = buildTaxonomyPrompt(enrichedFolders);
      taxonomy = await promptJSON(session, taxonomyPrompt, TAXONOMY_SCHEMA, signal);

      // Fire-and-forget save
      saveTaxonomy(currentFP, taxonomy);
    }
    // else: warm path — taxonomy loaded from cache, Phase 1 skipped

    // Always strip root containers (Bookmarks bar, Other bookmarks) from the
    // taxonomy — they are not valid classification targets. This also cleans up
    // any stale cache entries saved before this filter was introduced.
    taxonomy = {
      categories: taxonomy.categories.filter(c => !rootFolderIds.has(c.folderId)),
    };

    // --- Phase 1.5: Cluster analysis of uncategorized bookmarks ---
    callbacks.onPhaseChange('cluster');
    // New folders must land at root level (Bookmarks bar / Other bookmarks),
    // not nested inside existing sub-folders. Build the root folder list so
    // the prompt and schema constrain parentFolderId to only root containers.
    const rootFolders = [...rootFolderIds]
      .map(id => nodeById.get(id))
      .filter(Boolean)
      .map(n => ({ id: n.id, title: n.title || 'Bookmarks bar' }));
    const clusterPrompt = buildClusterPrompt(webUncategorized, taxonomy, rootFolders);
    const clusterFolderIds = rootFolders.map(f => f.id);
    let suggestedFolders = [];
    try {
      const clusterResult = await promptJSON(session, clusterPrompt, buildClusterSchema(clusterFolderIds), signal);
      suggestedFolders = clusterResult.clusters.map((c, i) => ({
        folderId: `__new_${i}`,
        folderPath: c.name,
        description: c.description,
        keywords: c.keywords,
        parentFolderId: c.parentFolderId,
      }));
      debugLog('cluster', { suggested: suggestedFolders.map(f => f.folderPath) });
    } catch (err) {
      debugLog('cluster', { error: err.message });
    }

    // Merge suggested folders into taxonomy for Phase 2
    taxonomy = {
      categories: [...taxonomy.categories, ...suggestedFolders],
    };

    // Phase 2: Classification in batches
    callbacks.onPhaseChange('classify');
    const batches = [];
    for (let i = 0; i < webUncategorized.length; i += BATCH_SIZE) {
      batches.push(webUncategorized.slice(i, i + BATCH_SIZE));
    }

    // Clone session after Phase 1.5 — each batch gets a fresh clone of this base,
    // preventing context accumulation across batches.
    // session may be in a bad state if Phase 1.5's promptJSON was aborted.
    // If clone fails, fall back to a fresh session — classification prompts are
    // self-contained and don't require Phase 1/1.5 conversation history.
    let baseSession;
    try {
      baseSession = await cloneSession(session, signal);
    } catch {
      baseSession = await createSession(SYSTEM_PROMPT, { signal });
    }

    const newFolderMoves = new Map(); // folderId (__new_N) → Set of bookmarkIds
    let processed = 0;
    for (const batch of batches) {
      if (signal?.aborted) break;

      const prunedTaxonomy = pruneTaxonomy(taxonomy, batch, tfidfMap);
      debugLog('pruning', {
        batchSize: batch.length,
        totalFolders: taxonomy.categories.length,
        prunedTo: prunedTaxonomy.categories.length,
      });
      const prunedFolderIds = prunedTaxonomy.categories.map(c => c.folderId);
      const batchBookmarkIds = batch.map(b => b.id);
      const classificationSchema = buildClassificationSchema(prunedFolderIds, batchBookmarkIds);
      const prompt = buildClassificationPrompt(prunedTaxonomy, batch);

      const batchSession = await cloneSession(baseSession, signal);
      try {
        const result = await promptJSON(batchSession, prompt, classificationSchema, signal);

        // Emit each suggestion individually for progressive UI
        for (const move of result.moves) {
          if (move.targetFolderId === '__skip__') continue;

          if (move.targetFolderId.startsWith('__new_')) {
            if (!newFolderMoves.has(move.targetFolderId)) {
              newFolderMoves.set(move.targetFolderId, new Set());
            }
            newFolderMoves.get(move.targetFolderId).add(move.bookmarkId);
          }

          const bookmark = nodeById.get(move.bookmarkId) || webUncategorized.find(b => b.id === move.bookmarkId);
          const sf = move.targetFolderId.startsWith('__new_')
            ? suggestedFolders.find(f => f.folderId === move.targetFolderId)
            : null;
          const targetFolder = sf ? null : nodeById.get(move.targetFolderId);
          callbacks.onSuggestion({
            type: 'move',
            bookmarkId: move.bookmarkId,
            bookmarkTitle: bookmark?.title || '',
            bookmarkUrl: bookmark?.url || '',
            targetFolderId: move.targetFolderId,
            targetFolderPath: sf
              ? `${sf.folderPath} (new)`
              : targetFolder?.path?.join(' / ') || move.targetFolderId,
            confidence: move.confidence,
            reason: move.reason,
            requiresConfirmation: sf ? true : move.confidence !== 'high',
          });
        }

      } catch (err) {
        debugLog('error', { message: `batch failed: ${err.message}`, batch: batch.map(b => b.id) });
        callbacks.onError(err);
      } finally {
        destroySession(batchSession);
      }

      processed += batch.length;
      callbacks.onProgress(processed, webUncategorized.length);
    }

    destroySession(baseSession);

    // Emit newFolder suggestions collected from __new_ moves across all batches
    for (const [folderId, bookmarkIds] of newFolderMoves) {
      const sf = suggestedFolders.find(f => f.folderId === folderId);
      if (!sf) continue;
      const parentFolder = nodeById.get(sf.parentFolderId);
      callbacks.onSuggestion({
        type: 'newFolder',
        suggestedName: sf.folderPath,
        parentFolderId: sf.parentFolderId,
        parentFolderPath: parentFolder?.path?.join(' / ') || '',
        bookmarkIds: [...bookmarkIds],
      });
    }

    callbacks.onPhaseChange('done');
  } catch (err) {
    if (err.name !== 'AbortError') {
      callbacks.onError(err);
    }
  } finally {
    destroySession(session);
  }
}
