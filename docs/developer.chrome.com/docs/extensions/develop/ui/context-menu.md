---
Source: https://developer.chrome.com/docs/extensions/develop/ui/context-menu
Generated: 2026-03-03
Updated: 2026-03-03
---

A context menu appears for the alternate click (frequently called the right click) of a mouse. To build a context menu, first add the `"contextMenus"` [permission](/docs/extensions/develop/concepts/declare-permissions) to the manifest.json file.

manifest.json:

  ```
"permissions": [
    "contextMenus"
  ],
```

Optionally, use the [`"icons"`](/docs/extensions/reference/manifest/icons) key if you want to show an icon next to a menu item. In this example, the menu item for the "Global Google Search" extension uses a 16 by 16 icon.

![A context menu item with a 16 by 16 icon.](https://developers.google.com/static/docs/extensions/develop/ui/context-menu/images/context-menu.png)

A context menu item with a 16 by 16 icon.

This rest of this example is taken from the [Global Google Search context menu sample](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/contextMenus/global_context_search), which provides multiple context menu options. When an extension contains more than one context menu, Chrome automatically collapses them into a single parent menu as shown here:

![A nested context menu.](https://developers.google.com/static/docs/extensions/develop/ui/context-menu/images/context-menu-nested.png)

**Figure 4**: A context menu and a nested sub menu.

The sample shows this by calling [`contextMenus.create()`](/docs/extensions/reference/contextMenus#method-create) in the [extension service worker](/docs/extensions/develop/concepts/service-workers). Sub menu items are imported from the [locales.js](https://github.com/GoogleChrome/chrome-extensions-samples/blob/main/api-samples/contextMenus/global_context_search/locales.js) file. Then [`runtime.onInstalled`](https://developer.chrome.com/docs/extensions/reference/runtime#event-onInstalled) iterates over them.

service-worker.js:

```javascript
const tldLocales = {
  'com.au': 'Australia',
  'com.br': 'Brazil',
  ...
}

chrome.runtime.onInstalled.addListener(async () => {
  for (let [tld, locale] of Object.entries(tldLocales)) {
    chrome.contextMenus.create({
      id: tld,
      title: locale,
      type: 'normal',
      contexts: ['selection'],
    });
  }
});
```
