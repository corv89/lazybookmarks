import std/[os, osproc, strutils, strformat, httpclient, terminal, json, times]
import ./config

const RuntimeAssetPattern* = "llama-server-{os}-{arch}-static"

type Asset = object
  name: string
  browserDownloadUrl: string

type LlamaRelease = object
  tagName: string
  assets: seq[Asset]

proc detectAssetName(): string =
  when defined(linux) and defined(arm64):
    return "llama-server-linux-arm64-static"
  elif defined(linux) and defined(amd64):
    return "llama-server-linux-amd64-static"
  elif defined(macosx) and defined(arm64):
    return "llama-server-macos-arm64-static"
  elif defined(macosx) and defined(amd64):
    return "llama-server-macos-amd64-static"
  else:
    return "llama-server-linux-arm64-static"

proc findRuntimeAsset*(tagName: string): (string, string) =
  let assetName = detectAssetName()
  let client = newHttpClient()
  defer: client.close()

  try:
    let url = &"https://api.github.com/repos/ggml-org/llama.cpp/releases/{tagName}"
    let body = client.getContent(url)
    let jsn = parseJson(body)
    for asset in jsn["assets"]:
      let name = asset["name"].getStr()
      if name == assetName:
        return (name, asset["browser_download_url"].getStr())
  except CatchableError as e:
    stderr.writeLine(&"Warning: could not query GitHub releases: {e.msg}")

  return ("", "")

proc downloadRuntime*(cfg: Config): string =
  let binPath = cfg.runtimeBinPath()
  if fileExists(binPath):
    return binPath

  ensureDir(cfg.dataDir)
  ensureDir(cfg.binDir())

  stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle, "Downloading llama-server...")

  let (assetName, downloadUrl) = findRuntimeAsset("b5278")
  if downloadUrl.len == 0:
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, "Could not find llama-server binary for this platform")
    quit(1)

  let response = newHttpClient().get(downloadUrl)
  if response.code != Http200:
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, &"Download failed: HTTP {response.code}")
    quit(1)

  let partPath = binPath & ".part"
  let partFile = open(partPath, fmWrite)
  partFile.write(response.body)
  partFile.close()

  setFilePermissions(partPath, {fpUserRead, fpUserWrite, fpUserExec})
  moveFile(partPath, binPath)
  stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle, "Runtime ready")
  return binPath

proc isRuntimeRunning*(cfg: Config): bool =
  let pidPath = cfg.pidFilePath()
  if not fileExists(pidPath):
    return false
  try:
    discard readFile(pidPath).strip().parseInt()
    let client = newHttpClient(timeout = 2000)
    defer: client.close()
    discard client.getContent("http://127.0.0.1:18080/health")
    return true
  except:
    return false

proc spawnRuntime*(cfg: Config, modelPath: string): int =
  let binPath = cfg.runtimeBinPath()
  if not fileExists(binPath):
    stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, &"Runtime not found: {binPath}")
    quit(1)

  ensureDir(cfg.logsDir())

  let pid = startProcess(binPath, args = @[
    "--model", modelPath,
    "--port", "18080",
    "--host", "127.0.0.1",
    "--ctx-size", "4096",
  ], options = {poStdErrToStdOut})

  writeFile(cfg.pidFilePath(), $pid.processID)
  return pid.processID

proc pollHealth*(cfg: Config, timeoutMs: int = 30000): bool =
  let client = newHttpClient(timeout = 1000)
  defer: client.close()

  let startTime = epochTime() * 1000
  while (epochTime() * 1000 - startTime) < timeoutMs.float:
    try:
      discard client.getContent("http://127.0.0.1:18080/health")
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
      when defined(macosx):
        discard execShellCmd(&"kill {pid}")
      else:
        discard execShellCmd(&"kill {pid}")
      removeFile(pidPath)
  except:
    removeFile(pidPath)
