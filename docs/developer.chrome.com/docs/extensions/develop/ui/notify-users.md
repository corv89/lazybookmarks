---
Source: https://developer.chrome.com/docs/extensions/develop/ui/notify-users
Generated: 2026-03-03
Updated: 2026-03-03
---

Post messages to a user's system tray using the extensions [Notifications API](/docs/extensions/reference/notifications). Start by declaring the `"notifications"` permission in the manifest.json.

```json
{
  "name": "Drink Water Event Popup",
...
  "permissions": [
    "notifications",
  ],
...
}
```

Once the permission is declared, display a notification by calling [`notifications.create()`](/docs/extensions/reference/notifications#method-create). The following example is taken from the [Drink water event popup](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/sample.water_alarm_notification) sample. It uses an alarm to set a reminder to drink a glass of water. This code shows the triggering of the alarm. Follow the previous link to explore how this is set up.

```javascript
chrome.alarms.onAlarm.addListener(() => {
  chrome.action.setBadgeText({ text: '' });
  chrome.notifications.create({
    type: 'basic',
    iconUrl: 'stay_hydrated.png',
    title: 'Time to Hydrate',
    message: "Everyday I'm Guzzlin'!",
    buttons: [{ title: 'Keep it Flowing.' }],
    priority: 0
  });
});
```

This code creates a notification on macOS like the following.

![A notification on macOS](https://developers.google.com/static/docs/extensions/develop/ui/notify-users/images/notification.png)

A notification on macOS.
