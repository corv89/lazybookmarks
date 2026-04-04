---
Source: https://developer.chrome.com/docs/extensions/develop/ui/respond-to-commands
Generated: 2026-03-03
Updated: 2026-03-03
---

Commands are key combinations that invoke an extension feature. Register commands in the manifest under the `"commands"` key. For example:

```json
{
  "name": "Open developer.chrome.com",
  "version": "0.1",
  "manifest_version": 3,
  "description": "Opens developer.chrome.com when you use Cmd/Ctrl + Shift + Z",
  "background": {
    "service_worker": "background.js"
  },
  "commands": {
   "open-tab": {
     "suggested_key": {
       "default": "Ctrl+Shift+Z",
       "mac": "Command+Shift+Z"
     },
     "description": "Open developer.chrome.com"
   }
  }
}
```

This key combination triggers the [`commands.onCommand`](/docs/extensions/reference/api/commands#event-onCommand) event in the [service worker](/docs/extensions/develop/concepts/service-workers/basics).

```javascript
chrome.commands.onCommand.addListener((command) => {
  if (command !== "open-tab") return;
  chrome.tabs.create({ url: "https://developer.chrome.com" });
});
```

To see responding to commands in action, download the The [Tab Flipper](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/default_command_override) sample and [load it unpacked](https://developer.chrome.com/docs/extensions/get-started/tutorial/hello-world#load-unpacked).
