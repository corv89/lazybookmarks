import std/strutils
import ./storage

const SystemPrompt* = "You are a bookmark classifier. Given a user's folder structure and uncategorized bookmarks, assign each to the most appropriate existing folder. If no folder fits well, set targetFolderId to \"__skip__\" instead of forcing a poor match. Respond with ONLY valid JSON matching the required structure. No explanation, no markdown, no other text. Prefer the user's existing folder names. Only suggest new folders when necessary."

const TaxonomySchemaJson* = """{
  "type": "object",
  "properties": {
    "categories": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "folderId": { "type": "string" },
          "folderPath": { "type": "string" },
          "description": { "type": "string" },
          "keywords": { "type": "array", "items": { "type": "string" }, "maxItems": 10 }
        },
        "required": ["folderId", "folderPath", "description", "keywords"],
        "additionalProperties": false
      }
    }
  },
  "required": ["categories"],
  "additionalProperties": false
}"""

proc buildClusterSchemaJson*(rootFolderIds: seq[string]): string =
  var enumParts: seq[string] = @[]
  for id in rootFolderIds:
    enumParts.add("\"" & id & "\"")
  let enumValues = enumParts.join(", ")
  return "{\"type\":\"object\",\"properties\":{\"clusters\":{\"type\":\"array\",\"items\":{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"description\":{\"type\":\"string\"},\"keywords\":{\"type\":\"array\",\"items\":{\"type\":\"string\"},\"maxItems\":8},\"parentFolderId\":{\"type\":\"string\",\"enum\":[" & enumValues & "]}}}}}}"

proc buildClassificationSchemaJson*(folderIds: seq[string], bookmarkIds: seq[string]): string =
  var folderParts: seq[string] = @[]
  for id in folderIds:
    folderParts.add("\"" & id & "\"")
  let folderEnum = folderParts.join(", ") & ", \"__skip__\""
  var bookmarkParts: seq[string] = @[]
  for id in bookmarkIds:
    bookmarkParts.add("\"" & id & "\"")
  let bookmarkEnum = bookmarkParts.join(", ")
  return "{\"type\":\"object\",\"properties\":{\"moves\":{\"type\":\"array\",\"items\":{\"type\":\"object\",\"properties\":{\"bookmarkId\":{\"type\":\"string\",\"enum\":[" & bookmarkEnum & "]},\"targetFolderId\":{\"type\":\"string\",\"enum\":[" & folderEnum & "]},\"confidence\":{\"type\":\"string\",\"enum\":[\"high\",\"medium\",\"low\"]},\"reason\":{\"type\":\"string\"}},\"required\":[\"bookmarkId\",\"targetFolderId\",\"confidence\",\"reason\"],\"additionalProperties\":false}}},\"required\":[\"moves\"]}"

proc buildClassificationSchemaJsonSmall*(): string =
  return "{\"type\":\"object\",\"properties\":{\"moves\":{\"type\":\"array\",\"items\":{\"type\":\"object\",\"properties\":{\"bookmarkId\":{\"type\":\"string\"},\"targetFolderId\":{\"type\":\"string\"},\"confidence\":{\"type\":\"string\"},\"reason\":{\"type\":\"string\"}},\"required\":[\"bookmarkId\",\"targetFolderId\",\"confidence\",\"reason\"]}}},\"required\":[\"moves\"]}"

proc buildClusterSchemaJsonSmall*(): string =
  return "{\"type\":\"object\",\"properties\":{\"clusters\":{\"type\":\"array\",\"items\":{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"},\"description\":{\"type\":\"string\"},\"keywords\":{\"type\":\"array\",\"items\":{\"type\":\"string\"}},\"parentFolderId\":{\"type\":\"string\"}},\"required\":[\"name\",\"description\",\"keywords\",\"parentFolderId\"]}}},\"required\":[\"clusters\"]}"

proc buildTaxonomyPrompt*(enrichedFolders: seq[tuple[id, path, count: string, domains, keywords, exemplars: string]]): string =
  var lines: seq[string] = @[]
  for f in enrichedFolders:
    var parts: seq[string] = @[]
    parts.add("[" & f.id & "] " & f.path & " (" & f.count & ")")
    if f.domains.len > 0: parts.add("domains: " & f.domains)
    if f.keywords.len > 0: parts.add("keywords: " & f.keywords)
    if f.exemplars.len > 0: parts.add("examples: " & f.exemplars)
    lines.add(parts.join(" | "))
  return "Analyze these bookmark folders. For each, describe what it contains and provide keywords.\n\n" &
    lines.join("\n") & "\n\n" &
    "Respond with a JSON object: {\"categories\": [{\"folderId\": \"<id>\", \"folderPath\": \"<path>\", \"description\": \"<what it contains>\", \"keywords\": [\"word1\", \"word2\"]}]}\n\n" &
    "Example:\n{\"categories\": [{\"folderId\": \"a1b2c3\", \"folderPath\": \"Tech/Blogs\", \"description\": \"Programming and software development blogs\", \"keywords\": [\"programming\", \"software\", \"code\"]}]}"

proc formatBookmarkBatch*(bookmarks: seq[tuple[id, title, url: string]]): string =
  var lines: seq[string] = @[]
  for b in bookmarks:
    var shortUrl = extractDomain(b.url)
    if shortUrl.len > 60:
      shortUrl = shortUrl[0 .. 56] & "..."
    let title = if b.title.len > 0: b.title else: "(untitled)"
    lines.add("[" & b.id & "] \"" & title & "\" " & shortUrl)
  return lines.join("\n")

proc buildClusterPrompt*(uncategorizedBookmarks: seq[tuple[id, title, url: string]],
                         taxonomyCategories: seq[tuple[id, path: string]],
                         rootFolders: seq[tuple[id, title: string]]): string =
  var existingParts: seq[string] = @[]
  for c in taxonomyCategories:
    existingParts.add("[" & c.id & "] " & c.path)
  let existingList = existingParts.join("\n")

  var rootParts: seq[string] = @[]
  for f in rootFolders:
    rootParts.add("[" & f.id & "] " & f.title)
  let rootList = rootParts.join("\n")

  let bookmarkList = formatBookmarkBatch(uncategorizedBookmarks)

  return "Analyze these uncategorized bookmarks and identify 2-6 thematic groups that would benefit from a new folder.\n\n" &
    "Existing folders (for reference -- do NOT use these as parentFolderId):\n" &
    existingList & "\n\n" &
    "Valid locations for new folders (use one of these IDs as parentFolderId):\n" &
    rootList & "\n\n" &
    "Uncategorized bookmarks:\n" &
    bookmarkList & "\n\n" &
    "For each cluster, suggest a short folder name, a description, keywords, and which root location to create it in (parentFolderId).\n" &
    "Only suggest clusters when a meaningful group of 2+ bookmarks shares a clear theme. Do not suggest clusters that duplicate an existing folder's purpose.\n\n" &
    "Respond with a JSON object: {\"clusters\": [{\"name\": \"<folder name>\", \"description\": \"<what it contains>\", \"keywords\": [\"word1\", \"word2\"], \"parentFolderId\": \"<root folder id>\"}]}"

proc buildClassificationPrompt*(taxonomyCategories: seq[tuple[id, path, description, keywords: string]],
                                bookmarkBatch: seq[tuple[id, title, url: string]]): string =
  var folderParts: seq[string] = @[]
  for c in taxonomyCategories:
    folderParts.add("[" & c.id & "] " & c.path & ": " & c.description & " (" & c.keywords & ")")
  let folderList = folderParts.join("\n")
  let bookmarkList = formatBookmarkBatch(bookmarkBatch)

  return "Classify these bookmarks into the most appropriate folders.\n\n" &
    "Available folders:\n" &
    folderList & "\n\n" &
    "Bookmarks to classify (format: [id] \"title\" url):\n" &
    bookmarkList & "\n\n" &
    "For each bookmark:\n" &
    "- Choose the best existing folder (targetFolderId)\n" &
    "- Set confidence: \"high\" (obvious match), \"medium\" (reasonable), \"low\" (uncertain)\n" &
    "- Give a brief reason\n\n" &
    "Use targetFolderId=\"__skip__\" if no folder is a good match.\n\n" &
    "Respond with a JSON object: {\"moves\": [{\"bookmarkId\": \"<id>\", \"targetFolderId\": \"<folder id or __skip__>\", \"confidence\": \"high|medium|low\", \"reason\": \"<brief reason>\"}]}"
