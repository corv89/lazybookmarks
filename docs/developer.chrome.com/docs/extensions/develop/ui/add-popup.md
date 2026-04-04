---
Source: https://developer.chrome.com/docs/extensions/develop/ui/add-popup
Generated: 2026-03-03
Updated: 2026-03-03
---

A popup is an action that displays a window letting users invoke multiple extension features. It's triggered by a keyboard shortcut, by clicking the extension's action icon or by calling [`chrome.action.openPopup()`](/docs/extensions/reference/api/action#method-openPopup). Popups automatically close when the user focuses on some portion of the browser outside of the popup. There is no way to keep the popup open after the user has clicked away.

The following image, taken from the [Drink Water Event](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/sample.water_alarm_notification) sample, shows a popup displaying available timer options. Users set an alarm by clicking one of the buttons.

![An example of a popup.](https://developers.google.com/static/docs/extensions/develop/ui/add-popup/image/popup.png)

An example of a popup.

Register a popup in the manifest under the `"action"` key.

```json
{
 "name": "Drink Water Event",
 ...
 "action": {
   "default_popup": "popup.html"
 }
 ...
}
```

Implement the popup as you would almost any other web page. Note that any JavaScript used in a popup must be in a separate file.

```
<html>
 <head>
   <title>Water Popup</title>
 </head>
 <body>
     <img src="./stay_hydrated.png" id="hydrateImage">
     <button id="sampleSecond" value="0.1">Sample Second</button>
     <button id="min15" value="15">15 Minutes</button>
     <button id="min30" value="30">30 Minutes</button>
     <button id="cancelAlarm">Cancel Alarm</button>
   <script src="popup.js"></script>
 </body>
</html>
```

You can also create popups dynamically by calling [`action.setPopup()`](/docs/extensions/reference/api/action#method-setPopup).

```javascript
chrome.storage.local.get('signed_in', (data) => {
  if (data.signed_in) {
    chrome.action.setPopup({popup: 'popup.html'});
  } else {
    chrome.action.setPopup({popup: 'popup_sign_in.html'});
  }
});
```
