import std/[os, strutils, re]

type ParamSize* = enum psSmall, psNormal

type Config* = object
  llmUrl*:         string
  modelVariant*:   string
  modelName*:      string
  dataDir*:        string
  runtimeManaged*: bool
  autoAcceptHigh*: bool
  batchSize*:      int
  concurrency*:    int
  verbose*:        bool
  paramSize*:      ParamSize

proc parseParamSize*(variant: string): ParamSize =
  for m in variant.findAll(re"[\d.]+[bB]"):
    let numPart = m[0 ..< m.len - 1]
    try:
      if parseFloat(numPart) < 1.5: return psSmall
    except:
      discard
  return psNormal

proc isSmallModel*(cfg: Config): bool =
  cfg.paramSize == psSmall

const DefaultLlmUrl* = "http://127.0.0.1:11434/v1"
const DefaultModelVariant* = "qwen3.5-2b"
const DefaultBatchSize* = 5
const DefaultConcurrency* = 4

proc xdgDataHome*: string =
  result = getEnv("XDG_DATA_HOME")
  if result.len == 0:
    result = getHomeDir() / ".local" / "share"

proc xdgConfigHome*: string =
  result = getEnv("XDG_CONFIG_HOME")
  if result.len == 0:
    result = getHomeDir() / ".config"

proc defaultDataDir*: string =
  xdgDataHome() / "lazybookmarks"

proc defaultConfigDir*: string =
  xdgConfigHome() / "lazybookmarks"

proc ensureDir*(dir: string) =
  createDir(dir)

proc loadConfig*(overrides: Config = Config()): Config =
  let variant = if overrides.modelVariant.len > 0: overrides.modelVariant
                elif getEnv("LB_MODEL").len > 0: getEnv("LB_MODEL")
                else: DefaultModelVariant
  let ps = parseParamSize(variant)
  let defaultBatch = if ps == psSmall: 5 else: 10
  result = Config(
    llmUrl:         DefaultLlmUrl,
    modelVariant:   variant,
    dataDir:        defaultDataDir(),
    runtimeManaged: true,
    autoAcceptHigh: false,
    batchSize:      defaultBatch,
    concurrency:    DefaultConcurrency,
    verbose:        false,
    paramSize:      ps,
  )

  let envLlmUrl = getEnv("LLM_URL")
  if envLlmUrl.len > 0:
    result.llmUrl = envLlmUrl
    result.runtimeManaged = false

  let envModel = getEnv("LB_MODEL")
  if envModel.len > 0:
    result.modelVariant = envModel
    result.paramSize = parseParamSize(envModel)

  let envDataDir = getEnv("LB_DATA_DIR")
  if envDataDir.len > 0:
    result.dataDir = envDataDir

  let envAutoAccept = getEnv("LB_AUTO_ACCEPT")
  if envAutoAccept.len > 0:
    result.autoAcceptHigh = true

  if overrides.llmUrl.len > 0 and overrides.llmUrl != DefaultLlmUrl:
    result.llmUrl = overrides.llmUrl
    result.runtimeManaged = false
  if overrides.modelVariant.len > 0:
    result.modelVariant = overrides.modelVariant
    result.paramSize = parseParamSize(overrides.modelVariant)
  if overrides.dataDir.len > 0:
    result.dataDir = overrides.dataDir
  if overrides.batchSize > 0:
    result.batchSize = overrides.batchSize
  if overrides.concurrency > 0:
    result.concurrency = overrides.concurrency
  if overrides.verbose:
    result.verbose = true
  if overrides.autoAcceptHigh:
    result.autoAcceptHigh = true

proc dbPath*(cfg: Config): string =
  cfg.dataDir / "bookmarks.db"

proc configFilePath*: string =
  defaultConfigDir() / "config.toml"
