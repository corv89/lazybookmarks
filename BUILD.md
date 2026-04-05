# Building lazybookmarks

## Prerequisites

- **Nim** >= 2.0.0 — https://nim-lang.org/install.html
- **Ollama** — https://ollama.com/download (runtime dependency, not build-time)

### macOS

```sh
brew install nim ollama
```

### Ubuntu/Debian

```sh
sudo apt install nim
curl -fsSL https://ollama.com/install.sh | sh
```

### Arch Linux

```sh
sudo pacman -S nim
yay -S ollama-cuda  # or ollama-rocm for AMD
```

## Install Nim dependencies

```sh
nimble install cligen db_connector jsony
```

## Build

```sh
# Release (optimised, smaller binary)
nimble release

# Debug
nimble debug
```

The binary will be at `build/lazybookmarks`.

## Cross-compiling for Linux (from macOS)

Install a Linux cross-compiler, then:

```sh
nim c -d:release --os:linux --cpu:arm64 -o:build/lazybookmarks-linux-arm64 src/lazybookmarks/main.nim
```
