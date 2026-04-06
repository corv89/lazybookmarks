import std/[os, strutils, terminal, strformat, sequtils, algorithm]
import cligen
import ./config
import ./storage
import ./model
import ./runtime
import ./bootstrap
import ./organizer
import ./linkchecker
import ./ui

proc cmdImport(file: string, format = "auto", dryRun = false) =
  if not fileExists(file):
    errorMsg &"File not found: {file}"
    quit(1)

  let cfg = loadConfig()
  let content = readFile(file)

  let detectedFormat = if format == "auto": detectFormat(content, file) else: format

  if dryRun:
    let parsed = parseImport(content, detectedFormat)
    infoMsg &"Would import {parsed.len} bookmarks (format: {detectedFormat})"
    for (url, title, folder) in parsed[0 .. min(9, parsed.high)]:
      echo &"  [{folder}] {title} - {url[0..min(79, url.high)]}"
    if parsed.len > 10:
      dimMsg &"... and {parsed.len - 10} more"
    return

  let count = importBookmarks(cfg, content, detectedFormat, extractFilename(file))
  infoMsg &"Imported {count} bookmarks from {file} (format: {detectedFormat})"

proc cmdOrganise(model = "", autoAcceptHigh = false, autoAcceptAll = false,
                  limit = 0, batchSize = 0, concurrency = 0, verbose = false) =
  let overrides = Config(modelVariant: model, batchSize: batchSize,
                         concurrency: concurrency, verbose: verbose,
                         autoAcceptHigh: autoAcceptHigh)
  var cfg = loadConfig(overrides)
  let registry = loadModelRegistry()

  ensureReady(cfg, registry)
  discard cfg.organizeBookmarks(autoAcceptAll = autoAcceptAll, limit = limit)

proc cmdList(category = "", unorganised = false) =
  let cfg = loadConfig()
  var bookmarks: seq[BookmarkEntry]

  if unorganised:
    bookmarks = getUnorganisedBookmarks(cfg)
  else:
    bookmarks = listBookmarks(cfg, category)

  if bookmarks.len == 0:
    dimMsg "No bookmarks found."
    return

  for b in bookmarks:
    let title = if b.title.len > 0: b.title else: "(untitled)"
    var cat = "-"
    if b.category.len > 0: cat = b.category
    elif b.rawFolder.len > 0: cat = b.rawFolder
    echo &"  {title:<50} {cat}"
  echo &"\n  {bookmarks.len} bookmarks"

proc cmdSearch(query: string) =
  let cfg = loadConfig()
  let bookmarks = searchBookmarks(cfg, query)

  if bookmarks.len == 0:
    dimMsg &"No results for \"{query}\""
    return

  for b in bookmarks:
    let title = if b.title.len > 0: b.title else: "(untitled)"
    echo &"  {title:<50} {b.url[0..min(79, b.url.high)]}"
  echo &"\n  {bookmarks.len} results for \"{query}\""

proc cmdUndo =
  let cfg = loadConfig()
  let count = cfg.undoLastBatch()
  if count > 0:
    infoMsg &"Undid {count} bookmark classifications"
  else:
    dimMsg "Nothing to undo"

proc cmdModelList =
  let cfg = loadConfig()
  let registry = loadModelRegistry()
  cfg.listModels(registry)

proc cmdModelSet(variant: string) =
  let cfgDir = defaultConfigDir()
  createDir(cfgDir)
  let configPath = cfgDir / "config.toml"
  var content = ""
  if fileExists(configPath):
    content = readFile(configPath)
  var lines = content.splitLines()
  var replaced = false
  var newLines: seq[string] = @[]
  for line in lines:
    if line.strip().startsWith("modelVariant"):
      newLines.add(&"modelVariant = \"{variant}\"")
      replaced = true
    else:
      newLines.add(line)
  if not replaced:
    newLines.add(&"modelVariant = \"{variant}\"")
  writeFile(configPath, newLines.join("\n") & "\n")
  infoMsg &"Default model set to {variant}"

proc cmdModelDownload =
  let cfg = loadConfig()
  let registry = loadModelRegistry()
  cfg.ensureModel(registry)

proc cmdStatus =
  let cfg = loadConfig()
  let registry = loadModelRegistry()

  echo ""
  styledWriteLine(stdout, styleBright, "  Endpoint:   ", resetStyle, cfg.llmUrl)
  styledWriteLine(stdout, styleBright, "  Model:      ", resetStyle, cfg.modelVariant)

  let modelReady = isModelReady(cfg, registry)
  styledWriteLine(stdout, styleBright, "  Model:      ", resetStyle, if modelReady: "[ready]" else: "[not pulled]")

  if cfg.runtimeManaged:
    let running = isRuntimeRunning(cfg)
    styledWriteLine(stdout, styleBright, "  Ollama:     ", resetStyle, if running: "[running]" else: "[not running]")

  styledWriteLine(stdout, styleBright, "  Data dir:   ", resetStyle, cfg.dataDir)
  echo ""

proc cmdDoctor =
  echo ""
  let cfg = loadConfig()
  var issues = 0

  let dbPath = cfg.dbPath()
  if fileExists(dbPath):
    infoMsg &"Database: {dbPath}"
  else:
    warnMsg "Database not found (will be created on first import)"
    issues.inc

  let ollamaBin = findOllamaBin()
  if ollamaBin.len > 0:
    infoMsg &"Ollama: {ollamaBin}"
  elif not cfg.runtimeManaged:
    dimMsg "Runtime: using external endpoint"
  else:
    warnMsg "Ollama not found in PATH"
    when defined(macosx):
      stdout.styledWriteLine(styleDim, "  Install: brew install ollama", resetStyle)
    elif defined(linux):
      stdout.styledWriteLine(styleDim, "  Install: curl -fsSL https://ollama.com/install.sh | sh", resetStyle)
    issues.inc

  let registry = loadModelRegistry()
  if isModelReady(cfg, registry):
    infoMsg &"Model: {cfg.modelVariant} ready"
  elif not cfg.runtimeManaged:
    dimMsg "Model: using external endpoint"
  else:
    warnMsg &"Model not pulled: {cfg.modelVariant}"

  let running = isRuntimeRunning(cfg)
  if running:
    infoMsg "Ollama: running"
  elif not cfg.runtimeManaged:
    dimMsg "Runtime: using external endpoint"
  else:
    warnMsg "Ollama not running"
    when defined(macosx):
      stdout.styledWriteLine(styleDim, "  Start: open -a Ollama", resetStyle)
    elif defined(linux):
      stdout.styledWriteLine(styleDim, "  Start: ollama serve &", resetStyle)
    issues.inc

  echo ""
  if issues == 0:
    infoMsg "All checks passed"
  else:
    warnMsg &"{issues} issue(s) found"

proc cmdDedup(interactive = true, autoRemove = false) =
  let cfg = loadConfig()
  let groups = findDuplicates(cfg)

  if groups.len == 0:
    infoMsg "No duplicate bookmarks found."
    return

  var totalDupes = 0
  for g in groups:
    totalDupes.inc g.dupes.len
  dimMsg &"Found {groups.len} duplicate group(s) ({totalDupes} total duplicates)"
  echo ""

  var totalRemoved = 0

  if interactive:
    for i, g in groups:
      let remove = reviewDuplicateGroup(i + 1, groups.len, g)
      if remove:
        let ids = g.dupes.mapIt(it.id)
        let removed = cfg.removeDuplicates(ids)
        totalRemoved.inc removed
        if removed > 0:
          infoMsg &"Removed {removed} duplicate(s)"
      else:
        dimMsg "Skipped"
  else:
    if autoRemove:
      for g in groups:
        let ids = g.dupes.mapIt(it.id)
        let removed = cfg.removeDuplicates(ids)
        totalRemoved.inc removed
      infoMsg &"Removed {totalRemoved} duplicate(s) across {groups.len} group(s)"
    else:
      for i, g in groups:
        stdout.styledWriteLine(styleBright, &"  Group {i+1}/{groups.len} ", resetStyle, styleDim, &"({g.reason})", resetStyle)
        let title = if g.keep.title.len > 0: g.keep.title else: "(untitled)"
        stdout.styledWriteLine("    Keep: ", fgGreen, title, resetStyle, styleDim, &"  [{g.keep.url[0..min(79, g.keep.url.high)]}]", resetStyle)
        for d in g.dupes:
          let dt = if d.title.len > 0: d.title else: "(untitled)"
          stdout.styledWriteLine(styleDim, "    - ", resetStyle, dt, styleDim, &"  [{d.url[0..min(79, d.url.high)]}]", resetStyle)
      echo ""
      dimMsg &"Run with --auto-remove to delete duplicates, or --interactive to review each group"

proc cmdCheckLinks(concurrency = 8, deadOnly = false, deleteDead = false,
                   unorganised = false) =
  let cfg = loadConfig()

  var bookmarks: seq[BookmarkEntry]
  if unorganised:
    bookmarks = getUnorganisedBookmarks(cfg)
  else:
    bookmarks = getAllBookmarks(cfg)

  if bookmarks.len == 0:
    dimMsg "No bookmarks to check."
    return

  infoMsg &"Checking {bookmarks.len} bookmark(s) (concurrency: {concurrency})..."
  echo ""

  var results: seq[LinkResult]

  proc onProgress(current, total: int) =
    showProgressBar(current, total, "  Checking")

  results = checkAllLinks(cfg, bookmarks, concurrency, onProgress)

  stdout.write "\n"

  var filtered: seq[LinkResult]
  if deadOnly:
    filtered = results.filterIt(it.status == lsDead)
  else:
    filtered = results

  if filtered.len > 0 and not deadOnly:
    filtered.sort(proc(a, b: LinkResult): int =
      result = ord(a.status) - ord(b.status))

  for r in filtered:
    showLinkResult(r)

  showLinkSummary(results)

  if deleteDead:
    let deadIds = results.filterIt(it.status == lsDead).mapIt(it.bookmark.id)
    if deadIds.len > 0:
      let removed = cfg.deleteBookmarks(deadIds)
      infoMsg &"Deleted {removed} dead bookmark(s)"

proc cmdExport(output = "", category = "") =
  let cfg = loadConfig()
  let html = exportBookmarksHtml(cfg, category)
  if html.len == 0:
    dimMsg "No bookmarks to export."
    return
  if output.len > 0:
    writeFile(output, html)
    infoMsg &"Exported {getBookmarksForExport(cfg, category).len} bookmarks to {output}"
  else:
    stdout.write(html)

when isMainModule:
  dispatchMulti(
    [cmdImport, cmdName = "import", doc = "Import bookmarks from a file",
      help = {"file": "Path to bookmark file", "format": "Format: auto|html|json|urllist", "dry-run": "Parse only, no database write"}],
    [cmdOrganise, cmdName = "organise", doc = "AI-organize unorganized bookmarks",
      help = {"model": "Override model variant", "auto-accept-high": "Skip review for high confidence",
              "auto-accept-all": "Accept all suggestions", "limit": "Max bookmarks to process",
              "batch-size": "Bookmarks per LLM request (0=auto)", "concurrency": "Parallel LLM requests (0=auto)",
              "verbose": "Show debug output"}],
    [cmdList, cmdName = "list", doc = "List bookmarks",
      help = {"category": "Filter by folder path", "unorganised": "Show only unorganized"}],
    [cmdSearch, cmdName = "search", doc = "Search bookmarks",
      help = {"query": "Search term"}],
    [cmdExport, cmdName = "export", doc = "Export bookmarks to Netscape HTML",
      help = {"output": "Write to file instead of stdout", "category": "Filter by category"}],
    [cmdUndo, cmdName = "undo", doc = "Undo last batch of classifications"],
    [cmdModelList, cmdName = "model-list", doc = "List available models"],
    [cmdModelSet, cmdName = "model-set", doc = "Set default model variant",
      help = {"variant": "Model variant name"}],
    [cmdModelDownload, cmdName = "model-download", doc = "Download model without running organise"],
    [cmdStatus, cmdName = "status", doc = "Show runtime and model status"],
    [cmdDoctor, cmdName = "doctor", doc = "Run self-diagnostic checks"],
    [cmdDedup, cmdName = "dedup", doc = "Find and remove duplicate bookmarks",
      help = {"interactive": "Review each duplicate group", "auto-remove": "Remove all duplicates without prompting"}],
    [cmdCheckLinks, cmdName = "check-links", doc = "Check bookmarks for dead links",
      help = {"concurrency": "Parallel requests", "dead-only": "Show only dead links",
              "delete-dead": "Delete dead bookmarks", "unorganised": "Only check unorganized bookmarks"}],
  )
