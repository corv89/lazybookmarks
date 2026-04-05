import ./config
import ./model
import ./runtime
import ./ui

proc ensureReady*(cfg: var Config, registry: ModelRegistry) =
  if not cfg.runtimeManaged:
    return

  if not isRuntimeRunning(cfg):
    discard spawnRuntime(cfg)

    infoMsg "Waiting for ollama to start..."
    if not pollHealth(cfg):
      errorMsg "Ollama failed to start. Check logs:"
      dimMsg cfg.logFilePath()
      quit(1)

    infoMsg "Ollama ready"

  let entry = findModel(registry, cfg.modelVariant)
  cfg.modelName = ollamaRef(entry)

  if not isEntryReady(entry):
    pullModel(entry)
  else:
    infoMsg "Model ready: " & ollamaRef(entry)
