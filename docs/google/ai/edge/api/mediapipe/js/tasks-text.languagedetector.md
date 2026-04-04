---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.languagedetector
Generated: 2026-01-05
Updated: 2026-01-05
---

Predicts the language of an input text.

**Signature:**

```
export declare class LanguageDetector extends TaskRunner
```

**Extends:** TaskRunner

## Methods

| Method | Modifiers | Description |
| --- | --- | --- |
| createFromModelBuffer(wasmFileset, modelAssetBuffer) | static | Initializes the Wasm runtime and creates a new language detector based on the provided model asset buffer. |
| createFromModelPath(wasmFileset, modelAssetPath) | static | Initializes the Wasm runtime and creates a new language detector based on the path to the model asset. |
| createFromOptions(wasmFileset, textClassifierOptions) | static | Initializes the Wasm runtime and creates a new language detector from the provided options. |
| detect(text) |  | Predicts the language of the input text. |
| setOptions(options) |  | Sets new options for the language detector.Calling setOptions() with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to undefined. |

## LanguageDetector.createFromModelBuffer()

Initializes the Wasm runtime and creates a new language detector based on the provided model asset buffer.

**Signature:**

```
static createFromModelBuffer(wasmFileset: WasmFileset, modelAssetBuffer: Uint8Array): Promise<LanguageDetector>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetBuffer | Uint8Array | A binary representation of the model. |

**Returns:**

Promise<[LanguageDetector](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.languagedetector#languagedetector_class)\>

## LanguageDetector.createFromModelPath()

Initializes the Wasm runtime and creates a new language detector based on the path to the model asset.

**Signature:**

```
static createFromModelPath(wasmFileset: WasmFileset, modelAssetPath: string): Promise<LanguageDetector>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetPath | string | The path to the model asset. |

**Returns:**

Promise<[LanguageDetector](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.languagedetector#languagedetector_class)\>

## LanguageDetector.createFromOptions()

Initializes the Wasm runtime and creates a new language detector from the provided options.

**Signature:**

```
static createFromOptions(wasmFileset: WasmFileset, textClassifierOptions: LanguageDetectorOptions): Promise<LanguageDetector>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| textClassifierOptions | LanguageDetectorOptions | The options for the language detector. Note that either a path to the TFLite model or the model itself needs to be provided (via baseOptions). |

**Returns:**

Promise<[LanguageDetector](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.languagedetector#languagedetector_class)\>

## LanguageDetector.detect()

Predicts the language of the input text.

**Signature:**

```
detect(text: string): LanguageDetectorResult;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| text | string | The text to process. The languages detected in the input text. |

**Returns:**

[LanguageDetectorResult](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.languagedetectorresult#languagedetectorresult_interface)

## LanguageDetector.setOptions()

Sets new options for the language detector.

Calling `setOptions()` with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to `undefined`.

**Signature:**

```
setOptions(options: LanguageDetectorOptions): Promise<void>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| options | LanguageDetectorOptions | The options for the language detector. |

**Returns:**

Promise<void>
