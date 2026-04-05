import std/[os, strutils, httpclient, terminal]
import ./config

proc findOllamaBin*(): string =
  for dir in getEnv("PATH").split(PathSep):
    let path = dir / "ollama"
    if fileExists(path):
      return path
  return ""

proc isRuntimeRunning*(cfg: Config): bool =
  try:
    let client = newHttpClient(timeout = 2000)
    defer: client.close()
    discard client.getContent(cfg.ollamaApiUrl() & "/api/tags")
    return true
  except:
    return false

proc requireRuntime*(cfg: Config) =
  if isRuntimeRunning(cfg):
    return
  if not cfg.runtimeManaged:
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle,
      "Endpoint not reachable: " & cfg.llmUrl)
    quit(1)
  stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle,
    "Ollama is not running.")
  when defined(macosx):
    stdout.styledWriteLine(styleDim, "    Start it with:  open -a Ollama", resetStyle)
    stdout.styledWriteLine(styleDim, "    Or install:     brew install ollama", resetStyle)
  elif defined(linux):
    stdout.styledWriteLine(styleDim, "    Start it with:  ollama serve &", resetStyle)
    stdout.styledWriteLine(styleDim, "    Or install:     curl -fsSL https://ollama.com/install.sh | sh", resetStyle)
  stdout.styledWriteLine(styleDim, "    Manual:         https://ollama.com/download", resetStyle)
  quit(1)
