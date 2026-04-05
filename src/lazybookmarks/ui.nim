import std/[terminal, strutils, strformat]
import ./storage
import ./linkchecker

proc infoMsg*(msg: string) =
  stdout.styledWriteLine(styleBright, fgGreen, "  ✓ ", fgDefault, resetStyle, msg)

proc warnMsg*(msg: string) =
  stdout.styledWriteLine(styleBright, fgYellow, "  ! ", fgDefault, resetStyle, msg)

proc errorMsg*(msg: string) =
  stdout.styledWriteLine(styleBright, fgRed, "  ✗ ", fgDefault, resetStyle, msg)

proc dimMsg*(msg: string) =
  stdout.styledWrite(styleDim, "  " & msg, resetStyle, "\n")

proc headerMsg*(msg: string) =
  stdout.styledWriteLine(styleBright, fgCyan, "\n  " & msg, resetStyle, "\n")

proc showProgressBar*(current: int, total: int, prefix: string = "") =
  stdout.write "\r\e[2K"
  if total == 0:
    stdout.write prefix & " 0/0"
    stdout.flushFile()
    return
  let pct = (current * 100) div total
  let width = 30
  let filled = (current * width) div total
  let bar = repeat("#", filled) & repeat("-", width - filled)
  stdout.write prefix & " [" & bar & "] " & $pct & "% (" & $current & "/" & $total & ")"
  stdout.flushFile()

type ReviewAction* = enum
  accept, skip, edit, quitReview

proc reviewSuggestion*(url: string, title: string, targetFolder: string, confidence: string, reason: string): ReviewAction =
  echo ""
  stdout.styledWrite(styleBright, "  ┌─ ", resetStyle, url, "\n")
  stdout.styledWrite(styleBright, "  │  ", resetStyle)
  stdout.write "\"" & title & "\"\n"
  let confColor = case confidence
    of "high": fgGreen
    of "medium": fgYellow
    else: fgRed
  stdout.styledWrite(styleBright, "  │  ", resetStyle, "→ ")
  stdout.styledWrite(confColor, targetFolder, resetStyle)
  stdout.write "  [" & confidence.toUpperAscii() & "]\n"
  stdout.styledWriteLine(styleBright, "  │  ", resetStyle, styleDim, reason, resetStyle)
  stdout.styledWriteLine(styleBright, "  └─ ", resetStyle, styleDim, "[A]ccept  [S]kip  [e]dit  [q]uit", resetStyle)
  stdout.write "  > "
  stdout.flushFile()

  while true:
    let input = stdin.readLine().strip().toLowerAscii()
    case input
    of "a", "accept": return ReviewAction.accept
    of "s", "skip": return ReviewAction.skip
    of "e", "edit": return ReviewAction.edit
    of "q", "quit": return ReviewAction.quitReview
    else:
      stdout.write "\r\e[2K"
      stdout.write "  > "
      stdout.flushFile()

proc reviewDuplicateGroup*(idx: int, total: int, group: DuplicateGroup): bool =
  echo ""
  stdout.styledWriteLine(styleBright, fgCyan, &"  Duplicate group {idx}/{total} ", resetStyle, styleDim, &"({group.reason})", resetStyle)
  stdout.styledWriteLine(styleBright, "  Keep:  ", fgGreen, group.keep.title, resetStyle, styleDim, &"  [{group.keep.url[0..min(79, group.keep.url.high)]}]", resetStyle)
  for i, d in group.dupes:
    let title = if d.title.len > 0: d.title else: "(untitled)"
    stdout.styledWriteLine(styleDim, "    - ", resetStyle, title, styleDim, &"  [{d.url[0..min(79, d.url.high)]}]", resetStyle)
  stdout.styledWriteLine(styleBright, "  └─ ", resetStyle, styleDim, "[R]emove dupes  [S]kip  [q]uit", resetStyle)
  stdout.write "  > "
  stdout.flushFile()

  while true:
    let input = stdin.readLine().strip().toLowerAscii()
    case input
    of "r", "remove": return true
    of "s", "skip": return false
    of "q", "quit": return false
    else:
      stdout.write "\r\e[2K"
      stdout.write "  > "
      stdout.flushFile()

proc showLinkResult*(r: LinkResult) =
  let title = if r.bookmark.title.len > 0: r.bookmark.title else: "(untitled)"
  let (label, color) = case r.status
    of lsAlive: ("OK", fgGreen)
    of lsDead: ("DEAD", fgRed)
    of lsUnknown: ("???", fgYellow)
    of lsRedirected: ("REDIR", fgCyan)
  var extra = ""
  if r.status == lsRedirected and r.redirectUrl.len > 0:
    extra = &" -> {r.redirectUrl[0..min(60, r.redirectUrl.high)]}"
  if r.statusCode > 0:
    extra = &" [{r.statusCode}]{extra}"
  stdout.styledWrite("  ", color, &"{label:<5}", resetStyle, &" {title:<50}", styleDim, &" {r.bookmark.url[0..min(60, r.bookmark.url.high)]}{extra}", resetStyle, "\n")

proc showLinkSummary*(results: seq[LinkResult]) =
  var alive = 0
  var dead = 0
  var unknown = 0
  var redirected = 0
  for r in results:
    case r.status
    of lsAlive: inc alive
    of lsDead: inc dead
    of lsUnknown: inc unknown
    of lsRedirected: inc redirected
  echo ""
  stdout.styledWriteLine(styleBright, "  Summary:", resetStyle)
  if alive > 0:
    stdout.styledWriteLine("    ", fgGreen, &"{alive} alive", resetStyle)
  if dead > 0:
    stdout.styledWriteLine("    ", fgRed, &"{dead} dead", resetStyle)
  if redirected > 0:
    stdout.styledWriteLine("    ", fgCyan, &"{redirected} redirected", resetStyle)
  if unknown > 0:
    stdout.styledWriteLine("    ", fgYellow, &"{unknown} unknown", resetStyle)
  echo ""
