---
Source: https://developer.chrome.com/docs/extensions/develop/ui/implement-action
Generated: 2026-03-03
Updated: 2026-03-03
---

An action is what happens when a user clicks the toolbar icon, usually called the [action icon](/docs/extensions/develop/ui#action-icons) for your extension. An action [invokes an extension feature](/docs/extensions/reference/api/action?#event-onClicked) using the [Action API](/docs/extensions/reference/api/action) or opens a [popup](/docs/extensions/develop/ui#popups). This page shows how to invoke an extension feature. To use a popup, see [Add a popup](/docs/extensions/develop/ui/add-popup).

## Register the action

To use the [`chrome.action` API](/docs/extensions/reference/api/action), add the `"action"` key to the the extension's [manifest](/docs/extensions/reference/manifest) file. See the [manifest section](/docs/extensions/reference/action#manifest) of the `chrome.action` API reference for a full description of the optional properties of this field.

manifest.json:

```json
{
  "name": "My Awesome action Extension",
 ...
  "action": {
   ...
  }
 ...
}
```

## Respond to the action

Register an [`onClicked` handler](/docs/extensions/reference/action#event-onClicked) for when the user clicks the action icon. This event is not triggered if a popup is registered in the manifest.json file.

service-worker.js:

```javascript
chrome.action.onClicked.addListener((tab) => {
  chrome.action.setTitle({
    tabId: tab.id,
    title: `You are on tab: ${tab.id}`});
});
```

## Activate the action conditionally

The [`chrome.declarativeContent` API](/docs/extensions/reference/api/declarativeContent) lets you enable the extension's action icon based on the page URL or when CSS selectors match the elements on the page. When an extension's action icon is disabled, the icon is grayed out. If the user clicks the disabled icon, the extension's context menu appears.

![A disabled action icon](https://developers.google.com/static/docs/extensions/develop/ui/implement-action/images/disabled-extension.png)

A disabled action icon.

## Action badge

Badges are bits of formatted text placed on top of the action icon to indicate such things as extension state or that actions are required by the user. To demonstrate this, the [Drink Water](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/sample.water_alarm_notification) sample displays a badge with "ON" to show the user they have successfully set an alarm and displays nothing when the extension is idle. Badges can contain up to four characters.

![An extension icon without a badge and with a badge.](https://developers.google.com/static/docs/extensions/develop/ui/implement-action/images/badges.png)

An extension icon with a badge (left) and without a badge (right).

Set the text of the badge by calling [`chrome.action.setBadgeText()`](/docs/extensions/reference/api/action#method-setBadgeText) and the background color by calling [`chrome.action.setBadgeBackgroundColor()`\`](/docs/extensions/reference/api/action#method-setBadgeBackgroundColor).

service-worker.js:

```
chrome.action.setBadgeText({text: 'ON'});
chrome.action.setBadgeBackgroundColor({color: '#4688F1'});
```

## Tooltip

Register tooltips in the `"default_title"` field under the `"action"` key in the manifest.json file.

manifest.json:

```json
{
  "name": "Tab Flipper",
 ...
  "action": {
    "default_title": "Press Ctrl(Win)/Command(Mac)+Shift+Right/Left to flip tabs"
  }
...
}
```

You can also set or update tooltips by calling [`action.setTitle()`\`](/docs/extensions/reference/api/action#method-setTitle). If no tooltip is set, the name of the extension displays.
