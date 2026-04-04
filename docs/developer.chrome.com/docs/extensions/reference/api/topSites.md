---
Source: https://developer.chrome.com/docs/extensions/reference/api/topSites
Generated: 2026-03-03
Updated: 2026-03-03
---

## Description

Use the `chrome.topSites` API to access the top sites (i.e. most visited sites) that are displayed on the new tab page. These do not include shortcuts customized by the user.

## Permissions

`topSites`

You must declare the "topSites" permission in your [extension's manifest](/docs/extensions/reference/manifest) to use this API.

```json
{
  "name": "My extension",
  ...
  "permissions": [
    "topSites",
  ],
  ...
}
```

## Examples

To try this API, install the [topSites API example](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/topSites) from the [chrome-extension-samples](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples) repository.

## Types

### MostVisitedURL

An object encapsulating a most visited URL, such as the default shortcuts on the new tab page.

#### Properties

-   title

    string

    The title of the page

-   url

    string

    The most visited URL.

## Methods

### get()

chrome.topSites.get(): Promise<[MostVisitedURL](#type-MostVisitedURL)\[\]\>

Gets a list of top sites.

#### Returns

-   Promise<[MostVisitedURL](#type-MostVisitedURL)\[\]>

    Chrome 96+
