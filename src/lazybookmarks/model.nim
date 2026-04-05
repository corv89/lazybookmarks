import std/[os, strformat, httpclient, json, terminal]
import jsony
import ./config

type
  ModelEntry* = object
    name*:        string
    ollamaModel*: string
    ollamaTag*:   string

  ModelRegistry* = object
    entries*: seq[ModelEntry]

const modelRegistryJson = staticRead("../../assets/models.json")

proc loadModelRegistry*: ModelRegistry =
  return modelRegistryJson.fromJson(ModelRegistry)

proc findModel*(registry: ModelRegistry, variant: string): ModelEntry =
  for e in registry.entries:
    if e.name == variant:
      return e
  raise newException(ValueError, &"Unknown model variant: {variant}")

proc ollamaRef*(entry: ModelEntry): string =
  entry.ollamaModel & ":" & entry.ollamaTag

proc pullModel*(entry: ModelEntry) =
  let refStr = ollamaRef(entry)
  stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle,
    "Pulling " & refStr & "...")

  let exitCode = execShellCmd("ollama pull " & quoteShell(refStr) & " 2>&1")
  if exitCode != 0:
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle,
      "Failed to pull " & refStr)
    quit(1)

proc listLocalModels*(cfg: Config): seq[string] =
  result = @[]
  try:
    let client = newHttpClient(timeout = 5000)
    defer: client.close()
    let body = client.getContent(cfg.ollamaApiUrl() & "/api/tags")
    let jsn = parseJson(body)
    for m in jsn["models"]:
      result.add(m["name"].getStr())
  except:
    discard

proc isEntryReady*(entry: ModelEntry, cfg: Config): bool =
  let refStr = ollamaRef(entry)
  for localName in listLocalModels(cfg):
    if localName == refStr:
      return true
  return false

proc isModelReady*(cfg: Config, registry: ModelRegistry): bool =
  try:
    let entry = findModel(registry, cfg.modelVariant)
    return isEntryReady(entry, cfg)
  except:
    return false

proc ensureModel*(cfg: Config, registry: ModelRegistry) =
  let entry = findModel(registry, cfg.modelVariant)
  if not isEntryReady(entry, cfg):
    pullModel(entry)
  else:
    stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle,
      "Model ready: " & ollamaRef(entry))

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
    stdout.styledWriteLine("  " & status & "  " & ollamaRef(entry))
  echo ""
  stdout.styledWriteLine(styleDim, "  * = current selection", resetStyle)
