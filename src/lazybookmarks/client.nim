import std/[httpclient, json, os, re, strutils, asyncdispatch]
import ./config

type
  Message* = object
    role*: string
    content*: string

proc stripThinkTags*(s: string): string =
  result = s
  result = result.replace(re"💭[\s\S]*?💭", "")
  result = result.replace(re"</?💭[^>]*>", "")
  result = result.replace(re"<system-reminder>[\s\S]*?</system-reminder>", "")
  result = result.replace(re"```json\s*", "")
  result = result.replace(re"```\s*$", "")
  result = result.strip()

proc closeJson*(s: string): string =
  var opens: seq[char] = @[]
  var inStr = false
  var j = 0
  while j < s.len:
    if not inStr:
      case s[j]
      of '{', '[': opens.add(s[j])
      of '}':
        if opens.len > 0 and opens[opens.high] == '{': discard opens.pop()
      of ']':
        if opens.len > 0 and opens[opens.high] == '[': discard opens.pop()
      of '"': inStr = true
      else: discard
    else:
      if s[j] == '"' and (j == 0 or s[j - 1] != '\\'):
        inStr = false
    inc j
  result = s
  var k = opens.high
  while k >= 0:
    let closing = if opens[k] == '{': '}' else: ']'
    result.add(closing)
    dec k

proc extractJson*(s: string): string =
  var cleaned = stripThinkTags(s)
  let start = cleaned.find('{')
  if start < 0:
    return ""
  var depth = 0
  var inStr = false
  var endPos = -1
  for i in start .. cleaned.high:
    let c = cleaned[i]
    if inStr:
      if c == '"' and (i == 0 or cleaned[i - 1] != '\\'):
        inStr = false
    else:
      case c
      of '"': inStr = true
      of '{': inc depth
      of '}':
        dec depth
        if depth == 0:
          endPos = i
          break
      else: discard
  if endPos < 0:
    return closeJson(cleaned[start .. cleaned.high])
  return cleaned[start .. endPos]

proc buildRequestBody(cfg: Config, messages: seq[Message], jsonSchema: string): JsonNode =
  result = %*{
    "model": cfg.modelName,
    "messages": messages,
    "temperature": 0.1,
    "max_tokens": 2048,
    "options": {
      "think": false,
    },
  }
  if jsonSchema.len > 0:
    if cfg.isSmallModel():
      result["response_format"] = %*{ "type": "json_object" }
    else:
      result["response_format"] = %*{
        "type": "json_schema",
        "json_schema": {
          "strict": true,
          "schema": parseJson(jsonSchema),
        }
      }

proc chatCompletion*(cfg: Config, messages: seq[Message],
                    jsonSchema: string = "",
                    maxRetries: int = 3): JsonNode =
  let body = buildRequestBody(cfg, messages, jsonSchema)

  let client = newHttpClient(timeout = 120000)
  client.headers = newHttpHeaders([("Content-Type", "application/json")])
  defer: client.close()

  let url = cfg.llmUrl & "/chat/completions"
  if cfg.verbose:
    stderr.writeLine("[chat] POST " & url & " model=" & cfg.modelName)
    for m in messages:
      stderr.writeLine("[chat]   " & m.role & ": " & m.content[0..min(300, m.content.high)])

  var lastError = ""
  for attempt in 1..maxRetries:
    try:
      let response = client.postContent(url, body = $body)

      if cfg.verbose:
        stderr.writeLine("[attempt " & $attempt & "] -> " & $response.len & " bytes")

      let parsed = parseJson(response)
      if parsed.hasKey("choices") and parsed["choices"].len > 0:
        let rawContent = parsed["choices"][0]["message"]["content"].getStr()
        let content = extractJson(rawContent)
        if content.len > 0:
          if cfg.verbose:
            stderr.writeLine("[chat] response: " & content[0..min(200, content.high)])
          return parseJson(content)
        else:
          lastError = "No JSON found in response: " & rawContent[0..min(200, rawContent.high)]
      else:
        lastError = "No choices in response: " & response[0..min(200, response.high)]
    except CatchableError as e:
      lastError = e.msg
      if cfg.verbose:
        stderr.writeLine("[attempt " & $attempt & "] Error: " & e.msg)
      if attempt < maxRetries:
        let delay = 1000 * (1 shl (attempt - 1))
        discard execShellCmd("sleep " & $(delay * 3 div 1000))

  raise newException(CatchableError, "chatCompletion failed after " & $maxRetries & " attempts: " & lastError)

proc chatCompletionSimple*(cfg: Config, systemPrompt: string, userMessage: string,
                            jsonSchema: string = ""): JsonNode =
  let messages = @[
    Message(role: "system", content: systemPrompt),
    Message(role: "user", content: userMessage),
  ]
  return chatCompletion(cfg, messages, jsonSchema)

proc chatCompletionAsync*(cfg: Config, messages: seq[Message],
                          jsonSchema: string = "",
                          maxRetries: int = 3): Future[JsonNode] {.async.} =
  let body = buildRequestBody(cfg, messages, jsonSchema)
  let url = cfg.llmUrl & "/chat/completions"

  if cfg.verbose:
    stderr.writeLine("[chat-async] POST " & url & " model=" & cfg.modelName)

  var lastError = ""
  for attempt in 1..maxRetries:
    try:
      let client = newAsyncHttpClient()
      client.headers = newHttpHeaders([("Content-Type", "application/json")])

      let postFut = client.postContent(url, body = $body)
      let timedOut = not await withTimeout(postFut, 120_000)
      client.close()

      if timedOut:
        lastError = "Request timed out (120s)"
        if cfg.verbose:
          stderr.writeLine("[attempt " & $attempt & "] Timeout")
      else:
        let response = postFut.read()

        if cfg.verbose:
          stderr.writeLine("[attempt " & $attempt & "] -> " & $response.len & " bytes")

        let parsed = parseJson(response)
        if parsed.hasKey("choices") and parsed["choices"].len > 0:
          let rawContent = parsed["choices"][0]["message"]["content"].getStr()
          let content = extractJson(rawContent)
          if content.len > 0:
            if cfg.verbose:
              stderr.writeLine("[chat-async] response: " & content[0..min(200, content.high)])
            return parseJson(content)
          else:
            lastError = "No JSON found in response: " & rawContent[0..min(200, rawContent.high)]
        else:
          lastError = "No choices in response: " & response[0..min(200, response.high)]
    except CatchableError as e:
      lastError = e.msg
      if cfg.verbose:
        stderr.writeLine("[attempt " & $attempt & "] Error: " & e.msg)

    if attempt < maxRetries:
      let delay = 1000 * (1 shl (attempt - 1))
      await sleepAsync(delay)

  raise newException(CatchableError, "chatCompletionAsync failed after " & $maxRetries & " attempts: " & lastError)

proc chatCompletionSimpleAsync*(cfg: Config, systemPrompt: string, userMessage: string,
                                jsonSchema: string = ""): Future[JsonNode] {.async.} =
  let messages = @[
    Message(role: "system", content: systemPrompt),
    Message(role: "user", content: userMessage),
  ]
  return await chatCompletionAsync(cfg, messages, jsonSchema)
