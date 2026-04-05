import ./config
import ./model
import ./runtime
import ./ui

proc ensureReady*(cfg: Config, registry: ModelRegistry) =
  if not cfg.runtimeManaged:
    return

  if not isRuntimeRunning(cfg):
    discard downloadRuntime(cfg)
    ensureModel(cfg, registry)
    let modelPath = getModelPath(cfg, registry)
    discard spawnRuntime(cfg, modelPath)

    infoMsg "Waiting for runtime to start..."
    if not pollHealth(cfg):
      errorMsg "Runtime failed to start within timeout. Check logs:"
      dimMsg cfg.logFilePath()
      quit(1)

    infoMsg "Runtime ready"
  else:
    ensureModel(cfg, registry)
