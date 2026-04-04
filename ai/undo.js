/**
 * Snapshot & rollback for AI-suggested bookmark moves.
 * Uses chrome.storage.session (in-memory; cleared on extension disable/reload/update or browser restart).
 */

const SNAPSHOT_KEY = 'lb_undo_snapshot';

/**
 * Save a pre-move snapshot recording each bookmark's current location.
 * @param {Array<{ bookmarkId: string }>} suggestions - Suggestions about to be applied
 * @returns {Promise<string>} snapshotId
 */
export async function saveSnapshot(suggestions) {
  const snapshotId = Date.now().toString(36);
  const entries = [];

  for (const s of suggestions) {
    const id = s.bookmarkId;
    try {
      const [node] = await chrome.bookmarks.get(id);
      entries.push({ id, parentId: node.parentId, index: node.index });
    } catch {
      // Bookmark may have been deleted — skip
    }
  }

  await chrome.storage.session.set({
    [SNAPSHOT_KEY]: { id: snapshotId, entries, timestamp: Date.now() },
  });

  return snapshotId;
}

/**
 * Apply bookmark moves with notification suppression.
 * Creates new folders first, then moves bookmarks, clears the pending queue,
 * and sends a single bookmarks-changed broadcast at the end.
 *
 * @param {Array} suggestions - Accepted suggestions to apply
 * @returns {Promise<void>}
 */
export async function applyMoves(suggestions) {
  await chrome.runtime.sendMessage({ type: 'suppress-notifications' });
  try {
    // Create new folders first
    const newFolderMap = new Map(); // suggestedName -> created folder id
    const folderSuggestions = suggestions.filter(s => s.type === 'newFolder');
    for (const s of folderSuggestions) {
      const created = await chrome.bookmarks.create({
        parentId: s.parentFolderId,
        title: s.suggestedName,
      });
      newFolderMap.set(s.suggestedName, created.id);
    }

    // Move bookmarks (direct moves take priority; __new_ targets are handled
    // by the newFolder path below which creates the folder first)
    const moveSuggestions = suggestions.filter(s => s.type === 'move');
    const movedIds = new Set();
    for (const s of moveSuggestions) {
      if (s.targetFolderId.startsWith('__new_')) continue;
      try {
        await chrome.bookmarks.move(s.bookmarkId, { parentId: s.targetFolderId });
        movedIds.add(s.bookmarkId);
      } catch (err) {
        console.warn('[LazyBookmarks] move failed:', s.bookmarkId, err);
      }
    }

    // Move bookmarks for new folders (skip any already moved by direct moves)
    for (const s of folderSuggestions) {
      const folderId = newFolderMap.get(s.suggestedName);
      if (!folderId) continue;
      for (const bmId of (s.bookmarkIds || [])) {
        if (movedIds.has(bmId)) continue;
        try {
          await chrome.bookmarks.move(bmId, { parentId: folderId });
        } catch (err) {
          console.warn('[LazyBookmarks] move to new folder failed:', bmId, err);
        }
      }
    }

    // Clear pending queue
    await chrome.storage.local.set({ lb_pending_queue: [] });
  } finally {
    await chrome.runtime.sendMessage({ type: 'unsuppress-notifications' });
    // Trigger a single reload for the entire batch
    chrome.runtime.sendMessage({ type: 'bookmarks-changed' }).catch(() => {});
  }
}

/**
 * Undo a previous set of moves by restoring bookmarks to their saved locations.
 * @returns {Promise<boolean>} true if undo succeeded
 */
export async function undoMoves() {
  const stored = await chrome.storage.session.get(SNAPSHOT_KEY);
  const snapshot = stored[SNAPSHOT_KEY];
  if (!snapshot || !snapshot.entries.length) return false;

  await chrome.runtime.sendMessage({ type: 'suppress-notifications' });
  try {
    // Reverse order to restore correct indices
    const entries = [...snapshot.entries].reverse();
    for (const entry of entries) {
      try {
        await chrome.bookmarks.move(entry.id, {
          parentId: entry.parentId,
          index: entry.index,
        });
      } catch (err) {
        console.warn('[LazyBookmarks] undo move failed:', entry.id, err);
      }
    }

    // Clear snapshot
    await chrome.storage.session.remove(SNAPSHOT_KEY);
  } finally {
    await chrome.runtime.sendMessage({ type: 'unsuppress-notifications' });
    chrome.runtime.sendMessage({ type: 'bookmarks-changed' }).catch(() => {});
  }

  return true;
}
