# Package

version       = "0.1.0"
author        = "corv89"
description   = "CLI bookmark organizer powered by local LLM"
license       = "MIT"
srcDir        = "src"
bin           = @["lazybookmarks/main"]

# Dependencies

requires "nim >= 2.0.0"
requires "cligen >= 1.6"
requires "db_connector >= 0.1"
requires "jsony >= 1.1"

# Tasks

task release, "Build release binary to build/":
  exec "nim c -d:release -o:build/lazybookmarks src/lazybookmarks/main.nim"

task debug, "Build debug binary to build/":
  exec "nim c -o:build/lazybookmarks src/lazybookmarks/main.nim"
