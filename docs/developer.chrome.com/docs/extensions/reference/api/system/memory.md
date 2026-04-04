---
Source: https://developer.chrome.com/docs/extensions/reference/api/system/memory
Generated: 2026-01-05
Updated: 2026-01-05
---

# chrome.system.memory bookmark\_border Stay organized with collections Save and categorize content based on your preferences.

-   On this page
-   [Description](#description)
-   [Permissions](#permissions)
-   [Types](#type)
    -   [MemoryInfo](#type-MemoryInfo)
-   [Methods](#method)
    -   [getInfo()](#method-getInfo)

## Description

The `chrome.system.memory` API.

## Permissions

`system.memory`

## Types

### MemoryInfo

#### Properties

-   availableCapacity

    number

    The amount of available capacity, in bytes.

-   capacity

    number

    The total amount of physical memory capacity, in bytes.

## Methods

### getInfo()

chrome.system.memory.getInfo(): Promise<[MemoryInfo](#type-MemoryInfo)\>

Get physical memory information.

#### Returns

-   Promise<[MemoryInfo](#type-MemoryInfo)\>

    Chrome 91+
