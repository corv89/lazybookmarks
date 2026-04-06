import std/[re, strutils, strformat, random, times, json, uri, sequtils]
import db_connector/db_sqlite
import ./config

randomize()

type
  BookmarkEntry* = object
    id*:       int64
    url*:      string
    title*:    string
    rawFolder*: string
    category*: string
    confidence*: string
    reason*:   string
    importId*: int64
    organisedAt*: int64
    addedAt*:  int64

  FolderEntry* = object
    id*:       int64
    uuid*:     string
    path*:     string
    parentId*: int64
    bookmarkCount*: int

const Schema = """
CREATE TABLE IF NOT EXISTS bookmarks (
  id            INTEGER PRIMARY KEY,
  url           TEXT    NOT NULL UNIQUE,
  title         TEXT,
  raw_folder    TEXT,
  category      TEXT,
  confidence    TEXT CHECK(confidence IN ('high','medium','low',NULL)),
  reason        TEXT,
  import_id     INTEGER REFERENCES imports(id),
  organised_at  INTEGER,
  added_at      INTEGER
);

CREATE TABLE IF NOT EXISTS imports (
  id            INTEGER PRIMARY KEY,
  filename      TEXT,
  format        TEXT CHECK(format IN ('netscape','json','urllist')),
  imported_at   INTEGER,
  bookmark_count INTEGER
);

CREATE TABLE IF NOT EXISTS taxonomy_cache (
  fingerprint   TEXT PRIMARY KEY,
  taxonomy      TEXT NOT NULL,
  created_at    INTEGER
);

CREATE TABLE IF NOT EXISTS folders (
  id            INTEGER PRIMARY KEY,
  uuid          TEXT    NOT NULL UNIQUE,
  path          TEXT    NOT NULL UNIQUE,
  parent_path   TEXT,
  bookmark_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_organised ON bookmarks(organised_at);
CREATE INDEX IF NOT EXISTS idx_bookmarks_import ON bookmarks(import_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_folder ON bookmarks(raw_folder);
"""

proc initDb*(cfg: Config): DbConn

proc genUuid*: string =
  const hexChars = "0123456789abcdef"
  var s = ""
  for i in 0..31:
    if i == 8 or i == 12 or i == 16 or i == 20:
      s.add '-'
    s.add hexChars[rand(15)]
  return s

const TrackingParams = [
  "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
  "fbclid", "gclid", "msclkid", "ref", "source", "mc_cid", "mc_eid",
]

proc normalizeUrl*(url: string): string =
  try:
    var u = parseUri(url)
    var host = u.hostname.toLowerAscii()
    var path = u.path
    if path.len > 1 and path.endsWith("/"):
      path = path[0 ..< path.len - 1]
    var query = u.query
    if query.len > 0:
      var pairs: seq[string] = @[]
      for part in query.split('&'):
        let eqIdx = part.find('=')
        let key = if eqIdx >= 0: part[0 ..< eqIdx].toLowerAscii() else: part.toLowerAscii()
        var isTracking = false
        for tp in TrackingParams:
          if key == tp:
            isTracking = true
            break
        if not isTracking:
          pairs.add(part)
      if pairs.len > 0:
        query = pairs.join("&")
        result = host & path & "?" & query
      else:
        result = host & path
    else:
      result = host & path
  except:
    result = url.toLowerAscii()

proc extractDomain*(url: string): string =
  try:
    let u = parseUri(url)
    result = u.hostname.toLowerAscii()
  except:
    let idx = url.find("://")
    if idx >= 0:
      let rest = url[idx + 3 .. url.high]
      let slashIdx = rest.find('/')
      result = if slashIdx >= 0: rest[0 ..< slashIdx] else: rest
    else:
      result = url

type
  DuplicateGroup* = object
    keep*:   BookmarkEntry
    dupes*:  seq[BookmarkEntry]
    reason*: string

proc findDuplicates*(cfg: Config): seq[DuplicateGroup] =
  let db = cfg.initDb()
  defer: db.close()

  for row in db.fastRows(sql("SELECT id, url, title, raw_folder, category, confidence FROM bookmarks ORDER BY added_at DESC")):
    let b = BookmarkEntry(
      id:         parseBiggestInt(row[0]),
      url:        row[1],
      title:      row[2],
      rawFolder:  row[3],
      category:   row[4],
      confidence: row[5],
    )

    let normUrl = normalizeUrl(b.url)
    var matched = false

    for i in 0 ..< result.len:
      let g = result[i]
      let keepNorm = normalizeUrl(g.keep.url)
      if keepNorm == normUrl and normUrl.len > 0:
        result[i].dupes.add(b)
        matched = true
        break

    if not matched:
      for i in 0 ..< result.len:
        let g = result[i]
        let keepDomain = extractDomain(g.keep.url)
        let bDomain = extractDomain(b.url)
        if keepDomain == bDomain and keepDomain.len > 0:
          let keepTitle = g.keep.title.strip().toLowerAscii()
          let bTitle = b.title.strip().toLowerAscii()
          if keepTitle.len > 3 and keepTitle == bTitle:
            result[i].dupes.add(b)
            matched = true
            break

    if not matched:
      result.add(DuplicateGroup(keep: b, dupes: @[], reason: ""))

    for i in 0 ..< result.len:
      if result[i].dupes.len > 0:
        let keepNorm = normalizeUrl(result[i].keep.url)
        var allNormMatch = true
        for d in result[i].dupes:
          if normalizeUrl(d.url) != keepNorm:
            allNormMatch = false
            break
        result[i].reason = if allNormMatch: "normalized URL match" else: "same domain + title"

  result = result.filterIt(it.dupes.len > 0)

  for i in 0 ..< result.len:
    var g = result[i]
    if g.dupes.len > 0:
      var bestIdx = 0
      for j in 0 ..< g.dupes.len:
        if g.dupes[j].category.len > 0 and g.keep.category.len == 0:
          bestIdx = j + 1
          break
      if bestIdx > 0:
        let oldKeep = g.keep
        g.keep = g.dupes[bestIdx - 1]
        g.dupes[bestIdx - 1] = oldKeep
      result[i] = g

proc removeDuplicates*(cfg: Config, ids: seq[int64]): int =
  if ids.len == 0:
    return 0
  let db = cfg.initDb()
  defer: db.close()
  let placeholders = repeat("?", ids.len).join(",")
  result = db.execAffectedRows(
    sql(&"DELETE FROM bookmarks WHERE id IN ({placeholders})"), ids)

proc deleteBookmarks*(cfg: Config, ids: seq[int64]): int =
  if ids.len == 0:
    return 0
  let db = cfg.initDb()
  defer: db.close()
  let placeholders = repeat("?", ids.len).join(",")
  result = db.execAffectedRows(
    sql(&"DELETE FROM bookmarks WHERE id IN ({placeholders})"), ids)

proc initDb*(cfg: Config): DbConn =
  ensureDir(cfg.dataDir)
  result = open(cfg.dbPath(), "", "", "")
  for stmt in Schema.split(';'):
    let trimmed = stmt.strip()
    if trimmed.len > 0:
      result.exec(sql(trimmed))

proc getOrCreateFolder(db: DbConn, path: string, parentPath: string = ""): FolderEntry =
  let row = db.getRow(sql("SELECT id, uuid, path, parent_path, bookmark_count FROM folders WHERE path = ?"), path)
  if row[0].len > 0:
    return FolderEntry(
      id: parseBiggestInt(row[0]),
      uuid: row[1],
      path: row[2],
      parentId: if row[3].len > 0: parseBiggestInt(row[3]) else: 0,
      bookmarkCount: if row[4].len > 0: parseBiggestInt(row[4]) else: 0,
    )
  let uuid = genUuid()
  result = FolderEntry(
    uuid: uuid,
    path: path,
    parentId: 0,
    bookmarkCount: 0,
  )
  result.id = db.insertId(sql("INSERT INTO folders (uuid, path, parent_path, bookmark_count) VALUES (?, ?, ?, 0)"), uuid, path, parentPath)
  return result

proc importNetscapeHtml*(content: string): seq[tuple[url, title, folder: string]] =
  result = @[]
  var folderStack: seq[string] = @[""]

  for line in content.splitLines():
    let trimmed = line.strip()
    if "<DT>" in trimmed:
      if "<A " in trimmed and "HREF=" in trimmed:
        var matches: array[1, string]
        if trimmed.find(re"""HREF="([^"]*)""", matches) >= 0:
          let url = matches[0]
          let titleStart = trimmed.find(">")
          let titleEnd = trimmed.find("</A>")
          var title = ""
          if titleStart >= 0 and titleEnd > titleStart:
            title = trimmed[titleStart + 1 .. titleEnd - 1]
            title = title.replace(re"<[^>]+>", "")
          result.add((url, title, folderStack.join(" / ")))
      elif "<H3" in trimmed and "</H3>" in trimmed:
        var matches: array[1, string]
        if trimmed.find(re"""<H3[^>]*>(.*?)</H3>""", matches) >= 0:
          var folderName = matches[0].replace(re"<[^>]+>", "")
          folderStack.add(folderName)
    if "</DL>" in trimmed and folderStack.len > 1:
      discard folderStack.pop()

proc importJson*(content: string): seq[tuple[url, title, folder: string]] =
  result = @[]
  try:
    let parsed = parseJson(content)
    for item in parsed.getElems():
      let url = item{"url"}.getStr("")
      let title = item{"title"}.getStr("")
      let folder = item{"folder"}.getStr("")
      if url.len > 0:
        result.add((url, title, folder))
  except:
    discard

proc importUrlList*(content: string): seq[tuple[url, title, folder: string]] =
  result = @[]
  for line in content.splitLines():
    let trimmed = line.strip()
    if trimmed.len == 0 or trimmed.startsWith("#"):
      continue
    if trimmed.startsWith("http://") or trimmed.startsWith("https://"):
      result.add((trimmed, "", ""))

proc detectFormat*(content: string, filename: string): string =
  let parts = filename.split('.')
  let ext = if parts.len > 1: parts[parts.len - 1].toLowerAscii() else: ""
  if ext == "json":
    return "json"
  if ext == "txt" or ext == "url" or ext == "urls":
    return "urllist"
  if ext == "html" or ext == "htm":
    return "netscape"
  if "<DT>" in content and "<A " in content:
    return "netscape"
  try:
    discard parseJson(content)
    return "json"
  except:
    discard
  return "urllist"

proc parseImport*(content: string, format: string): seq[tuple[url, title, folder: string]] =
  case format
  of "netscape": importNetscapeHtml(content)
  of "json": importJson(content)
  of "urllist": importUrlList(content)
  else: @[]

proc importBookmarks*(cfg: Config, content: string, format: string, filename: string): int =
  let db = cfg.initDb()
  defer: db.close()

  let parsed = parseImport(content, format)
  if parsed.len == 0:
    return 0

  let now = getTime().toUnix()
  let importId = db.insertId(
    sql("INSERT INTO imports (filename, format, imported_at, bookmark_count) VALUES (?, ?, ?, ?)"),
    filename, format, now, parsed.len
  )

  var count = 0
  for (url, title, folder) in parsed:
    let existing = db.getRow(sql("SELECT id FROM bookmarks WHERE url = ?"), url)
    if existing[0].len > 0:
      continue
    if folder.len > 0:
      discard db.getOrCreateFolder(folder)
    try:
      db.exec(
        sql("INSERT INTO bookmarks (url, title, raw_folder, import_id, added_at) VALUES (?, ?, ?, ?, ?)"),
        url, title, folder, importId, now
      )
      count.inc
    except DbError:
      continue

  return count

proc getUnorganisedBookmarks*(cfg: Config, limit: int = 0): seq[BookmarkEntry] =
  let db = cfg.initDb()
  defer: db.close()

  var query = "SELECT id, url, title, raw_folder, category, confidence FROM bookmarks WHERE organised_at IS NULL"
  if limit > 0:
    query.add &" LIMIT {limit}"
  query.add " ORDER BY added_at DESC"

  for row in db.fastRows(sql(query)):
    result.add(BookmarkEntry(
      id:        parseBiggestInt(row[0]),
      url:       row[1],
      title:     row[2],
      rawFolder: row[3],
      category:  row[4],
      confidence: row[5],
    ))

proc getAllBookmarks*(cfg: Config): seq[BookmarkEntry] =
  let db = cfg.initDb()
  defer: db.close()

  for row in db.fastRows(sql(
      "SELECT id, url, title, raw_folder, category, confidence FROM bookmarks ORDER BY added_at DESC")):
    result.add(BookmarkEntry(
      id:        parseBiggestInt(row[0]),
      url:       row[1],
      title:     row[2],
      rawFolder: row[3],
      category:  row[4],
      confidence: row[5],
    ))

proc listBookmarks*(cfg: Config, category: string = ""): seq[BookmarkEntry] =
  let db = cfg.initDb()
  defer: db.close()

  if category.len > 0:
    for row in db.fastRows(sql(
        "SELECT id, url, title, raw_folder, category, confidence FROM bookmarks WHERE raw_folder = ? ORDER BY added_at DESC LIMIT 50"),
        category):
      result.add(BookmarkEntry(
        id:        parseBiggestInt(row[0]),
        url:       row[1],
        title:     row[2],
        rawFolder: row[3],
        category:  row[4],
        confidence: row[5],
      ))
  else:
    for row in db.fastRows(sql(
        "SELECT id, url, title, raw_folder, category, confidence FROM bookmarks ORDER BY added_at DESC LIMIT 50")):
      result.add(BookmarkEntry(
        id:        parseBiggestInt(row[0]),
        url:       row[1],
        title:     row[2],
        rawFolder: row[3],
        category:  row[4],
        confidence: row[5],
      ))

proc searchBookmarks*(cfg: Config, query: string): seq[BookmarkEntry] =
  let db = cfg.initDb()
  defer: db.close()

  let pattern = "%" & query & "%"
  for row in db.fastRows(sql(
      "SELECT id, url, title, raw_folder, category, confidence FROM bookmarks WHERE title LIKE ? OR url LIKE ? OR category LIKE ? LIMIT 20"),
      pattern, pattern, pattern):
    result.add(BookmarkEntry(
      id:        parseBiggestInt(row[0]),
      url:       row[1],
      title:     row[2],
      rawFolder: row[3],
      category:  row[4],
      confidence: row[5],
    ))

proc getAllFolders*(cfg: Config): seq[FolderEntry] =
  let db = cfg.initDb()
  defer: db.close()

  for row in db.fastRows(sql("SELECT id, uuid, path, parent_path, bookmark_count FROM folders")):
    result.add(FolderEntry(
      id:            parseBiggestInt(row[0]),
      uuid:          row[1],
      path:          row[2],
      parentId:      if row[3].len > 0: parseBiggestInt(row[3]) else: 0,
      bookmarkCount: if row[4].len > 0: parseBiggestInt(row[4]) else: 0,
    ))

proc applyClassification*(cfg: Config, bookmarkId: int64, category: string, confidence: string, reason: string) =
  let db = cfg.initDb()
  defer: db.close()

  let now = getTime().toUnix()
  db.exec(sql(
    "UPDATE bookmarks SET category = ?, confidence = ?, reason = ?, organised_at = ? WHERE id = ?"
  ), category, confidence, reason, now, bookmarkId)

proc undoLastBatch*(cfg: Config): int =
  let db = cfg.initDb()
  defer: db.close()

  let row = db.getRow(sql(
    "SELECT organised_at FROM bookmarks WHERE organised_at IS NOT NULL ORDER BY organised_at DESC LIMIT 1"
  ))
  if row.len > 0 and row[0].len > 0:
    let batchTime = parseBiggestInt(row[0])
    result = db.execAffectedRows(sql(
      "UPDATE bookmarks SET category = NULL, confidence = NULL, reason = NULL, organised_at = NULL WHERE organised_at >= ?"
    ), batchTime)

proc htmlEscape*(s: string): string =
  result = s
  result = result.replace("&", "&amp;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")
  result = result.replace("\"", "&quot;")

proc getBookmarksForExport*(cfg: Config, categoryFilter = ""): seq[tuple[url, title, category: string]] =
  let db = cfg.initDb()
  defer: db.close()

  let query = if categoryFilter.len > 0:
    sql("SELECT url, title, category FROM bookmarks WHERE category = ? ORDER BY category, title")
  else:
    sql("SELECT url, title, category FROM bookmarks ORDER BY category, title")

  for row in db.fastRows(query, categoryFilter):
    result.add((
      url: row[0],
      title: row[1],
      category: if row[2].len > 0: row[2] else: "Unorganized",
    ))

proc exportBookmarksHtml*(cfg: Config, categoryFilter = ""): string =
  let bookmarks = getBookmarksForExport(cfg, categoryFilter)
  if bookmarks.len == 0:
    return ""

  var lines: seq[string] = @[]
  lines.add("""<!DOCTYPE NETSCAPE-Bookmark-file-1>""")
  lines.add("""<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">""")
  lines.add("<TITLE>Bookmarks</TITLE>")
  lines.add("<H1>Bookmarks</H1>")
  lines.add("<DL><p>")

  var currentCat = ""
  for bm in bookmarks:
    if bm.category != currentCat:
      if currentCat.len > 0:
        lines.add("</DL><p>")
      currentCat = bm.category
      lines.add("<DT><H3>" & htmlEscape(currentCat) & "</H3>")
      lines.add("<DL><p>")
    let title = if bm.title.len > 0: bm.title else: bm.url
    lines.add("<DT><A HREF=\"" & htmlEscape(bm.url) & "\">" & htmlEscape(title) & "</A>")

  lines.add("</DL><p>")
  lines.add("</DL><p>")
  return lines.join("\n")
