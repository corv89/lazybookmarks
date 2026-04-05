import std/os

type Config* = object
  llmUrl*:         string
  modelVariant*:   string
  modelName*:      string
  dataDir*:        string
  runtimeManaged*: bool
  autoAcceptHigh*: bool
  batchSize*:      int
  verbose*:        bool

const DefaultLlmUrl* = "http://127.0.0.1:11434/v1"
const DefaultModelVariant* = "qwen3.5-0.8b"
const DefaultBatchSize* = 1

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
  result = Config(
    llmUrl:         DefaultLlmUrl,
    modelVariant:   DefaultModelVariant,
    dataDir:        defaultDataDir(),
    runtimeManaged: true,
    autoAcceptHigh: false,
    batchSize:      DefaultBatchSize,
    verbose:        false,
  )

  let envLlmUrl = getEnv("LLM_URL")
  if envLlmUrl.len > 0:
    result.llmUrl = envLlmUrl
    result.runtimeManaged = false

  let envModel = getEnv("LB_MODEL")
  if envModel.len > 0:
    result.modelVariant = envModel

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
  if overrides.dataDir.len > 0:
    result.dataDir = overrides.dataDir
  if overrides.batchSize > 0:
    result.batchSize = overrides.batchSize
  if overrides.verbose:
    result.verbose = true
  if overrides.autoAcceptHigh:
    result.autoAcceptHigh = true

proc dbPath*(cfg: Config): string =
  cfg.dataDir / "bookmarks.db"

proc logsDir*(cfg: Config): string =
  cfg.dataDir / "logs"

proc pidFilePath*(cfg: Config): string =
  cfg.dataDir / "runtime.pid"

proc logFilePath*(cfg: Config): string =
  cfg.logsDir() / "ollama.log"

proc configFilePath*: string =
  defaultConfigDir() / "config.toml"
