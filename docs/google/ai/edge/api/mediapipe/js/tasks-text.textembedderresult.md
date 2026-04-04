---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textembedderresult
Generated: 2026-01-05
Updated: 2026-01-05
---

Embedding results for a given embedder model.

**Signature:**

```
export declare interface TextEmbedderResult
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| embeddings | Embedding[] | The embedding results for each model head, i.e. one for each output tensor. |
| timestampMs | number | The optional timestamp (in milliseconds) of the start of the chunk of data corresponding to these results.This is only used for embedding extraction on time series (e.g. audio embedding). In these use cases, the amount of data to process might exceed the maximum size that the model can process: to solve this, the input data is split into multiple chunks starting at different timestamps. |

## TextEmbedderResult.embeddings

The embedding results for each model head, i.e. one for each output tensor.

**Signature:**

```
embeddings: Embedding[];
```

## TextEmbedderResult.timestampMs

The optional timestamp (in milliseconds) of the start of the chunk of data corresponding to these results.

This is only used for embedding extraction on time series (e.g. audio embedding). In these use cases, the amount of data to process might exceed the maximum size that the model can process: to solve this, the input data is split into multiple chunks starting at different timestamps.

**Signature:**

```
timestampMs?: number;
```
