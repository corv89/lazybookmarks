/**
 * Full-text search over bookmarks using Orama.
 */
import { create, insertMultiple, search } from '../vendor/orama.js';

let db = null;

/** Build the search index from a flat list of bookmarks. */
export async function buildIndex(bookmarks) {
  db = create({
    schema: {
      title: 'string',
      url: 'string',
      path: 'string',
    },
  });

  if (bookmarks.length === 0) return;

  const docs = bookmarks.map((b) => ({
    id: b.id,
    title: b.title,
    url: b.url,
    path: b.path,
  }));

  await insertMultiple(db, docs, 500);
}

/**
 * Search bookmarks by query string.
 * Returns array of { id, score, title, url, path }.
 */
export function searchBookmarks(query) {
  if (!db || !query.trim()) return [];

  const results = search(db, {
    term: query,
    limit: 50,
  });

  return results.hits.map((hit) => ({
    id: hit.id,
    score: hit.score,
    title: hit.document.title,
    url: hit.document.url,
    path: hit.document.path,
  }));
}
