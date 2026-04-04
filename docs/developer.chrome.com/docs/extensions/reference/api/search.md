---
Source: https://developer.chrome.com/docs/extensions/reference/api/search
Generated: 2026-03-03
Updated: 2026-03-03
---

## Description

Use the `chrome.search` API to search via the default provider.

## Permissions

`search`

## Availability

Chrome 87+

## Types

### Disposition

#### Enum

"CURRENT\_TAB"
Specifies that the search results display in the calling tab or the tab from the active browser.

"NEW\_TAB"
Specifies that the search results display in a new tab.

"NEW\_WINDOW"
Specifies that the search results display in a new window.

### QueryInfo

#### Properties

-   disposition

    [Disposition](#type-Disposition) optional

    Location where search results should be displayed. `CURRENT_TAB` is the default.

-   tabId

    number optional

    Location where search results should be displayed. `tabId` cannot be used with `disposition`.

-   text

    string

    String to query with the default search provider.

## Methods

### query()

chrome.search.query(
  queryInfo: [QueryInfo](#type-QueryInfo),
): Promise<void>

Used to query the default search provider. In case of an error, [`runtime.lastError`](https://developer.chrome.com/docs/extensions/reference/runtime/#property-lastError) will be set.

#### Parameters

-   queryInfo

    [QueryInfo](#type-QueryInfo)

#### Returns

-   Promise<void>

    Chrome 96+
