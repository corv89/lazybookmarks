import std/[httpclient, json, os, re, strutils]
import ./config

type
  Message* = object
    role*: string
    content*: string

proc stripThinkTags*(s: string): string =
  result = s
  result = result.replace(re"<think>[\s\S]*?</think>", "")
  result = result.replace(re"<system-reminder>[\s\S]*?</system-reminder>", "")
  result = result.replace(re"</?[\w][\w-]*[^>]*>", "")
  result = result.strip()

proc extractJson*(s: string): string =
  let cleaned = stripThinkTags(s)
  let start = cleaned.find('{')
  if start < 0:
    return ""
  var endPos = cleaned.high
  while endPos > start and cleaned[endPos] != '}':
    dec endPos
  if endPos <= start:
    return ""
  return cleaned[start .. endPos]

proc chatCompletion*(cfg: Config, messages: seq[Message],
                    jsonSchema: string = "",
                    maxRetries: int = 3): JsonNode =
  let body = %*{
    "model": cfg.modelName,
    "messages": messages,
    "temperature": 0.1,
    "max_tokens": 2048,
    "options": {
      "think": false,
    },
  }

  if jsonSchema.len > 0:
    body["response_format"] = %*{
      "type": "json_schema",
      "json_schema": {
        "strict": true,
        "schema": parseJson(jsonSchema),
      }
    }

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
