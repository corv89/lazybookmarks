---
Source: https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/basics
Generated: 2026-03-03
Updated: 2026-03-03
---

Extension service workers are installed and updated differently from web service workers. This page explains those differences.

## Register service workers

To register an extension service worker, specify it in the `"background"` field of the `manifest.json` file. Use the `"service_worker"` key, which specifies a single JavaScript file. Service workers in web pages or web apps register service workers by first feature-detecting for `serviceWorker` in `navigator` then calling `register()` inside feature detection. This does not work for extensions.

```json
{
  "name": "Awesome Test Extension",
  ...
  "background": {
    "service_worker": "service-worker.js"
  },
  ...
}
```

## Import scripts

There are two methods of importing scripts into a service worker: the [`import`](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Statements/import) statement and the [`importScripts()`](https://developer.mozilla.org/docs/Web/API/WorkerGlobalScope/importScripts) method. Note that [`import()`](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Operators/import), often called a dynamic import, is not supported.

To use the `import` statement, add the `"type"` field to your manifest and specify `"module"`. For example:

  ```
"background": {
    "service_worker": "service-worker.js",
    "type": "module"
  }
```

Then use `import` as you normally would. Note that import assertions are not supported.

```javascript
import { tldLocales } from './locales.js';
```

Use `importScripts()` as you would in a web service worker.

```
importScripts('locales.js');
```

## Update

To update the service worker, [publish a new version](/docs/webstore/publish) of your extension to the Chrome Web Store. You cannot get around this by loading your extension from a server. For security reasons Manifest V3 [does not support](/docs/extensions/develop/migrate/improve-security#remove-remote-code) remotely-hosted code. Your service worker must be part of the extension package.
