---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.classifications
Generated: 2026-01-05
Updated: 2026-01-05
---

Classification results for a given classifier head.

**Signature:**

```
export declare interface Classifications
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| categories | Category[] | The array of predicted categories, usually sorted by descending scores, e.g., from high to low probability. |
| headIndex | number | The index of the classifier head these categories refer to. This is useful for multi-head models. |
| headName | string | The name of the classifier head, which is the corresponding tensor metadata name. Defaults to an empty string if there is no such metadata. |

## Classifications.categories

The array of predicted categories, usually sorted by descending scores, e.g., from high to low probability.

**Signature:**

```
categories: Category[];
```

## Classifications.headIndex

The index of the classifier head these categories refer to. This is useful for multi-head models.

**Signature:**

```
headIndex: number;
```

## Classifications.headName

The name of the classifier head, which is the corresponding tensor metadata name. Defaults to an empty string if there is no such metadata.

**Signature:**

```
headName: string;
```
