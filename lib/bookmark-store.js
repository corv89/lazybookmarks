/**
 * Unified bookmark data layer.
 * Single-pass fetch, normalize, stats, and flatten.
 */

const STORAGE_KEY = 'lazybookmarks_collapsed';

/**
 * Load the full bookmark tree, normalize it, compute per-folder stats,
 * and flatten bookmarks into a search-ready array — all in one recursive walk.
 *
 * @returns {{ tree: Array, stats: Map, flat: Array, nodeById: Map }}
 */
export async function loadBookmarks() {
  const raw = await chrome.bookmarks.getTree();
  const rootChildren = raw[0].children || [];
  const stats = new Map();
  const flat = [];
  const nodeById = new Map();

  walk(rootChildren, [], stats, flat, nodeById);

  return { tree: rootChildren, stats, flat, nodeById };
}

function walk(nodes, parentPath, stats, flat, nodeById) {
  let totalBookmarks = 0;
  let totalFolders = 0;

  for (const node of nodes) {
    node.isFolder = !('url' in node);
    node.path = [...parentPath, node.title].filter(Boolean);
    nodeById.set(node.id, node);

    if (node.isFolder) {
      totalFolders++;
      const directChildren = node.children ? node.children.length : 0;
      let bookmarkCount = 0;
      let folderCount = 0;

      if (node.children) {
        const nested = walk(node.children, node.path, stats, flat, nodeById);
        bookmarkCount = nested.bookmarks;
        folderCount = nested.folders;
      }

      node.isEmpty = directChildren === 0;
      stats.set(node.id, { bookmarkCount, folderCount, directChildren });
      totalBookmarks += bookmarkCount;
      totalFolders += folderCount;
    } else {
      totalBookmarks++;
      flat.push({
        id: node.id,
        title: node.title || '',
        url: node.url,
        path: node.path.slice(0, -1).join(' / '),
        parentId: node.parentId,
      });
    }
  }

  return { bookmarks: totalBookmarks, folders: totalFolders };
}

/** Load the collapsed folder ID set from storage. */
export async function loadCollapsed() {
  try {
    const stored = await chrome.storage.local.get(STORAGE_KEY);
    return new Set(stored[STORAGE_KEY] || []);
  } catch {
    return new Set();
  }
}

/** Persist the collapsed folder ID set to storage. */
export function saveCollapsed(collapsed) {
  try {
    chrome.storage.local.set({ [STORAGE_KEY]: [...collapsed] });
  } catch {
    // Ignore storage errors
  }
}

/** Remove IDs from the collapsed set that no longer exist in the stats map. */
export function pruneCollapsed(collapsed, stats) {
  for (const id of collapsed) {
    if (!stats.has(id)) collapsed.delete(id);
  }
}

/**
 * Determine root folder IDs dynamically via folderType (Chrome 134+).
 * Returns the IDs of "Bookmarks Bar" and "Other Bookmarks" root containers.
 * Cached after first call.
 */
let rootIds;
export async function getRootFolderIds() {
  if (rootIds) return rootIds;
  const [root] = await chrome.bookmarks.getTree();
  rootIds = new Set(
    root.children
      .filter(n => n.folderType === 'bookmarks-bar' || n.folderType === 'other')
      .map(n => n.id)
  );
  return rootIds;
}
