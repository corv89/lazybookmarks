---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.filesetresolver
Generated: 2026-01-05
Updated: 2026-01-05
---

Resolves the files required for the MediaPipe Task APIs.

This class verifies whether SIMD is supported in the current environment and loads the SIMD files only if support is detected. The returned filesets require that the Wasm files are published without renaming. If this is not possible, you can invoke the MediaPipe Tasks APIs using a manually created `WasmFileset`.

**Signature:**

```
export declare class FilesetResolver
```

## Methods

| Method | Modifiers | Description |
| --- | --- | --- |
| forAudioTasks(basePath) | static | Creates a fileset for the MediaPipe Audio tasks. |
| forGenAiExperimentalTasks(basePath) | static | Creates a fileset for the MediaPipe GenAI Experimental tasks. |
| forGenAiTasks(basePath) | static | Creates a fileset for the MediaPipe GenAI tasks. |
| forTextTasks(basePath) | static | Creates a fileset for the MediaPipe Text tasks. |
| forVisionTasks(basePath) | static | Creates a fileset for the MediaPipe Vision tasks. |
| isSimdSupported() | static | Returns whether SIMD is supported in the current environment.If your environment requires custom locations for the MediaPipe Wasm files, you can use isSimdSupported() to decide whether to load the SIMD-based assets. Whether SIMD support was detected in the current environment. |

## FilesetResolver.forAudioTasks()

Creates a fileset for the MediaPipe Audio tasks.

**Signature:**

```
static forAudioTasks(basePath?: string): Promise<WasmFileset>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| basePath | string | An optional base path to specify the directory the Wasm files should be loaded from. If not specified, the Wasm files are loaded from the host's root directory. A WasmFileset that can be used to initialize MediaPipe Audio tasks. |

**Returns:**

Promise<WasmFileset>

## FilesetResolver.forGenAiExperimentalTasks()

Creates a fileset for the MediaPipe GenAI Experimental tasks.

**Signature:**

```
static forGenAiExperimentalTasks(basePath?: string): Promise<WasmFileset>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| basePath | string | An optional base path to specify the directory the Wasm files should be loaded from. If not specified, the Wasm files are loaded from the host's root directory. A WasmFileset that can be used to initialize MediaPipe GenAI tasks. |

**Returns:**

Promise<WasmFileset>

## FilesetResolver.forGenAiTasks()

Creates a fileset for the MediaPipe GenAI tasks.

**Signature:**

```
static forGenAiTasks(basePath?: string): Promise<WasmFileset>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| basePath | string | An optional base path to specify the directory the Wasm files should be loaded from. If not specified, the Wasm files are loaded from the host's root directory. A WasmFileset that can be used to initialize MediaPipe GenAI tasks. |

**Returns:**

Promise<WasmFileset>

## FilesetResolver.forTextTasks()

Creates a fileset for the MediaPipe Text tasks.

**Signature:**

```
static forTextTasks(basePath?: string): Promise<WasmFileset>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| basePath | string | An optional base path to specify the directory the Wasm files should be loaded from. If not specified, the Wasm files are loaded from the host's root directory. A WasmFileset that can be used to initialize MediaPipe Text tasks. |

**Returns:**

Promise<WasmFileset>

## FilesetResolver.forVisionTasks()

Creates a fileset for the MediaPipe Vision tasks.

**Signature:**

```
static forVisionTasks(basePath?: string): Promise<WasmFileset>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| basePath | string | An optional base path to specify the directory the Wasm files should be loaded from. If not specified, the Wasm files are loaded from the host's root directory. A WasmFileset that can be used to initialize MediaPipe Vision tasks. |

**Returns:**

Promise<WasmFileset>

## FilesetResolver.isSimdSupported()

Returns whether SIMD is supported in the current environment.

If your environment requires custom locations for the MediaPipe Wasm files, you can use `isSimdSupported()` to decide whether to load the SIMD-based assets.

Whether SIMD support was detected in the current environment.

**Signature:**

```
static isSimdSupported(): Promise<boolean>;
```

**Returns:**

Promise<boolean>
