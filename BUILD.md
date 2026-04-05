# Building lazybookmarks

## Prerequisites

- **Nim** >= 2.0.0 — https://nim-lang.org/install.html
- **OpenSSL** (for SHA256 via nimcrypto)
- **curl** (for model downloads)

### macOS

```sh
brew install nim openssl
```

### Ubuntu/Debian

```sh
sudo apt install nim libssl-dev curl
```

### Arch Linux

```sh
sudo pacman -S nim openssl curl
```

## Install Nim dependencies

```sh
nimble install cligen db_connector jsony nimcrypto
```

## Build

```sh
# Release (optimised, smaller binary)
nimble build

# Debug
nimble buildDebug
```

The binary will be at `build/lazybookmarks`.

## Cross-compiling for Linux (from macOS)

Install a Linux cross-compiler, then:

```sh
nim c -d:release --os:linux --cpu:arm64 -o:build/lazybookmarks-linux-arm64 src/lazybookmarks/main.nim
```

On Ubuntu with `musl` for a static binary:

```sh
nim c -d:release --os:linux --cpu:arm64 --gc:orc -d:useMalloc -o:build/lazybookmarks src/lazybookmarks/main.nim
```
