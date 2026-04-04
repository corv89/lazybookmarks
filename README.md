# LazyBookmarks

LazyBookmarks is a Chrome extension that uses Google's in-browser Gemini Nano model to automatically organize your bookmarks. It's a testbed and proof-of-concept for experimenting with Chrome's [Prompt API](https://developer.chrome.com/docs/ai/prompt-api) — the built-in, on-device language model that runs entirely in your browser with no cloud calls. Bookmark things lazily without worrying about folders, then click "Organize" and let the AI classify everything into your existing folder structure.

> **This is experimental software.** It modifies your bookmarks by moving them between folders. Back up your bookmarks before using it.

## Back Up Your Bookmarks

Before installing, export your bookmarks:

1. Open Chrome and go to `chrome://bookmarks`
2. Click the three-dot menu (top-right of the Bookmark Manager)
3. Select **Export bookmarks**
4. Save the HTML file somewhere safe

You can restore from this file at any time using **Import bookmarks** from the same menu.

## Installation

### Requirements

**Browser:** Google Chrome only. The Prompt API is a Chrome-specific feature — Chromium, Edge, Brave, and other variants are not supported.

**Chrome version:** 138 or later (origin trial). The API is available on `localhost` with feature flags enabled.

**Hardware** (from [official Chrome docs](https://developer.chrome.com/docs/ai/prompt-api)):

| Requirement | Minimum |
|---|---|
| OS | Windows 10/11, macOS 13+, Linux, or ChromeOS (Chromebook Plus) |
| Storage | 22 GB free on the volume containing your Chrome profile |
| GPU | More than 4 GB VRAM |
| CPU (if no GPU) | 16 GB RAM and 4+ cores |
| Network | Unmetered connection (initial model download only) |

### Step 1: Enable Chrome Flags

Open each of the following URLs in Chrome and set them to **Enabled**, then click **Relaunch**:

1. `chrome://flags/#optimization-guide-on-device-model`
2. `chrome://flags/#prompt-api-for-gemini-nano-multimodal-input`

### Step 2: Verify the Model

Go to `chrome://on-device-internals` and confirm that Gemini Nano is listed and available. If it shows as downloading, wait for it to finish. The model is roughly 2 GB.

If the model doesn't appear, check that your hardware meets the requirements above. See [Chrome's troubleshooting guide](https://developer.chrome.com/docs/ai/get-started#troubleshoot_localhost) for more help.

### Step 3: Clone and Load the Extension

```bash
git clone <repo-url>
```

1. Open `chrome://extensions`
2. Enable **Developer mode** (toggle in the top-right)
3. Click **Load unpacked**
4. Select the cloned `lazybookmarks` directory

### Step 4: Use It

1. Pin the LazyBookmarks extension in your toolbar
2. Click the icon to open the bookmark viewer
3. Click **Organize** to run AI classification
4. Review the suggestions — accept, reject, or apply all

The AI analyzes your existing folder structure, groups uncategorized bookmarks by theme, and suggests where each one should go. All processing happens locally in your browser.

## Project Overview

```
lazybookmarks/
├── manifest.json        Extension manifest (Manifest V3)
├── background.js        Service worker — detects new bookmarks, manages the pending queue
├── popup/               Extension popup — opens the viewer tab
├── viewer/              Main bookmark viewer UI — tree view, search, organize button
├── ai/                  AI classification engine — Prompt API, structured prompts, suggestions
├── lib/                 Shared utilities — bookmark store, tree rendering, search
├── debug/               Live AI debug log viewer — prompts, responses, streaming events
├── icons/               Extension icons (16, 48, 128px)
├── vendor/              Third-party libraries (Orama full-text search)
└── docs/                Cached Chrome API documentation for LLM-assisted development
```

## Detailed File Reference

### `ai/` — AI Classification Engine

The core of the extension. Orchestrates a multi-phase pipeline: build a taxonomy of your existing folders, cluster uncategorized bookmarks by theme, then classify each one into the best-fit folder.

| File | Purpose |
|---|---|
| `ai-organizer.js` | Orchestrates the full classification pipeline (taxonomy, clustering, classification) |
| `language-model.js` | Wrapper around Chrome's `LanguageModel` (Prompt API) — session creation, streaming, quota management |
| `prompts.js` | All prompt templates and JSON schemas used for structured output |
| `suggestions-ui.js` | UI for reviewing AI suggestions — accept, reject, or apply all moves |
| `taxonomy-cache.js` | Caches the folder taxonomy so it can be reused across classification batches |
| `undo.js` | Snapshot-based undo/redo for bookmark moves |
| `debug-log.js` | Structured event logging for the debug viewer |
| `debug-constants.js` | Debug configuration flags |

### `lib/` — Shared Utilities

| File | Purpose |
|---|---|
| `bookmark-store.js` | `chrome.bookmarks` API wrapper — loads the full tree, normalizes it into flat and hierarchical formats |
| `tree-view.js` | DOM tree renderer with expand/collapse, drag targets, and folder highlighting |
| `search.js` | Full-text bookmark search powered by Orama |
| `search-view.js` | Connects the search input to the search engine and renders results |
| `favicon.js` | Fetches favicons for bookmark URLs |

### `viewer/` — Main UI

| File | Purpose |
|---|---|
| `viewer.html` | Main page with HTML templates for folders and bookmarks |
| `viewer.js` | Orchestrator — wires together the tree, search, AI organizer, and suggestions UI |
| `viewer.css` | Styling with dark/light theme support |

### `debug/` — Debug Viewer

A standalone page (`debug/debug.html`) that displays a live stream of AI classification events — every prompt sent to Gemini Nano, every streamed response token, parse results, and errors. Open it from the extension's debug page or navigate to it directly.

### `docs/` — Cached Documentation

Pre-fetched documentation from `developer.chrome.com`, `docs.orama.com`, and other sources. These are used for LLM-assisted development — providing context to AI coding tools without needing live web access. Not required at runtime.
