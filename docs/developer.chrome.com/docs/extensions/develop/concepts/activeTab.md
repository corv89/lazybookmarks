---
Source: https://developer.chrome.com/docs/extensions/develop/concepts/activeTab
Generated: 2026-03-03
Updated: 2026-03-03
---

The `"activeTab"` permission gives an extension temporary access to the currently active tab when the user *invokes* the extension - for example by clicking its [action](/docs/extensions/reference/api/action). Access to the tab lasts while the user is on that page, and is revoked when the user navigates away or closes the tab. For example, if the user invokes the extension on https://example.com and then navigates to https://example.com/foo, the extension will continue to have access to the page. If the user navigates to https://chromium.org, access is revoked.

This serves as an alternative for many uses of `"<all_urls>"`, but displays *no warning message* during installation:

Without `"activeTab"`:

![Without activeTab](https://developers.google.com/static/docs/extensions/develop/concepts/activeTab/image/without-activetab-ac8957597267.png)

With `"activeTab"`:

![With activeTab](https://developers.google.com/static/docs/extensions/develop/concepts/activeTab/image/with-activetab-f0c7e749bcb97.png)

## Example

See the [Page Redder](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/sample.page-redder) sample extension:

manifest.json:

```json
{
  "name": "Page Redder",
  "version": "2.0",
  "permissions": [
    "activeTab",
    "scripting"
  ],
  "background": {
    "service_worker": "service-worker.js"
  },
  "action": {
    "default_title": "Make this page red"
  },
  "manifest_version": 3
}
```

service-worker:

```javascript
function reddenPage() {
  document.body.style.backgroundColor = 'red';
}

chrome.action.onClicked.addListener((tab) => {
  if (!tab.url.includes('chrome://')) {
    chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: reddenPage
    });
  }
});
```

## Motivation

Consider a web clipping extension that has an [action](/docs/extensions/reference/api/action) and a [context menu item](/docs/extensions/reference/api/contextMenus). This extension may only really need to access tabs when its action is clicked, or when its context menu item is executed.

Without `"activeTab"`, this extension would need to request full, persistent access to every website, just so that it could do its work if it happened to be called upon by the user. This is a lot of power to entrust to such a simple extension. And if the extension is ever compromised, the attacker gets access to everything the extension had.

In contrast, an extension with the `"activeTab"` permission only obtains access to a tab in response to an explicit user gesture. If the extension is compromised the attacker would need to wait for the user to invoke the extension before obtaining access. And that access only lasts until the tab is navigated or is closed.

## What "activeTab" allows

While the `"activeTab"` permission is enabled for a tab, an extension can:

-   Call [`scripting.insertCSS()`](/docs/extensions/reference/api/scripting#method-insertCSS) or [`scripting.executeScript()`](/docs/extensions/reference/api/scripting#method-executeScript) on that tab if the `"scripting"` [permission](/docs/extensions/develop/concepts/declare-permissions#permissions) is also declared (as in the [example above](#example)).
-   Get the URL, title, and favicon for that tab via an API that returns a [`tabs.Tab`](/docs/extensions/reference/api/tabs#type-Tab) object (essentially, `"activeTab"` grants [host permission](/docs/extensions/develop/concepts/match-patterns) temporarily).
-   Intercept network requests in the tab to the tab's main frame origin using the [webRequest](/docs/extensions/reference/api/webRequest) API. The extension temporarily gets host permissions for the tab's main frame origin.

## Invoking activeTab

The following user gestures enable the `"activeTab"` permission:

-   Executing an [action](/docs/extensions/reference/api/action)
-   Executing a [context menu item](/docs/extensions/reference/api/contextMenus)
-   Executing a keyboard shortcut from the [commands API](/docs/extensions/reference/api/commands)
-   Accepting a suggestion from the [omnibox API](/docs/extensions/reference/api/omnibox)
