import std/[os, strutils, terminal, strformat]
import cligen
import ./config
import ./storage
import ./model
import ./runtime
import ./bootstrap
import ./organizer
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
    [cmdUndo, cmdName = "undo", doc = "Undo last batch of classifications"],
    [cmdModelList, cmdName = "model-list", doc = "List available models"],
    [cmdModelSet, cmdName = "model-set", doc = "Set default model variant",
      help = {"variant": "Model variant name"}],
    [cmdModelDownload, cmdName = "model-download", doc = "Download model without running organise"],
    [cmdStatus, cmdName = "status", doc = "Show runtime and model status"],
    [cmdDoctor, cmdName = "doctor", doc = "Run self-diagnostic checks"],
  )
