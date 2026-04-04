// Broadcast bookmark changes so the viewer can reload.
// Queues uncategorized bookmarks for AI organization.

import { getRootFolderIds } from './lib/bookmark-store.js';

// --- Bookmark import guard ---
// Docs: "expensive observers should ignore onCreated updates during import"
let importing = false;
chrome.bookmarks.onImportBegan.addListener(() => { importing = true; });
chrome.bookmarks.onImportEnded.addListener(() => { importing = false; });

// --- Queue writes serialized through a promise chain ---
// Prevents read-modify-write races when multiple onCreated events fire rapidly.
let queueChain = Promise.resolve();

function enqueue(entry) {
  queueChain = queueChain.then(async () => {
    const { lb_pending_queue: queue = [] } = await chrome.storage.local.get('lb_pending_queue');
    queue.push(entry);
    await chrome.storage.local.set({ lb_pending_queue: queue });
    updateBadge(queue.length);
  }).catch(err => console.error('[LazyBookmarks] queue write failed:', err));
}

chrome.bookmarks.onCreated.addListener(async (id, bookmark) => {
  if (importing) return;
  const roots = await getRootFolderIds();
  // Only queue bookmarks (not folders) in root containers
  if (!bookmark.url || !roots.has(bookmark.parentId)) return;
  enqueue({ id, title: bookmark.title, url: bookmark.url, parentId: bookmark.parentId });
});

// --- Badge ---
// Chrome badges support max 4 characters. Use compact notation.
function badgeText(n) {
  if (n === 0) return '';
  if (n < 1000) return String(n);
  if (n < 10000) return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k';
  return Math.floor(n / 1000) + 'k';
}

function updateBadge(count) {
  chrome.action.setBadgeText({ text: badgeText(count) });
  if (count > 0) chrome.action.setBadgeBackgroundColor({ color: '#6366f1' });
}

// Clear badge when queue is emptied (e.g., after viewer processes it)
chrome.storage.onChanged.addListener((changes, areaName) => {
  if (areaName !== 'local') return;
  if (changes.lb_pending_queue) {
    updateBadge((changes.lb_pending_queue.newValue || []).length);
  }
});

// --- Suppress reload broadcasts during AI-driven batch moves ---
// Uses an in-memory reference counter. The viewer sends
// 'suppress-notifications' / 'unsuppress-notifications' messages and awaits
// the sendResponse acknowledgment before calling move().
let suppressDepth = 0;

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'suppress-notifications') {
    suppressDepth++;
    sendResponse({ ok: true });
    return false;
  }
  if (msg.type === 'unsuppress-notifications') {
    suppressDepth = Math.max(0, suppressDepth - 1);
    sendResponse({ ok: true });
    return false;
  }
});

// --- Bookmark change notifications ---
function notify() {
  if (importing) return;
  if (suppressDepth > 0) return;
  chrome.runtime.sendMessage({ type: 'bookmarks-changed' }).catch(() => {});
}

chrome.bookmarks.onCreated.addListener(notify);
chrome.bookmarks.onRemoved.addListener(notify);
chrome.bookmarks.onMoved.addListener(notify);
chrome.bookmarks.onChanged.addListener(notify);
chrome.bookmarks.onChildrenReordered.addListener(notify);
