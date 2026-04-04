---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedder
Generated: 2026-01-05
Updated: 2026-01-05
---

Performs embedding extraction on text.

**Signature:**

```
export declare class TextEmbedder extends TaskRunner
```

**Extends:** TaskRunner

## Methods

| Method | Modifiers | Description |
| --- | --- | --- |
| cosineSimilarity(u, v) | static | Utility function to compute cosine similarity[1] between two Embedding objects.[1]: https://en.wikipedia.org/wiki/Cosine_similarity |
| createFromModelBuffer(wasmFileset, modelAssetBuffer) | static | Initializes the Wasm runtime and creates a new text embedder based on the provided model asset buffer. |
| createFromModelPath(wasmFileset, modelAssetPath) | static | Initializes the Wasm runtime and creates a new text embedder based on the path to the model asset. |
| createFromOptions(wasmFileset, textEmbedderOptions) | static | Initializes the Wasm runtime and creates a new text embedder from the provided options. |
| embed(text) |  | Performs embeding extraction on the provided text and waits synchronously for the response. |
| setOptions(options) |  | Sets new options for the text embedder.Calling setOptions() with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to undefined. |

## TextEmbedder.cosineSimilarity()

Utility function to compute cosine similarity\[1\] between two `Embedding` objects.

\[1\]: https://en.wikipedia.org/wiki/Cosine\_similarity

**Signature:**

```
static cosineSimilarity(u: Embedding, v: Embedding): number;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| u | Embedding |  |
| v | Embedding |  |

**Returns:**

number

### Exceptions

if the embeddings are of different types(float vs. quantized), have different sizes, or have an L2-norm of 0.

## TextEmbedder.createFromModelBuffer()

Initializes the Wasm runtime and creates a new text embedder based on the provided model asset buffer.

**Signature:**

```
static createFromModelBuffer(wasmFileset: WasmFileset, modelAssetBuffer: Uint8Array): Promise<TextEmbedder>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetBuffer | Uint8Array | A binary representation of the TFLite model. |

**Returns:**

Promise<[TextEmbedder](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedder#textembedder_class)\>

## TextEmbedder.createFromModelPath()

Initializes the Wasm runtime and creates a new text embedder based on the path to the model asset.

**Signature:**

```
static createFromModelPath(wasmFileset: WasmFileset, modelAssetPath: string): Promise<TextEmbedder>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| modelAssetPath | string | The path to the TFLite model. |

**Returns:**

Promise<[TextEmbedder](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedder#textembedder_class)\>

## TextEmbedder.createFromOptions()

Initializes the Wasm runtime and creates a new text embedder from the provided options.

**Signature:**

```
static createFromOptions(wasmFileset: WasmFileset, textEmbedderOptions: TextEmbedderOptions): Promise<TextEmbedder>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| wasmFileset | WasmFileset | A configuration object that provides the location of the Wasm binary and its loader. |
| textEmbedderOptions | TextEmbedderOptions | The options for the text embedder. Note that either a path to the TFLite model or the model itself needs to be provided (via baseOptions). |

**Returns:**

Promise<[TextEmbedder](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedder#textembedder_class)\>

## TextEmbedder.embed()

Performs embeding extraction on the provided text and waits synchronously for the response.

**Signature:**

```
embed(text: string): TextEmbedderResult;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| text | string | The text to process. The embedding resuls of the text |

**Returns:**

[TextEmbedderResult](https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedderresult#textembedderresult_interface)

## TextEmbedder.setOptions()

Sets new options for the text embedder.

Calling `setOptions()` with a subset of options only affects those options. You can reset an option back to its default value by explicitly setting it to `undefined`.

**Signature:**

```
setOptions(options: TextEmbedderOptions): Promise<void>;
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| options | TextEmbedderOptions | The options for the text embedder. |

**Returns:**

Promise<void>
