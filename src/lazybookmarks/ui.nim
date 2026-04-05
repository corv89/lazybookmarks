import std/[terminal, strutils]

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
