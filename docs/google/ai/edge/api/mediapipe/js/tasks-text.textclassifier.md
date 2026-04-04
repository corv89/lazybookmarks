---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifier
Generated: 2026-01-05
Updated: 2026-01-05
---

Performs Natural Language classification.

**Signature:**

```
export declare class TextClassifier extends TaskRunner
```

**Extends:** TaskRunner

## Methods

| Method | Modifiers | Description |
| --- | --- | --- |
| classify(text) |  | Performs Natural Language classification on the provided text and waits synchronously for the response. |
| createFromModelBuffer(wasmFileset, modelAssetBuffer) | static | Initializes the Wasm runtime and creates a new text classifier based on the provided model asset buffer. |
| createFromModelPath(wasmFileset, modelAssetPath) | static | Initializes the Wasm runtime and creates a new text classifier based on the path to the model asset. |
| createFromOptions(wasmFileset, textClassifierOptions) | static | Initializes the Wasm runtime and creates a new text classifier from the provided options. |
| setOptions(options) |  | Sets new options for the text classifier.Calling setOptions() with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to undefined. |

## TextClassifier.classify()

Performs Natural Language classification on the provided text and waits synchronously for the response.

**Signature:**

```
classify(text: string): TextClassifierResult;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| text | string | The text to process. The classification result of the text |

**Returns:**

[TextClassifierResult](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifierresult#textclassifierresult_interface)

## TextClassifier.createFromModelBuffer()

Initializes the Wasm runtime and creates a new text classifier based on the provided model asset buffer.

**Signature:**

```
static createFromModelBuffer(wasmFileset: WasmFileset, modelAssetBuffer: Uint8Array): Promise<TextClassifier>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetBuffer | Uint8Array | A binary representation of the model. |

**Returns:**

Promise<[TextClassifier](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifier#textclassifier_class)\>

## TextClassifier.createFromModelPath()

Initializes the Wasm runtime and creates a new text classifier based on the path to the model asset.

**Signature:**

```
static createFromModelPath(wasmFileset: WasmFileset, modelAssetPath: string): Promise<TextClassifier>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetPath | string | The path to the model asset. |

**Returns:**

Promise<[TextClassifier](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifier#textclassifier_class)\>

## TextClassifier.createFromOptions()

Initializes the Wasm runtime and creates a new text classifier from the provided options.

**Signature:**

```
static createFromOptions(wasmFileset: WasmFileset, textClassifierOptions: TextClassifierOptions): Promise<TextClassifier>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| textClassifierOptions | TextClassifierOptions | The options for the text classifier. Note that either a path to the TFLite model or the model itself needs to be provided (via baseOptions). |

**Returns:**

Promise<[TextClassifier](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifier#textclassifier_class)\>

## TextClassifier.setOptions()

Sets new options for the text classifier.

Calling `setOptions()` with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to `undefined`.

**Signature:**

```
setOptions(options: TextClassifierOptions): Promise<void>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| options | TextClassifierOptions | The options for the text classifier. |

**Returns:**

Promise<void>
