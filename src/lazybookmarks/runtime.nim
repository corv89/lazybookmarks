import std/[os, osproc, strutils, strformat, httpclient, terminal, times]
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
    discard client.getContent("http://127.0.0.1:11434/api/tags")
    return true
  except:
    return false

proc spawnRuntime*(cfg: Config): int =
  let binPath = findOllamaBin()
  if binPath.len == 0:
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, "ollama not found in PATH")
    when defined(macosx):
      stdout.styledWriteLine(styleDim, "    macOS:  brew install ollama", resetStyle)
    elif defined(linux):
      stdout.styledWriteLine(styleDim, "    Linux:  curl -fsSL https://ollama.com/install.sh | sh", resetStyle)
    stdout.styledWriteLine(styleDim, "    Manual: https://ollama.com/download", resetStyle)
    quit(1)

  ensureDir(cfg.logsDir())

  let logPath = cfg.logFilePath()
  let pidPath = cfg.pidFilePath()
  let cmd = quoteShell(binPath) & " serve" &
    " >> " & quoteShell(logPath) & " 2>&1 & echo $! > " & quoteShell(pidPath)

  discard execShellCmd(cmd)

  try:
    result = readFile(pidPath).strip().parseInt()
  except:
    result = 0

proc pollHealth*(cfg: Config, timeoutMs: int = 30000): bool =
  let client = newHttpClient(timeout = 1000)
  defer: client.close()

  let startTime = epochTime() * 1000
  while (epochTime() * 1000 - startTime) < timeoutMs.float:
    try:
      discard client.getContent("http://127.0.0.1:11434/api/tags")
      return true
    except:
      os.sleep(500)
  return false

proc stopRuntime*(cfg: Config) =
  let pidPath = cfg.pidFilePath()
  if not fileExists(pidPath):
    return
  try:
    let pid = readFile(pidPath).strip().parseInt()
    if pid > 0:
      discard execShellCmd(&"kill {pid}")
      removeFile(pidPath)
  except:
    removeFile(pidPath)
