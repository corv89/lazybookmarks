---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text.category
Generated: 2026-01-05
Updated: 2026-01-05
---

A classification category.

**Signature:**

```
export declare interface Category
```

## Properties

| Property | Type | Description |
| --- | --- | --- |
| categoryName | string | The label of this category object. Defaults to an empty string if there is no category. |
| displayName | string | The display name of the label, which may be translated for different locales. For example, a label, "apple", may be translated into Spanish for display purpose, so that the display_name is "manzana". Defaults to an empty string if there is no display name. |
| index | number | The index of the category in the corresponding label file. |
| score | number | The probability score of this label category. |

## Category.categoryName

The label of this category object. Defaults to an empty string if there is no category.

**Signature:**

```
categoryName: string;
```

## Category.displayName

The display name of the label, which may be translated for different locales. For example, a label, "apple", may be translated into Spanish for display purpose, so that the `display_name` is "manzana". Defaults to an empty string if there is no display name.

**Signature:**

```
displayName: string;
```

## Category.index

The index of the category in the corresponding label file.

**Signature:**

```
index: number;
```

## Category.score

The probability score of this label category.

**Signature:**

```
score: number;
```
