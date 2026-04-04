---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.embedding
Generated: 2026-01-05
Updated: 2026-01-05
---

List of embeddings with an optional timestamp.

One and only one of the two 'floatEmbedding' and 'quantizedEmbedding' will contain data, based on whether or not the embedder was configured to perform scalar quantization.

**Signature:**

```
export declare interface Embedding
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| floatEmbedding | number[] | Floating-point embedding. Empty if the embedder was configured to perform scalar-quantization. |
| headIndex | number | The index of the classifier head these categories refer to. This is useful for multi-head models. |
| headName | string | The name of the classifier head, which is the corresponding tensor metadata name. |
| quantizedEmbedding | Uint8Array | Scalar-quantized embedding. Empty if the embedder was not configured to perform scalar quantization. |

## Embedding.floatEmbedding

Floating-point embedding. Empty if the embedder was configured to perform scalar-quantization.

**Signature:**

```
floatEmbedding?: number[];
```

## Embedding.headIndex

The index of the classifier head these categories refer to. This is useful for multi-head models.

**Signature:**

```
headIndex: number;
```

## Embedding.headName

The name of the classifier head, which is the corresponding tensor metadata name.

**Signature:**

```
headName: string;
```

## Embedding.quantizedEmbedding

Scalar-quantized embedding. Empty if the embedder was not configured to perform scalar quantization.

**Signature:**

```
quantizedEmbedding?: Uint8Array;
```
