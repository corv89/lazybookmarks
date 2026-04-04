---
Source: https://developer.chrome.com/docs/extensions/develop/ui/options-page
Generated: 2026-03-03
Updated: 2026-03-03
---

Just as extensions allow users to customize the Chrome browser, the options page enables customization of the extension. Use options to enable features and allow users to choose what functionality is relevant to their needs.

## Locating the options page

Users can access the options page by [direct link](#linking) or by right-clicking the extension icon in the toolbar and then selecting options. Additionally, users can navigate to the options page by, first, opening `chrome://extensions`, locating the desired extension, clicking **Details**, and then selecting the options link.

![Options page link in the user interface](https://developers.google.com/static/docs/extensions/develop/ui/options-page/image/options-page-link-the-us-ae0a3ee5d7b2e.png)

Link to the Options page.

![Context Menu Options page](https://developers.google.com/static/docs/extensions/develop/ui/options-page/image/context-menu-options-page-3d4d2c8dcce27.png)

Right-clicking on the extension's icon.

## Write the options page

The following is an example of an options page:

options.html:

```
<!DOCTYPE html>
<html>
  <head>
    <title>My Test Extension Options</title>
  </head>
  <body>
    <select id="color">
      <option value="red">red</option>
      <option value="green">green</option>
      <option value="blue">blue</option>
      <option value="yellow">yellow</option>
    </select>

    <label>
      <input type="checkbox" id="like" />
      I like colors.
    </label>

    <div id="status"></div>
    <button id="save">Save</button>

    <script src="options.js"></script>
  </body>
</html>
```

Below is an example options script. Save it in the same folder as `options.html`. This saves the user's preferred options across devices using the [`storage.sync`](/docs/extensions/reference/api/storage#property-sync) API.

options.js:

```javascript
// Saves options to chrome.storage
const saveOptions = () => {
  const color = document.getElementById('color').value;
  const likesColor = document.getElementById('like').checked;

  chrome.storage.sync.set(
    { favoriteColor: color, likesColor: likesColor },
    () => {
      // Update status to let user know options were saved.
      const status = document.getElementById('status');
      status.textContent = 'Options saved.';
      setTimeout(() => {
        status.textContent = '';
      }, 750);
    }
  );
};

// Restores select box and checkbox state using the preferences
// stored in chrome.storage.
const restoreOptions = () => {
  chrome.storage.sync.get(
    { favoriteColor: 'red', likesColor: true },
    (items) => {
      document.getElementById('color').value = items.favoriteColor;
      document.getElementById('like').checked = items.likesColor;
    }
  );
};

document.addEventListener('DOMContentLoaded', restoreOptions);
document.getElementById('save').addEventListener('click', saveOptions);
```

Finally, add the `"storage"` permission to the extension's [manifest](/docs/extensions/reference/manifest) file:

manifest.json:

```json
{
  "name": "My extension",
  ...
  "permissions": [
    "storage"
  ]
  ...
}
```

## Declare options page behavior

There are two types of extension options pages, [full page](#full_page) and [embedded](#embedded_options). The type of options page is determined by how it is declared in the manifest.

### Full page options

A *full page* options page is displayed in a new tab. Register the options HTML file in the manifest in the `"options_page"` field.

manifest.json:

```json
{
  "name": "My extension",
  ...
  "options_page": "options.html",
  ...
}
```

![Full page options](https://developers.google.com/static/docs/extensions/develop/ui/options-page/image/full-page-options-06cf906a1303e.png)

Full page options in a new tab.

### Embedded options

An *embedded options* page allows users to adjust extension options without navigating away from the extensions management page inside an embedded box. To declare embedded options, register the HTML file under the `"options_ui"` field in the extension manifest, with the `"open_in_tab"` key set to `false`.

manifest.json:

```json
{
  "name": "My extension",
  ...
  "options_ui": {
    "page": "options.html",
    "open_in_tab": false
  },
  ...
}
```

![Embedded options](https://developers.google.com/static/docs/extensions/develop/ui/options-page/image/embedded-options-7de329f362ce.png)

Embedded options.

`page` (string)

Specifies the path to the options page, relative to the extension's root.

`open_in_tab` (boolean)

Indicates whether the extension's options page will be opened in a new tab. If set to `false`, the extension's options page is embedded in `chrome://extensions` rather than opened in a new tab.

## Consider the differences

Options pages embedded inside `chrome://extensions` have subtle behavior differences from options pages in tabs.

### Link to the options page

An extension can link directly to the options page by calling [`chrome.runtime.openOptionsPage()`](/docs/extensions/reference/api/runtime#method-openOptionsPage). For example, it can be added to a popup:

popup.html:

```
<button id="go-to-options">Go to options</button>
<script src="popup.js"></script>
```

popup.js:

```
document.querySelector('#go-to-options').addEventListener('click', function() {
  if (chrome.runtime.openOptionsPage) {
    chrome.runtime.openOptionsPage();
  } else {
    window.open(chrome.runtime.getURL('options.html'));
  }
});
```

### Tabs API

Because embedded options code is not hosted in a tab, the Tabs API cannot be used. Use [`runtime.connect()`](/docs/extensions/reference/api/runtime#method-connect) and [`runtime.sendMessage()`](/docs/extensions/reference/api/runtime#method-sendMessage) instead, if the options page does need to manipulate the containing tab.

### Messaging APIs

If an extension's options page sends a message using [`runtime.connect()`](/docs/extensions/reference/api/runtime#method-connect) or [`runtime.sendMessage()`](/docs/extensions/reference/api/runtime#method-sendMessage), the [sender's tab](/docs/extensions/reference/api/runtime#property-MessageSender-tab) will not be set, and the [sender's URL](/docs/extensions/reference/api/runtime#property-MessageSender-url) will be the options page URL.

### Sizing

The embedded options should automatically determine their own size based on the page content. However, the embedded box may not find a good size for some types of content. This problem is most common for options pages that adjust their content shape based on window size.

If this is an issue, provide fixed minimum dimensions for the options page to ensure that the embedded page will find an appropriate size.
