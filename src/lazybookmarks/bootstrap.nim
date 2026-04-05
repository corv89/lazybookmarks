import ./config
import ./model
import ./runtime
import ./ui

proc ensureReady*(cfg: var Config, registry: ModelRegistry) =
  if not cfg.runtimeManaged:
    return

  requireRuntime(cfg)

  let entry = findModel(registry, cfg.modelVariant)
  cfg.modelName = ollamaRef(entry)

  if not isEntryReady(entry):
    pullModel(entry)
  else:
    infoMsg "Model ready: " & ollamaRef(entry)
