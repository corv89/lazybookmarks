# AGENTS.md — Lazybookmarks Development Guide

## Project Overview
- Chrome extension (AI-powered bookmark organizer using Gemini Nano) ported to standalone Nim CLI
- Target: Linux arm64, dev on macOS arm64
- Dependencies: cligen, db_connector, jsony (only 3)
- Build: `nimble release` (NOT `nimble build`)

## Build & Toolchain
- Nim 2.2.8 via Homebrew
- `nimble release` outputs to `build/lazybookmarks`
- Do NOT use `nimble build` — it ignores custom tasks
- `nim.cfg`: --opt:size, --mm:orc, NO -d:ssl
- `nimble release` auto-resolves dependencies

## LLM Backend
- Default: Ollama native `/api/chat` (constrained decoding via `format` param)
- OpenAI-compatible `/v1/chat/completions` fallback when `runtimeManaged=false` (LLM_URL set)
- `format` param = grammar-based constrained decoding (model physically cannot generate invalid tokens)
- `"options": {"think": false}` suppresses qwen3.5 thinking mode
- Model lineup: qwen3.5:0.8b, qwen3.5:2b (default), qwen3.5:4b, gemma4:e2b
- Model managed via `ollama pull`, not custom download code

## Architecture
- Config priority: CLI > env vars > config.toml > defaults
- `runtimeManaged` flag: true = Ollama (native endpoints), false = custom LLM_URL (OpenAI endpoints)
- Link checking: `curl` + `xargs -P` (Nim SSL broken with OpenSSL 3.6+)
- `__skip__` handling: bookmarks classified as `__skip__` remain `organised_at = NULL`

## 3-Phase Pipeline Internals

The organize command (`organizer.nim`) runs a 3-phase pipeline to classify bookmarks into folders.

### Phase 1: Taxonomy Analysis (`runTaxonomyPhase`)
- **Input:** All folders with their bookmarks, enriched with TF-IDF keywords, domain patterns, and exemplar bookmarks
- **Process:** Single LLM call asking the model to describe each folder and provide keywords
- **Schema:** `TaxonomySchemaJson` — array of `{folderId, folderPath, description, keywords[]}`
- **Caching:** Results keyed by a fingerprint of folder UUIDs + bookmark counts (`buildFingerprint`). Cache stored in `taxonomy_cache` table. Survives across runs unless folder structure changes.
- **Key helpers:** `computeTFIDF` (term frequency-inverse document frequency per folder), `extractDomainPatterns` (top domains per folder above 20% threshold), `sampleExemplars` (2 most recent bookmark titles/urls per folder)

### Phase 1.5: Cluster/Theme Grouping (`runClusterPhase`)
- **Input:** All unorganized bookmarks, existing taxonomy categories, root-level folders
- **Process:** Single LLM call to identify 2-6 thematic groups among unorganized bookmarks that deserve a new folder
- **Schema:** `buildClusterSchemaJson(rootFolderIds)` — array of `{name, description, keywords[], parentFolderId}`. The `parentFolderId` is constrained to root folder UUIDs via JSON enum.
- **Output:** `seq[ClusterSuggestion]` — these become synthetic folders prefixed with `__new_` (e.g., `__new_Hardware`) in the taxonomy for Phase 2

### Phase 2: Per-Bookmark Classification (`runClassificationPhase`)
- **Input:** Unorganized bookmarks (chunked into batches), full taxonomy (original + new cluster folders)
- **Process:** For each batch, calls `pruneTaxonomy` to reduce the folder list to the most relevant ~15 folders (based on keyword overlap with the batch's titles via TF-IDF), then asks the LLM to classify each bookmark
- **Schema:** `buildClassificationSchemaJson(folderIds, bookmarkIds)` — array of `{bookmarkId, targetFolderId, confidence, reason}`. Both `bookmarkId` and `targetFolderId` are constrained to exact IDs via JSON enum, plus `"__skip__"` as a valid target.
- **Concurrency:** Uses `classifyBatchAsync` with sliding window — up to `concurrency` (default 4) batches in flight simultaneously via `AsyncHttpClient`. Batch size auto-set by model size (5 for small, 10 for normal).
- **`pruneTaxonomy`:** Scores each taxonomy category by how many of its TF-IDF keywords appear in the batch's token set. Keeps top N (max 15, min 5). This prevents overwhelming small models with 30+ folder options.
- **Bookmarks classified as `__skip__`** are silently dropped (not applied). Low-confidence matches can be reviewed interactively or auto-skipped.

### Data Flow
1. `organizeBookmarks` loads all bookmarks, builds `folderBookmarks` table mapping folder UUID → bookmark entries
2. Phase 1 enriches folders with TF-IDF/domain/exemplar data, runs LLM, caches result
3. Phase 1.5 takes unorganized bookmarks + taxonomy + root folders, suggests new folders
4. Phase 2 merges new folders into taxonomy, chunks unorganized bookmarks, classifies each batch with pruned taxonomy
5. Results become `seq[Suggestion]` with `bookmarkId`, `targetFolderId`, `targetFolderPath`, `confidence`, `reason`, `isNewFolder`
6. Suggestions are applied via `applyClassification` (sets `category`, `confidence`, `reason`, `organised_at` on the bookmark row)

### Key Types
- `TaxonomyCategory`: folderId, folderPath, description, keywords
- `ClusterSuggestion`: name, description, keywords, parentFolderId
- `Classification`: bookmarkId, targetFolderId, confidence, reason
- `Suggestion`: bookmarkId, bookmarkTitle, bookmarkUrl, targetFolderId, targetFolderPath, confidence, reason, isNewFolder

## Nim Language Pitfalls (The Hard-Won Lessons)

### Syntax
- `.[^1]` is Python, not Nim — use `seq[seq.len - 1]`
- `mapIt` cannot have multi-line blocks — use explicit `for` loops
- `=>` lambda syntax doesn't exist in Nim
- Anonymous tuple fields can't be accessed by name (`.score`) — use `[0]`, `[1]`
- `findIt` on seqs returns `int` (index), not the element — use `seq[index]`
- `{}` set literals only support values 0..255 — HTTP codes 302/404/410 must use `==` chains
- `re.match` requires full-string match — use `re.find` for substring matching
- `&"..."` format strings require `strformat` import
- Variable names can't conflict with keywords (e.g., `file` parameter)

### Standard Library
- `std/terminal` has `hideCursor`/`showCursor` templates that conflict with custom procs
- `postContent` doesn't take a `headers` param — set `client.headers` before calling
- `HttpClient` has no `onProgress` field
- `filterIt`/`mapIt` are in `std/sequtils`, NOT `std/sugar` in Nim 2.2.8
- `split()` requires `strutils` import
- `parseFloat` requires `strutils` import
- `sort()` requires `std/algorithm` import
- `sum()` doesn't exist as a standalone proc — use manual loop with `.inc`
- `sleep` → `os.sleep` or `execShellCmd`
- `execShellCmd` is in `std/os`, not `std/osproc`
- `/` operator is for filesystem paths, not URL concatenation — use `&`
- `reversed()` doesn't exist — use manual reverse loop with index
- `rfind` doesn't exist — use manual loop or reverse approach
- `chunk` doesn't exist — implement manually
- `formatFloat` uses `precision` not `ffDecimal` named param

### Async
- `AsyncHttpClient` is inside `std/httpclient`, no built-in timeout
- `withTimeout(fut, ms)` returns `Future[bool]` — true if completed
- `one()` doesn't exist — use polling with `sleepAsync` + `.finished`
- Async macro can't capture `var` parameters — use return values
- `pump()` closures capturing locals from enclosing procs violate borrow checker — inline
- `std/channels` doesn't exist in 2.2.8; `threadpool` is deprecated
- `waitFor()` requires `std/asyncdispatch`

### JSON & Data
- `HttpHeaders` doesn't have 3-arg `get(key, default)` — use `hasKey` + `[]`
- `HttpCode` is `range[0..255]` — can't use in `{}`
- `toHex` from `nimcrypto/utils` returns uppercase — `toLowerAscii()` for comparisons

### Build System
- `nimble build` always runs its own default build via `bin` field — custom `build` tasks are ignored
- `self.exec` is old nimble syntax — use just `exec`
- `--out:path` doesn't work in `nim.cfg` — only `--outdir:dir`
- Circular imports cause "undeclared identifier" — restructure to avoid cycles
- Forward declarations needed for procs called before their definition
- Inline `if` in string concatenation within proc call arguments doesn't work — extract to `let` binding

### SSL
- Nim 2.2.8 SSL bindings are incompatible with OpenSSL 3.6+
- Do NOT add `-d:ssl` — use `curl` via `execShellCmd` for HTTPS

## Code Conventions
- No comments unless asked
- Imports grouped: std/*, then local ./* modules
- Procs use `*` export marker for public API
- CLI subcommands use `cmdXxx` naming, flat names in dispatchMulti (e.g., `model-list`)

## Testing
- Manual e2e testing with real bookmark data (692 bookmarks)
- `./build/lazybookmarks <command> --verbose` for debug output
- Smoke test: `./build/lazybookmarks status` / `./build/lazybookmarks --help`

## Ollama API Reference (Native Endpoints)
- Chat: `POST /api/chat` with `format` for structured output, `stream: false`
- Models: `GET /api/tags`
- Health: `GET /api/tags` (200 = running)
- Pull: `ollama pull <model>:<tag>` (CLI, not API)
- Response: `{"message": {"content": "..."}}` (not OpenAI's `choices[0].message.content`)
