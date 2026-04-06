import std/[strutils, strformat, json, re, math, tables, algorithm, sequtils, sets, asyncdispatch]
import db_connector/db_sqlite
import ./config
import ./storage
import ./client
import ./prompts
import ./ui

type
  TaxonomyCategory* = object
    folderId*:    string
    folderPath*:  string
    description*: string
    keywords*:    seq[string]

  Taxonomy* = object
    categories*: seq[TaxonomyCategory]

  ClusterSuggestion* = object
    name*:          string
    description*:   string
    keywords*:      seq[string]
    parentFolderId*: string

  Classification* = object
    bookmarkId*:    string
    targetFolderId*: string
    confidence*:    string
    reason*:        string

  Suggestion* = object
    bookmarkId*:     int64
    bookmarkTitle*:  string
    bookmarkUrl*:    string
    targetFolderId*: string
    targetFolderPath*: string
    confidence*:     string
    reason*:         string
    isNewFolder*:    bool

const StopWords = ["the","a","an","and","or","of","to","in","for","is","on","with","at","by","from","this","that","it","as","are","was","be","has","have"]

proc tokenizeText*(text: string): seq[string] =
  result = @[]
  for word in text.toLowerAscii().replace(re"[^a-z0-9\säöüß]", " ").splitWhitespace():
    if word.len > 2 and word notin StopWords:
      result.add(word)

proc extractDomainPatterns*(bookmarks: seq[BookmarkEntry], threshold = 0.2): seq[string] =
  var counts: Table[string, int]
  for b in bookmarks:
    let domain = extractDomain(b.url).replace(re"^www\.", "")
    if domain.len > 0:
      counts[domain] = counts.getOrDefault(domain, 0) + 1
  let total = max(1, bookmarks.len)
  result = @[]
  for domain, count in counts:
    if count.float / total.float >= threshold:
      result.add(domain)
  sort(result, proc(a, b: string): int = cmp(counts[b], counts[a]))
  if result.len > 5:
    result.setLen(5)

proc computeTFIDF*(folderBookmarks: Table[string, seq[BookmarkEntry]], allBookmarks: seq[BookmarkEntry]): Table[string, seq[string]] =
  var df: Table[string, int]
  let N = max(1, allBookmarks.len)

  for b in allBookmarks:
    for tok in tokenizeText(b.title):
      df[tok] = df.getOrDefault(tok, 0) + 1

  result = initTable[string, seq[string]]()
  for folderId, bookmarks in folderBookmarks:
    if bookmarks.len == 0:
      result[folderId] = @[]
      continue
    var tf: Table[string, int]
    for b in bookmarks:
      for tok in tokenizeText(b.title):
        tf[tok] = tf.getOrDefault(tok, 0) + 1

    proc idf(term: string): float =
      let d = df.getOrDefault(term, 0)
      return ln(N.float / (1.0 + d.float))

    var scored: seq[tuple[word: string, score: float]] = @[]
    for word, freq in tf:
      let score = (freq.float / bookmarks.len.float) * idf(word)
      scored.add((word, score))

    scored.sort(proc(a, b: (string, float)): int = cmp(b[1], a[1]))
    var keywords: seq[string] = @[]
    for s in scored[0 .. min(5, scored.high)]:
      keywords.add(s[0])
    result[folderId] = keywords

proc sampleExemplars*(bookmarks: seq[BookmarkEntry], count = 2): string =
  var sorted = bookmarks
  sorted.sort(proc(a, b: BookmarkEntry): int = cmp(b.addedAt, a.addedAt))
  var parts: seq[string] = @[]
  for i in 0 .. min(count - 1, sorted.high):
    let host = extractDomain(sorted[i].url)
    let title = if sorted[i].title.len > 40: sorted[i].title[0 .. 39] else: sorted[i].title
    parts.add("\"" & title & "\" " & host)
  return parts.join(" | ")

proc buildFingerprint*(folders: seq[FolderEntry]): string =
  var parts: seq[string] = @[]
  for f in folders:
    parts.add(&"{f.uuid}:{f.bookmarkCount}")
  parts.sort()
  return parts.join(",")

proc loadCachedTaxonomy*(db: DbConn, fingerprint: string): (bool, Taxonomy) =
  try:
    let row = db.getRow(sql("SELECT taxonomy FROM taxonomy_cache WHERE fingerprint = ?"), fingerprint)
    if row[0].len == 0:
      return (false, Taxonomy())
    let json = parseJson(row[0])
    var cats: seq[TaxonomyCategory] = @[]
    for elem in json["categories"].getElems():
      var kws: seq[string] = @[]
      for kw in elem["keywords"].getElems():
        kws.add(kw.getStr())
      cats.add(TaxonomyCategory(
        folderId: elem["folderId"].getStr(),
        folderPath: elem["folderPath"].getStr(),
        description: elem["description"].getStr(),
        keywords: kws,
      ))
    let tax = Taxonomy(categories: cats)
    return (true, tax)
  except:
    return (false, Taxonomy())

proc saveTaxonomy*(db: DbConn, fingerprint: string, taxonomy: Taxonomy) =
  try:
    db.exec(sql("INSERT OR REPLACE INTO taxonomy_cache (fingerprint, taxonomy, created_at) VALUES (?, ?, strftime('%s','now'))"),
      fingerprint, $(%*taxonomy))
  except:
    discard

proc pruneTaxonomy*(taxonomy: Taxonomy, batch: seq[BookmarkEntry],
                    tfidfMap: Table[string, seq[string]],
                    topN = 15, minN = 5): Taxonomy =
  var batchTokens = initHashSet[string]()
  for b in batch:
    for tok in tokenizeText(b.title):
      batchTokens.incl(tok)

  var scored: seq[tuple[cat: TaxonomyCategory, overlap: int]] = @[]
  for cat in taxonomy.categories:
    let keywords = tfidfMap.getOrDefault(cat.folderId, @[])
    let overlap = keywords.filterIt(it in batchTokens).len
    scored.add((cat, overlap))

  sort(scored, proc(a, b: (TaxonomyCategory, int)): int =
    result = cmp(b[1], a[1])
    if result == 0: result = cmp(a[0].folderId, b[0].folderId)
  )

  let count = min(max(topN, minN), scored.len)
  var pruned: seq[TaxonomyCategory] = @[]
  for s in scored[0 .. count - 1]:
    pruned.add(s[0])
  return Taxonomy(categories: pruned)

proc runTaxonomyPhase*(cfg: Config, folders: seq[FolderEntry],
                       folderBookmarks: Table[string, seq[BookmarkEntry]],
                       allBookmarks: seq[BookmarkEntry],
                       db: DbConn): Taxonomy =
  let fingerprint = buildFingerprint(folders)
  let (cached, taxonomy) = loadCachedTaxonomy(db, fingerprint)
  if cached:
    if cfg.verbose:
      dimMsg &"Taxonomy cache hit ({taxonomy.categories.len} folders)"
    return taxonomy

  if cfg.verbose:
    dimMsg "Taxonomy cache miss, running Phase 1..."

  let tfidfMap = computeTFIDF(folderBookmarks, allBookmarks)

  var enriched: seq[tuple[id, path, count: string, domains, keywords, exemplars: string]] = @[]
  for folder in folders:
    let bookmarks = folderBookmarks.getOrDefault(folder.uuid, @[])
    let domains = extractDomainPatterns(bookmarks)
    let keywords = tfidfMap.getOrDefault(folder.uuid, @[])
    let exemplars = sampleExemplars(bookmarks)

    enriched.add((
      id: folder.uuid,
      path: folder.path,
      count: $folder.bookmarkCount,
      domains: domains.join(", "),
      keywords: keywords.join(", "),
      exemplars: exemplars,
    ))

  let prompt = buildTaxonomyPrompt(enriched)
  let response = chatCompletionSimple(cfg, SystemPrompt, prompt, TaxonomySchemaJson)

  result = Taxonomy(categories: @[])
  for elem in response["categories"].getElems():
    var kws: seq[string] = @[]
    for kw in elem["keywords"].getElems():
      kws.add(kw.getStr())
    result.categories.add(TaxonomyCategory(
      folderId: elem["folderId"].getStr(),
      folderPath: elem["folderPath"].getStr(),
      description: elem["description"].getStr(),
      keywords: kws,
    ))

  saveTaxonomy(db, fingerprint, result)
  if cfg.verbose:
    dimMsg &"Taxonomy cached ({result.categories.len} folders)"

proc runClusterPhase*(cfg: Config, uncategorized: seq[BookmarkEntry],
                      taxonomy: Taxonomy, folders: seq[FolderEntry]): seq[ClusterSuggestion] =
  var rootFolders: seq[tuple[id, title: string]] = @[]
  for f in folders:
    if f.parentId == 0:
      rootFolders.add((id: f.uuid, title: f.path))

  let batchTuples = uncategorized.mapIt((id: $it.id, title: it.title, url: it.url))
  let taxCats = taxonomy.categories.mapIt((id: it.folderId, path: it.folderPath))
  let rootIds = rootFolders.mapIt(it.id)

  let prompt = buildClusterPrompt(batchTuples, taxCats, rootFolders)
  let schema = buildClusterSchemaJson(rootIds)

  let response = chatCompletionSimple(cfg, SystemPrompt, prompt, schema)

  if not response.hasKey("clusters"):
    return @[]

  result = @[]
  for elem in response["clusters"].getElems():
    var kws: seq[string] = @[]
    for kw in elem["keywords"].getElems():
      kws.add(kw.getStr())
    result.add(ClusterSuggestion(
      name: elem["name"].getStr(),
      description: elem["description"].getStr(),
      keywords: kws,
      parentFolderId: elem["parentFolderId"].getStr(),
    ))

proc chunk*[T](s: seq[T], size: int): seq[seq[T]] =
  if size <= 0 or s.len == 0: return @[]
  result = @[]
  var i = 0
  while i < s.len:
    var batch: seq[T] = @[]
    for j in 0 ..< min(size, s.len - i):
      batch.add(s[i + j])
    result.add(batch)
    i += size

proc classifyBatchAsync(cfg: Config, batch: seq[BookmarkEntry],
                        fullTaxonomy: Taxonomy,
                        tfidfMap: Table[string, seq[string]],
                        batchIndex: int): Future[seq[Suggestion]] {.async.} =
  let pruned = pruneTaxonomy(fullTaxonomy, batch, tfidfMap)
  let folderIds = pruned.categories.mapIt(it.folderId)
  let bookmarkIds = batch.mapIt($it.id)
  let schema = buildClassificationSchemaJson(folderIds, bookmarkIds)

  let taxCats = pruned.categories.mapIt(
    (id: it.folderId, path: it.folderPath, description: it.description, keywords: it.keywords.join(", "))
  )
  let batchTuples = batch.mapIt((id: $it.id, title: it.title, url: it.url))
  let prompt = buildClassificationPrompt(taxCats, batchTuples)

  try:
    let response = await chatCompletionSimpleAsync(cfg, SystemPrompt, prompt, schema)
    var suggestions: seq[Suggestion] = @[]

    if response.hasKey("moves"):
      for move in response["moves"]:
        let moveObj = move
        let bmId = parseBiggestInt(moveObj["bookmarkId"].getStr())
        let targetId = moveObj["targetFolderId"].getStr()
        let conf = moveObj["confidence"].getStr()
        let reason = moveObj["reason"].getStr()

        if targetId == "__skip__":
          continue

        let bmIdx = batch.findIt(it.id == bmId)
        var bmTitle = ""
        var bmUrl = ""
        if bmIdx >= 0:
          bmTitle = batch[bmIdx].title
          bmUrl = batch[bmIdx].url
        let targetIdx = pruned.categories.findIt(it.folderId == targetId)
        var targetPath = targetId
        if targetIdx >= 0:
          targetPath = pruned.categories[targetIdx].folderPath
        let isNew = targetId.startsWith("__new_")

        suggestions.add(Suggestion(
          bookmarkId: bmId,
          bookmarkTitle: bmTitle,
          bookmarkUrl: bmUrl,
          targetFolderId: targetId,
          targetFolderPath: targetPath,
          confidence: conf,
          reason: reason,
          isNewFolder: isNew,
        ))

    return suggestions
  except CatchableError as e:
    if cfg.verbose:
      errorMsg &"Batch {batchIndex + 1} failed: {e.msg}"
    return @[]

proc runClassificationPhase*(cfg: Config, uncategorized: seq[BookmarkEntry],
                             taxonomy: Taxonomy,
                             folderBookmarks: Table[string, seq[BookmarkEntry]],
                             allBookmarks: seq[BookmarkEntry],
                             clusters: seq[ClusterSuggestion]): seq[Suggestion] =
  var fullTaxonomy = taxonomy

  let newFolders = clusters.mapIt(TaxonomyCategory(
    folderId: &"__new_{it.name}",
    folderPath: it.name,
    description: it.description,
    keywords: it.keywords,
  ))
  fullTaxonomy.categories.add(newFolders)

  let tfidfMap = computeTFIDF(folderBookmarks, allBookmarks)

  let batches = uncategorized.chunk(cfg.batchSize)
  let conc = cfg.concurrency

  if batches.len == 0:
    return @[]

  var completedCount = 0
  var allSuggestions: seq[Suggestion] = @[]

  if conc <= 1:
    for i, batch in batches:
      showProgressBar(i + 1, batches.len, "Classifying bookmarks")
      let suggestions = classifyBatchAsync(cfg, batch, fullTaxonomy, tfidfMap, i).waitFor()
      allSuggestions.add(suggestions)
    echo ""
    return allSuggestions

  var pending: seq[Future[seq[Suggestion]]] = @[]
  var batchIdx = 0

  proc drainPending(): int =
    var drained = 0
    var i = 0
    while i < pending.len:
      if pending[i].finished:
        let batchResult = pending[i].read()
        pending.delete(i)
        inc completedCount
        showProgressBar(completedCount, batches.len, "Classifying bookmarks")
        allSuggestions.add(batchResult)
        inc drained
      else:
        inc i
    return drained

  while batchIdx < batches.len or pending.len > 0:
    while pending.len < conc and batchIdx < batches.len:
      pending.add(classifyBatchAsync(cfg, batches[batchIdx], fullTaxonomy, tfidfMap, batchIdx))
      inc batchIdx

    while pending.len > 0:
      poll()
      discard drainPending()
      if pending.len > 0 and not pending[0].finished:
        poll()
      else:
        break

  echo ""
  return allSuggestions

proc organizeBookmarks*(cfg: Config, autoAcceptAll: bool = false, limit: int = 0): int =
  let db = cfg.initDb()
  defer: db.close()

  let uncategorized = getUnorganisedBookmarks(cfg, limit)
  let webUncategorized = uncategorized.filterIt(it.url.startsWith("http://") or it.url.startsWith("https://"))

  if webUncategorized.len == 0:
    dimMsg "No unorganized bookmarks found."
    return 0

  infoMsg &"Found {webUncategorized.len} unorganized bookmarks"

  let folders = getAllFolders(cfg)

  var folderBookmarks = initTable[string, seq[BookmarkEntry]]()
  var allBookmarks: seq[BookmarkEntry] = @[]

  for row in db.fastRows(sql("SELECT id, url, title, raw_folder FROM bookmarks")):
    let bm = BookmarkEntry(
      id: parseBiggestInt(row[0]),
      url: row[1],
      title: row[2],
      rawFolder: row[3],
    )
    allBookmarks.add(bm)
    if bm.rawFolder.len > 0:
      let folderIdx = folders.findIt(it.path == bm.rawFolder)
      if folderIdx >= 0:
        let folder = folders[folderIdx]
        if folder.uuid notin folderBookmarks:
          folderBookmarks[folder.uuid] = @[]
        folderBookmarks[folder.uuid].add(bm)

  headerMsg "Phase 1: Analyzing folder structure..."
  let taxonomy = runTaxonomyPhase(cfg, folders, folderBookmarks, allBookmarks, db)

  headerMsg "Phase 1.5: Identifying new folder opportunities..."
  var clusters: seq[ClusterSuggestion] = @[]
  try:
    clusters = runClusterPhase(cfg, webUncategorized, taxonomy, folders)
    if clusters.len > 0 and cfg.verbose:
      dimMsg &"Found {clusters.len} potential new folders"
  except CatchableError as e:
    if cfg.verbose:
      warnMsg &"Cluster phase skipped: {e.msg}"

  headerMsg "Phase 2: Classifying bookmarks..."
  let suggestions = runClassificationPhase(cfg, webUncategorized, taxonomy, folderBookmarks, allBookmarks, clusters)

  if suggestions.len == 0:
    dimMsg "No suggestions generated."
    return 0

  if autoAcceptAll or cfg.autoAcceptHigh:
    var accepted = 0
    for s in suggestions:
      if autoAcceptAll or s.confidence == "high":
        applyClassification(cfg, s.bookmarkId, s.targetFolderPath, s.confidence, s.reason)
        accepted.inc
    infoMsg &"Applied {accepted} suggestions automatically"
    return accepted

  var accepted = 0
  var skipped = 0
  var edited = 0

  for s in suggestions:
    let displayPath = s.targetFolderPath & (if s.isNewFolder: " (new)" else: "")
    let action = reviewSuggestion(s.bookmarkUrl, s.bookmarkTitle,
      displayPath, s.confidence, s.reason)

    case action
    of ReviewAction.accept:
      applyClassification(cfg, s.bookmarkId, s.targetFolderPath, s.confidence, s.reason)
      accepted.inc
    of ReviewAction.skip:
      skipped.inc
    of ReviewAction.edit:
      stdout.write "  New folder path: "
      stdout.flushFile()
      let newPath = stdin.readLine().strip()
      if newPath.len > 0:
        applyClassification(cfg, s.bookmarkId, newPath, s.confidence, s.reason)
        edited.inc
      else:
        skipped.inc
    of ReviewAction.quitReview:
      break

  infoMsg &"Done: {accepted} accepted, {skipped} skipped, {edited} edited"
  return accepted
