/**
 * All prompt templates and JSON schemas as pure data.
 * No DOM dependencies — portable to any execution context.
 */

// --- System Prompt ---

export const SYSTEM_PROMPT = `You are a bookmark classifier. Given a user's folder structure and uncategorized bookmarks, assign each to the most appropriate existing folder. If no folder fits well, set targetFolderId to "__skip__" instead of forcing a poor match. Respond with valid JSON matching the provided schema. Prefer the user's existing folder names. Only suggest new folders when necessary.`;

// --- JSON Schemas (for responseConstraint) ---

export const TAXONOMY_SCHEMA = {
  type: 'object',
  properties: {
    categories: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          folderId: { type: 'string' },
          folderPath: { type: 'string' },
          description: { type: 'string' },
          keywords: { type: 'array', items: { type: 'string' }, maxItems: 10 },
        },
        required: ['folderId', 'folderPath', 'description', 'keywords'],
        additionalProperties: false,
      },
    },
  },
  required: ['categories'],
  additionalProperties: false,
};

export function buildClusterSchema(rootFolderIds) {
  return {
    type: 'object',
    properties: {
      clusters: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name:           { type: 'string' },
            description:    { type: 'string' },
            keywords:       { type: 'array', items: { type: 'string' }, maxItems: 8 },
            parentFolderId: { type: 'string', enum: rootFolderIds },
          },
          required: ['name', 'description', 'keywords', 'parentFolderId'],
          additionalProperties: false,
        },
      },
    },
    required: ['clusters'],
    additionalProperties: false,
  };
}

export function buildClassificationSchema(folderIds, bookmarkIds) {
  return {
    type: 'object',
    properties: {
      moves: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            bookmarkId: { type: 'string', enum: bookmarkIds },
            targetFolderId: { type: 'string', enum: [...folderIds, '__skip__'] },
            confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
            reason: { type: 'string' },
          },
          required: ['bookmarkId', 'targetFolderId', 'confidence', 'reason'],
          additionalProperties: false,
        },
      },
    },
    required: ['moves'],
    additionalProperties: false,
  };
}

// --- Prompt Builder Functions ---

/**
 * Build a compact indented folder summary with bookmark counts.
 * @param {Array} tree - Root children from bookmark tree
 * @param {Map} stats - Per-folder stats from bookmark-store
 * @returns {string}
 */
export function buildFolderSummary(tree, stats) {
  const lines = [];

  function walkFolders(nodes, depth) {
    for (const node of nodes) {
      if (!node.isFolder) continue;
      const s = stats.get(node.id);
      const count = s ? s.bookmarkCount : 0;
      const indent = '  '.repeat(depth);
      lines.push(`${indent}[${node.id}] ${node.title || '(untitled)'} (${count})`);
      if (node.children) walkFolders(node.children, depth + 1);
    }
  }

  walkFolders(tree, 0);
  return lines.join('\n');
}

/**
 * Build the Phase 1 taxonomy prompt using enriched folder data.
 * @param {Array} enrichedFolders - Array of enriched folder objects
 * @returns {string}
 */
export function buildTaxonomyPrompt(enrichedFolders) {
  const lines = enrichedFolders.map(f => {
    const parts = [`[${f.folderId}] ${f.folderPath} (${f.bookmarkCount})`];
    if (f.domains.length) parts.push(`domains: ${f.domains.join(', ')}`);
    if (f.siblings.length) parts.push(`siblings: ${f.siblings.join(', ')}`);
    if (f.tfidfKeywords.length) parts.push(`keywords: ${f.tfidfKeywords.join(', ')}`);
    if (f.exemplars.length) parts.push(`examples: ${f.exemplars.map(e => `"${e.title}" ${e.url}`).join(' | ')}`);
    return parts.join(' | ');
  }).join('\n');

  return `Analyze these bookmark folders. For each, describe what it contains and provide keywords.\n\n${lines}`;
}

/**
 * Format a batch of bookmarks for the classification prompt.
 * @param {Array} bookmarks - Array of { id, title, url }
 * @returns {string}
 */
export function formatBookmarkBatch(bookmarks) {
  return bookmarks.map(b => {
    let shortUrl = b.url;
    try {
      const u = new URL(b.url);
      shortUrl = u.hostname + (u.pathname !== '/' ? u.pathname : '');
      if (shortUrl.length > 60) shortUrl = shortUrl.slice(0, 57) + '...';
    } catch { /* keep original */ }
    return `[${b.id}] "${b.title || '(untitled)'}" ${shortUrl}`;
  }).join('\n');
}

/**
 * Build the Phase 1.5 cluster analysis prompt.
 * @param {Array} uncategorizedBookmarks - Uncategorized bookmarks to analyze
 * @param {object} taxonomy - Taxonomy from Phase 1
 * @param {Array<{id: string, title: string}>} rootFolders - Root bookmark bar containers
 * @returns {string}
 */
export function buildClusterPrompt(uncategorizedBookmarks, taxonomy, rootFolders) {
  const existingList = taxonomy.categories
    .map(c => `[${c.folderId}] ${c.folderPath}`)
    .join('\n');

  const rootList = rootFolders
    .map(f => `[${f.id}] ${f.title}`)
    .join('\n');

  const bookmarkList = formatBookmarkBatch(uncategorizedBookmarks);

  return `Analyze these uncategorized bookmarks and identify 2–6 thematic groups that would benefit from a new folder.

Existing folders (for reference — do NOT use these as parentFolderId):
${existingList}

Valid locations for new folders (use one of these IDs as parentFolderId):
${rootList}

Uncategorized bookmarks:
${bookmarkList}

For each cluster, suggest a short folder name, a description, keywords, and which root location to create it in (parentFolderId).
Only suggest clusters when a meaningful group of 2+ bookmarks shares a clear theme. Do not suggest clusters that duplicate an existing folder's purpose.`;
}

/**
 * Build the Phase 2 classification prompt.
 * @param {object} taxonomy - Parsed taxonomy result from Phase 1
 * @param {Array} bookmarkBatch - Bookmarks to classify
 * @returns {string}
 */
export function buildClassificationPrompt(taxonomy, bookmarkBatch) {
  const folderList = taxonomy.categories
    .map(c => `[${c.folderId}] ${c.folderPath}: ${c.description} (${c.keywords.join(', ')})`)
    .join('\n');

  const bookmarkList = formatBookmarkBatch(bookmarkBatch);

  return `Classify these bookmarks into the most appropriate folders.

Available folders:
${folderList}

Bookmarks to classify (format: [id] "title" url):
${bookmarkList}

For each bookmark:
- Choose the best existing folder (targetFolderId)
- Set confidence: "high" (obvious match), "medium" (reasonable), "low" (uncertain)
- Give a brief reason

Use targetFolderId="__skip__" if no folder is a good match.`;
}
