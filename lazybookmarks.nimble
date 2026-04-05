# Package

version       = "0.1.0"
author        = "corv89"
description   = "CLI bookmark organizer powered by local LLM"
license       = "MIT"
srcDir        = "src"
bin           = @["lazybookmarks/main"]
installDirs   = @["lazybookmarks"]

# Dependencies

requires "nim >= 2.0.0"
requires "cligen >= 1.6"
requires "db_connector >= 0.1"
requires "nimcrypto"
requires "jsony >= 1.1"

# Tasks

task build, "Build release binary":
  exec "nim c -d:release -d:ssl -o:build/lazybookmarks src/lazybookmarks/main.nim"

task buildDebug, "Build debug binary":
  exec "nim c -d:ssl -o:build/lazybookmarks src/lazybookmarks/main.nim"
