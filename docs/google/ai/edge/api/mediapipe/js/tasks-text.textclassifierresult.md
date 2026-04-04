---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.textclassifierresult
Generated: 2026-01-05
Updated: 2026-01-05
---

Classification results of a model.

**Signature:**

```
export declare interface TextClassifierResult
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| classifications | Classifications[] | The classification results for each head of the model. |
| timestampMs | number | The optional timestamp (in milliseconds) of the start of the chunk of data corresponding to these results.This is only used for classification on time series (e.g. audio classification). In these use cases, the amount of data to process might exceed the maximum size that the model can process: to solve this, the input data is split into multiple chunks starting at different timestamps. |

## TextClassifierResult.classifications

The classification results for each head of the model.

**Signature:**

```
classifications: Classifications[];
```

## TextClassifierResult.timestampMs

The optional timestamp (in milliseconds) of the start of the chunk of data corresponding to these results.

This is only used for classification on time series (e.g. audio classification). In these use cases, the amount of data to process might exceed the maximum size that the model can process: to solve this, the input data is split into multiple chunks starting at different timestamps.

**Signature:**

```
timestampMs?: number;
```
