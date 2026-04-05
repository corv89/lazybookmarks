import std/[httpclient, json, os]
import ./config

type
  Message* = object
    role*: string
    content*: string

proc chatCompletion*(cfg: Config, messages: seq[Message],
                    jsonSchema: string = "",
                    maxRetries: int = 3): JsonNode =
  let body = %*{
    "model": "local",
    "messages": messages,
    "temperature": 0.1,
    "max_tokens": 1024,
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

  var lastError = ""
  for attempt in 1..maxRetries:
    try:
      let url = cfg.llmUrl / "chat" / "completions"
      let response = client.postContent(url, body = $body)

      if cfg.verbose:
        stderr.writeLine("[attempt " & $attempt & "] POST " & url & " -> " & $response.len & " bytes")

      let parsed = parseJson(response)
      if parsed.hasKey("choices") and parsed["choices"].len > 0:
        let content = parsed["choices"][0]["message"]["content"].getStr()
        return parseJson(content)
      else:
        lastError = "No choices in response: " & response[0..min(200, response.high)]
    except CatchableError as e:
      lastError = e.msg
      if cfg.verbose:
        stderr.writeLine("[attempt " & $attempt & "] Error: " & e.msg)
      if attempt < maxRetries:
        let delay = 1000 * (1 shl (attempt - 1))
        os.sleep(delay)

  raise newException(CatchableError, "chatCompletion failed after " & $maxRetries & " attempts: " & lastError)

proc chatCompletionSimple*(cfg: Config, systemPrompt: string, userMessage: string,
                           jsonSchema: string = ""): JsonNode =
  let messages = @[
    Message(role: "system", content: systemPrompt),
    Message(role: "user", content: userMessage),
  ]
  return chatCompletion(cfg, messages, jsonSchema)
