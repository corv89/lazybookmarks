import { loadBookmarks, loadCollapsed, saveCollapsed, pruneCollapsed, getRootFolderIds } from '../lib/bookmark-store.js';
import { initTree } from '../lib/tree-view.js';
import { initSearch } from '../lib/search-view.js';
import { buildIndex, searchBookmarks } from '../lib/search.js';
import { checkAvailability } from '../ai/language-model.js';
import { organizeBookmarks } from '../ai/ai-organizer.js';
import { initSuggestionsUI } from '../ai/suggestions-ui.js';
import { saveSnapshot, applyMoves, undoMoves } from '../ai/undo.js';

const treeContainer = document.getElementById('tree-container');
const searchResults = document.getElementById('search-results');
const searchInput = document.getElementById('search-input');
const statsBar = document.getElementById('stats-bar');
const loadingOverlay = document.getElementById('loading-overlay');
const organizeBtn = document.getElementById('organize-btn');
const aiProgress = document.getElementById('ai-progress');
const aiProgressLabel = document.getElementById('ai-progress-label');
const aiProgressBar = document.getElementById('ai-progress-bar');

const templates = {
  folderTpl: document.getElementById('folder-tpl'),
  bookmarkTpl: document.getElementById('bookmark-tpl'),
};

const tree = initTree(treeContainer, templates, {
  onToggle: (collapsed) => saveCollapsed(collapsed),
});

const suggestionsUI = initSuggestionsUI(treeContainer, {
  expandPathTo: (nodeId) => tree.expandPathTo(nodeId),
  onApply: async (accepted) => {
    await saveSnapshot(accepted.filter(s => s.type === 'move'));
    await applyMoves(accepted);
    suggestionsUI.clearAll();
    suggestionsUI.showUndoButton();
    await load();
  },
  onUndo: async () => {
    const success = await undoMoves();
    suggestionsUI.clearAll();
    aiProgress.hidden = true;
    if (success) await load();
  },
  onCancel: () => {
    aiProgress.hidden = true;
  },
});

initSearch(searchInput, searchResults, {
  onSearch(query) {
    treeContainer.hidden = true;
    searchResults.hidden = false;
    return searchBookmarks(query);
  },
  onClear() {
    searchResults.hidden = true;
    treeContainer.hidden = false;
  },
});

document.getElementById('expand-all').addEventListener('click', () => tree.expandAll());
document.getElementById('collapse-all').addEventListener('click', () => tree.collapseAll());

// --- AI Organize ---
let abortController = null;

organizeBtn.addEventListener('click', async () => {
  if (abortController) {
    abortController.abort();
    abortController = null;
    organizeBtn.textContent = 'Organize';
    aiProgress.hidden = true;
    return;
  }

  abortController = new AbortController();
  organizeBtn.textContent = 'Cancel';
  suggestionsUI.clearAll();
  aiProgress.hidden = false;
  aiProgressBar.value = 0;
  aiProgressLabel.textContent = 'Starting AI analysis...';

  try {
    const [data, rootFolderIds] = await Promise.all([
      loadBookmarks(),
      getRootFolderIds(),
    ]);

    const { lb_pending_queue: pendingQueue = [] } = await chrome.storage.local.get('lb_pending_queue');

    await organizeBookmarks(data, pendingQueue, {
      signal: abortController.signal,
      onDownloadProgress: (() => {
        let lastLoaded = -1;
        let stallTimer = null;
        return (e) => {
          const pct = Math.round(e.loaded * 100);
          aiProgressLabel.textContent = `Downloading AI model... ${pct}%`;
          aiProgressBar.max = 100;
          aiProgressBar.value = pct;

          if (e.loaded !== lastLoaded) {
            lastLoaded = e.loaded;
            clearTimeout(stallTimer);
            if (pct < 100) {
              stallTimer = setTimeout(() => {
                aiProgressLabel.textContent =
                  `Download stalled at ${pct}% — check chrome://on-device-internals for errors (GPU blocked?)`;
              }, 30_000);
            }
          }

          // After download completes, model still needs extraction/loading
          if (e.loaded === 1) {
            aiProgressBar.removeAttribute('value'); // indeterminate
            aiProgressLabel.textContent = 'Loading AI model into memory...';
          }
        };
      })(),
      onPhaseChange(phase) {
        if (phase === 'download') {
          aiProgressLabel.textContent = 'Waiting for AI model download...';
          aiProgressBar.removeAttribute('value'); // indeterminate
        } else if (phase === 'taxonomy') {
          aiProgressLabel.textContent = 'Analyzing folder structure...';
          aiProgressBar.removeAttribute('value'); // indeterminate
        } else if (phase === 'cluster') {
          aiProgressLabel.textContent = 'Finding thematic clusters...';
          aiProgressBar.removeAttribute('value'); // indeterminate
        } else if (phase === 'classify') {
          aiProgressLabel.textContent = 'Classifying bookmarks...';
        } else if (phase === 'done') {
          aiProgress.hidden = true;
          if (suggestionsUI.getPending() === 0 && suggestionsUI.getAccepted().length === 0) {
            aiProgressLabel.textContent = 'All bookmarks well-organized!';
            aiProgress.hidden = false;
            aiProgressBar.value = 100;
          }
        }
      },
      onProgress(current, total) {
        aiProgressBar.max = total;
        aiProgressBar.value = current;
        aiProgressLabel.textContent = `Classifying bookmarks... ${current}/${total}`;
      },
      onSuggestion(suggestion) {
        suggestionsUI.addSuggestion(suggestion);
      },
      onError(err) {
        console.error('[LazyBookmarks] AI error:', err);
        aiProgressLabel.textContent = `Error: ${err.message}`;
      },
      onQuotaWarning(quota) {
        console.warn('[LazyBookmarks] AI quota low:', quota);
      },
    }, rootFolderIds);
  } catch (err) {
    if (err.name !== 'AbortError') {
      console.error('[LazyBookmarks] organize failed:', err);
      aiProgressLabel.textContent = `Error: ${err.message}`;
    }
  } finally {
    abortController = null;
    organizeBtn.textContent = 'Organize';
    refreshAvailability();
  }
});

// --- Enable/disable Organize button based on AI availability ---
let availabilityPollTimer = null;

function refreshAvailability() {
  checkAvailability().then(status => {
    if (abortController) return; // already running, don't touch button state
    const usable = (status === 'available' || status === 'downloadable' || status === 'downloading');
    organizeBtn.disabled = !usable;
    if (organizeBtn.disabled) {
      organizeBtn.title = `AI unavailable (${status})`;
    } else if (status === 'downloading') {
      organizeBtn.title = 'AI model is downloading — click to organize after download';
      organizeBtn.textContent = 'Organize (downloading…)';
      // Poll until the download finishes
      clearInterval(availabilityPollTimer);
      availabilityPollTimer = setInterval(() => refreshAvailability(), 3000);
    } else {
      organizeBtn.title = 'AI-organize uncategorized bookmarks';
      organizeBtn.textContent = 'Organize';
      clearInterval(availabilityPollTimer);
      availabilityPollTimer = null;
    }
  });
}
refreshAvailability();

// --- Bookmark loading ---
let loading = false;

async function load() {
  if (loading) return;
  loading = true;
  loadingOverlay.hidden = false;

  try {
    // Clear any active suggestions — tree rebuild detaches their DOM elements
    suggestionsUI.clearAll();

    const [data, collapsed] = await Promise.all([loadBookmarks(), loadCollapsed()]);
    pruneCollapsed(collapsed, data.stats);

    tree.render(data.tree, data.stats, collapsed, data.nodeById);
    await buildIndex(data.flat);

    statsBar.textContent = `${data.flat.length} bookmarks in ${data.stats.size} folders`;
  } finally {
    loading = false;
    loadingOverlay.hidden = true;
  }
}

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'bookmarks-changed') load();
});

load();
