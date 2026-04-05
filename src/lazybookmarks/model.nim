import std/[os, strutils, strformat, streams, terminal, osproc]
import nimcrypto/sha2
import nimcrypto/utils
import jsony
import ./config

type
  ModelEntry* = object
    name*:        string
    ollamaModel*: string
    ollamaTag*:   string
    digest*:      string
    sizeBytes*:   int64

  ModelRegistry* = object
    entries*: seq[ModelEntry]

const modelRegistryJson = staticRead("../../assets/models.json")

const OllamaRegistry* = "https://registry.ollama.ai/v2/library"

proc loadModelRegistry*: ModelRegistry =
  return modelRegistryJson.fromJson(ModelRegistry)

proc findModel*(registry: ModelRegistry, variant: string): ModelEntry =
  for e in registry.entries:
    if e.name == variant:
      return e
  raise newException(ValueError, &"Unknown model variant: {variant}")

proc modelFilename*(entry: ModelEntry): string =
  entry.ollamaModel & "-" & entry.ollamaTag

proc resolveDownloadUrl*(entry: ModelEntry): string =
  let digest = entry.digest.replace("sha256:", "")
  return OllamaRegistry & "/" & entry.ollamaModel & "/blobs/sha256:" & digest

proc sha256File*(path: string): string =
  var ctx: sha256
  ctx.init()
  let file = newFileStream(path, fmRead)
  if file == nil:
    raise newException(IOError, &"Cannot open file: {path}")
  defer: file.close()
  var buf = newString(8192)
  while true:
    let n = file.readData(buf[0].addr, buf.len)
    if n == 0: break
    ctx.update(cast[ptr byte](buf[0].addr), uint(n))
  var digest: array[32, byte]
  ctx.finish(digest)
  return toLowerAscii(digest.toHex())

proc formatBytes*(bytes: int64): string =
  if bytes < 1024: return $bytes & " B"
  if bytes < 1024 * 1024: return $(bytes div 1024) & " KB"
  if bytes < 1024 * 1024 * 1024: return &"{float(bytes) / (1024*1024):.1f} MB"
  return &"{float(bytes) / (1024*1024*1024):.2f} GB"

proc ensureModel*(cfg: Config, registry: ModelRegistry) =
  let entry = findModel(registry, cfg.modelVariant)
  let modelsDir = cfg.modelsDir()
  let filename = modelFilename(entry)
  let modelPath = modelsDir / filename
  let hashPath = modelPath & ".sha256"

  ensureDir(modelsDir)

  if fileExists(modelPath):
    if fileExists(hashPath):
      let storedHash = readFile(hashPath).strip()
      if storedHash == entry.digest:
        return
    let currentHash = sha256File(modelPath)
    if currentHash == entry.digest:
      writeFile(hashPath, entry.digest)
      return
    stdout.styledWriteLine(styleBright, fgYellow, "  ! ", fgDefault, resetStyle, "Model file corrupted, re-downloading...")
    removeFile(modelPath)
    if fileExists(hashPath):
      removeFile(hashPath)

  let partPath = modelPath & ".part"
  let resume = fileExists(partPath)

  if resume:
    stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle,
      "Resuming " & entry.name & " (" & formatBytes(entry.sizeBytes) & ")...")
  else:
    stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle,
      "Downloading " & entry.name & " (" & formatBytes(entry.sizeBytes) & ")...")

  let downloadUrl = resolveDownloadUrl(entry)
  let exitCode = execCmd("curl -fL -C - -o " & quoteShell(partPath) & " " &
    quoteShell(downloadUrl) & " --progress-bar 2>&1")
  if exitCode != 0:
    echo ""
    if fileExists(partPath):
      let partSize = getFileSize(partPath)
      if partSize > 0 and partSize < entry.sizeBytes:
        stdout.styledWriteLine(styleBright, fgYellow, "  ! ", fgDefault, resetStyle,
          "Partial download saved (" & formatBytes(partSize) & "/" &
          formatBytes(entry.sizeBytes) & "). Re-run to resume.")
      else:
        removeFile(partPath)
    quit(1)

  echo ""

  let actualHash = sha256File(partPath)
  if actualHash != toLowerAscii(entry.digest.replace("sha256:", "")):
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, "Checksum verification failed")
    removeFile(partPath)
    quit(1)

  moveFile(partPath, modelPath)
  writeFile(hashPath, entry.digest)
  stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle,
    "Model ready: " & entry.name)

proc getModelPath*(cfg: Config, registry: ModelRegistry): string =
  let entry = findModel(registry, cfg.modelVariant)
  return cfg.modelsDir() / modelFilename(entry)

proc isEntryReady*(entry: ModelEntry, cfg: Config): bool =
  try:
    let modelPath = cfg.modelsDir() / modelFilename(entry)
    let hashPath = modelPath & ".sha256"
    if not fileExists(modelPath): return false
    if fileExists(hashPath):
      return readFile(hashPath).strip() == entry.digest
    return sha256File(modelPath) == toLowerAscii(entry.digest.replace("sha256:", ""))
  except CatchableError:
    return false

proc isModelReady*(cfg: Config, registry: ModelRegistry): bool =
  try:
    let entry = findModel(registry, cfg.modelVariant)
    return isEntryReady(entry, cfg)
  except CatchableError:
    return false

proc listModels*(cfg: Config, registry: ModelRegistry) =
  echo ""
  for entry in registry.entries:
    let isCurrent = entry.name == cfg.modelVariant
    let isReady = isEntryReady(entry, cfg)
    let marker = if isCurrent: " *" else: ""
    let status = if isReady: "[installed]" else: "[not installed]"
    let name = if isCurrent: entry.name & marker else: entry.name
    if isCurrent:
      stdout.styledWrite(styleBright)
    stdout.write "  " & name
    stdout.styledWrite(resetStyle)
    stdout.styledWriteLine("  " & status & "  " & formatBytes(entry.sizeBytes))
  echo ""
  stdout.styledWriteLine(styleDim, "  * = current selection", resetStyle)
