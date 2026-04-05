import std/[re, strutils, strformat, random, times, json]
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
    tags*:     string
    summary*:  string
    language*: string
    confidence*: string
    reason*:   string
    source*:   string
    importId*: int64
    organisedAt*: int64
    addedAt*:  int64

  FolderEntry* = object
    id*:       int64
    uuid*:     string
    path*:     string
    parentId*: int64
    bookmarkCount*: int

  ImportEntry* = object
    id*:           int64
    filename*:     string
    format*:       string
    importedAt*:   int64
    bookmarkCount*: int

const Schema = """
CREATE TABLE IF NOT EXISTS bookmarks (
  id            INTEGER PRIMARY KEY,
  url           TEXT    NOT NULL UNIQUE,
  title         TEXT,
  raw_folder    TEXT,
  category      TEXT,
  tags          TEXT,
  summary       TEXT,
  language      TEXT,
  confidence    TEXT CHECK(confidence IN ('high','medium','low',NULL)),
  reason        TEXT,
  source        TEXT,
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

proc genUuid*: string =
  const hexChars = "0123456789abcdef"
  var s = ""
  for i in 0..31:
    if i == 8 or i == 12 or i == 16 or i == 20:
      s.add '-'
    s.add hexChars[rand(15)]
  return s

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
        if trimmed.match(re"""HREF="([^"]*)""", matches):
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
        if trimmed.match(re"""<H3[^>]*>(.*?)</H3>""", matches):
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
        sql("INSERT INTO bookmarks (url, title, raw_folder, source, import_id, added_at) VALUES (?, ?, ?, 'import', ?, ?)"),
        url, title, folder, importId, now
      )
      count.inc
    except DbError:
      continue

  return count

proc getUnorganisedBookmarks*(cfg: Config, limit: int = 0): seq[BookmarkEntry] =
  let db = cfg.initDb()
  defer: db.close()

  var query = "SELECT id, url, title, raw_folder, category, tags, summary, language, confidence, reason, source, import_id, organised_at, added_at FROM bookmarks WHERE organised_at IS NULL"
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
      tags:      row[5],
      summary:   row[6],
      language:  row[7],
      confidence: row[8],
      reason:    row[9],
      source:    row[10],
      importId:  if row[11].len > 0: parseBiggestInt(row[11]) else: 0,
      organisedAt: if row[12].len > 0: parseBiggestInt(row[12]) else: 0,
      addedAt:   if row[13].len > 0: parseBiggestInt(row[13]) else: 0,
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
  let folder = db.getOrCreateFolder(category)
  db.exec(sql(
    "UPDATE bookmarks SET category = ?, confidence = ?, reason = ?, organised_at = ? WHERE id = ?"
  ), category, confidence, reason, now, bookmarkId)

proc undoLastBatch*(cfg: Config): int =
  let db = cfg.initDb()
  defer: db.close()

  let now = getTime().toUnix()
  result = db.execAffectedRows(sql(
    "UPDATE bookmarks SET category = NULL, confidence = NULL, reason = NULL, organised_at = NULL"
  ),)
  # Actually undo: find the last batch by organised_at
  let row = db.getRow(sql(
    "SELECT organised_at FROM bookmarks WHERE organised_at IS NOT NULL ORDER BY organised_at DESC LIMIT 1"
  ))
  if row[0].len > 0:
    let batchTime = parseBiggestInt(row[0])
    result = db.execAffectedRows(sql(
      "UPDATE bookmarks SET category = NULL, confidence = NULL, reason = NULL, organised_at = NULL WHERE organised_at >= ?"
    ), batchTime)
