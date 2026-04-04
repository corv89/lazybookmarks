---
Source: https://developer.chrome.com/docs/extensions/develop/ui/omnibox-triggers
Generated: 2026-03-03
Updated: 2026-03-03
---

You can allow users to interact with your extension through the Chrome omnibox (usually called the address bar). When a user enters extension-defined keywords in the omnibox, your extension controls what the user sees in the omnibox. The [Omnibox New Tab Search](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/omnibox/new-tab-search) sample extension uses "nt" as the keyword. When the user types "nt" into the omnibox, it activates the extension. To signal this to the user, it grayscales the provided 16 by 16 icon and displays it in the omnibox next to the extension name.

![](https://developers.google.com/static/docs/extensions/develop/ui/omnibox-triggers/images/omnibox.png)

An example of using the ominibox to trigger an action.

The entered text causes Chrome to send an event to the [`omnibox.onInputEntered`](/docs/extensions/reference/omnibox#event-onInputEntered) event handler. In the handler, the extension opens a new tab containing a Google Search for the user's entry.

```javascript
chrome.omnibox.onInputEntered.addListener((text) => {
  // Encode user input for special characters , / ? : @ & = + $ #
  const newURL = `https://www.google.com/search?q=${encodeURIComponent(text)}`;
  chrome.tabs.create({ url: newURL });
});
```
