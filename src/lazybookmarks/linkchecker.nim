import std/[osproc, strutils, sequtils, os, tables]
import ./config
import ./storage

type LinkStatus* = enum
  lsAlive, lsDead, lsUnknown, lsRedirected

type LinkResult* = object
  bookmark*:   BookmarkEntry
  status*:     LinkStatus
  statusCode*: int
  redirectUrl*: string

const TrackingParams = [
  "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
  "fbclid", "gclid", "msclkid",
]

proc checkBatch(urls: seq[string]): string =
  if urls.len == 0:
    return ""
  let tmpFile = getTempDir() / "lbcheck_urls.txt"
  let outFile = getTempDir() / "lbcheck_results.txt"
  try:
    var f: File
    if not open(f, tmpFile, fmWrite):
      return ""
    for u in urls:
      f.writeLine(u)
    f.close()

    let cmd = "cat '" & tmpFile & "' | xargs -P " & $urls.len &
      " -I{} curl -sI -o /dev/null -w '%{http_code}\\t%{redirect_url}\\t{}\\n' " &
      "--max-time 10 -L --max-redirs 5 -A 'Mozilla/5.0 (compatible; lazybookmarks/0.1)' '{}' > '" & outFile & "' 2>/dev/null"
    discard execShellCmd(cmd)

    if not fileExists(outFile):
      return ""
    result = readFile(outFile)
  except:
    discard
  finally:
    try: removeFile(tmpFile)
    except: discard
    try: removeFile(outFile)
    except: discard

proc classifyCode(code: int, redirectUrl: string): LinkStatus =
  if code >= 200 and code < 400:
    if redirectUrl.len > 0:
      var isTracking = false
      for tp in TrackingParams:
        if redirectUrl.contains("?" & tp & "=") or redirectUrl.contains("&" & tp & "="):
          isTracking = true
          break
      if isTracking:
        return lsAlive
      return lsRedirected
    return lsAlive
  if code == 404 or code == 410:
    return lsDead
  return lsUnknown

proc checkAllLinks*(cfg: Config, bookmarks: seq[BookmarkEntry],
                    concurrency: int = 8,
                    onProgress: proc(current, total: int) = nil): seq[LinkResult] =
  result = newSeq[LinkResult](bookmarks.len)
  let total = bookmarks.len
  if total == 0:
    return

  let batchSize = min(concurrency * 4, total)
  var offset = 0
  var done = 0

  while offset < total:
    let endIdx = min(offset + batchSize, total)
    var urls: seq[string] = @[]
    for i in offset ..< endIdx:
      urls.add(bookmarks[i].url)

    let content = checkBatch(urls)
    var resultMap: Table[string, tuple[code: int, redirectUrl: string]] = initTable[string, tuple[code: int, redirectUrl: string]]()

    for line in content.splitLines():
      if line.len == 0:
        continue
      let parts = line.split("\t", maxsplit = 2)
      if parts.len < 3:
        continue
      var code = 0
      try: code = parseInt(parts[0])
      except: continue
      let redirect = parts[1]
      let url = parts[2]
      if url.len > 0:
        resultMap[url] = (code, redirect)

    for i in offset ..< endIdx:
      let url = bookmarks[i].url
      if url in resultMap:
        let (code, redirect) = resultMap[url]
        result[i] = LinkResult(
          bookmark: bookmarks[i],
          status: classifyCode(code, redirect),
          statusCode: code,
          redirectUrl: redirect,
        )
      else:
        result[i] = LinkResult(
          bookmark: bookmarks[i],
          status: lsUnknown,
          statusCode: 0,
        )

    done = endIdx
    offset = endIdx
    if onProgress != nil:
      onProgress(done, total)
