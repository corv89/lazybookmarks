---
Source: https://developer.chrome.com/docs/extensions/develop/ui
Generated: 2026-03-03
Updated: 2026-03-03
---

This is a catalog of user interface elements available in extensions. Each entry contains:

-   An image of the element (if applicable).
-   A description of what it's for.
-   Related interface elements (if applicable).
-   Links to implementation instructions and code samples.

These elements are different ways of invoking extension features. You're not required to implement all of them. In fact, some use cases might not use any of them. For example, a link shorter could act on the displayed URL using a keyboard shortcut and put the shortened link into the clipboard programmatically.

## Actions

An action is what happens when a user clicks the [action icon](#action-icons) for your extension. An action can either [invoke an extension feature](/docs/extensions/reference/api/action#event-onClicked) using the [Action API](/docs/extensions/reference/api/action) or open a [popup](#popups) that lets users invoke multiple extension features. Tell users what the action does using a [tooltip](#tooltips).

![Both a pinned extension and an unpinned extension.](https://developers.google.com/static/docs/extensions/develop/ui/image/pinned-unpinned.png)

**Figure 1**: Pinned (left) and unpinned (right) extensions.

To learn to build an action, see [Implement an action](/docs/extensions/reference/api/action#concepts_and_usage), or examine the [action samples](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/action).

## Action icons

An extension requires at least one icon to represent it. Users click the icon to invoke an [action](#actions), whether that action [invokes an extension feature](/docs/extensions/reference/api/action?#event-onClicked) using the [Action API](/docs/extensions/reference/api/action) or opens a [popup](#popups).

![The icon for the Google dictionary extension.](https://developers.google.com/static/docs/extensions/develop/ui/image/icon.png)

**Figure 2**: Icon for the Google dictionary extension (in red).

You can also add a label, here called a 'badge', to the icon to communicate such things as extension state or that actions are required by the user.

To learn to build an action, see [Implement an action](/docs/extensions/reference/api/action#concepts_and_usage), or examine the [action samples](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/action).

## Badges

Badges are bits of formatted text placed on top of the [action icon](#action-icons) to indicate such things as extension state or that actions are required by the user. You can set the text of the badge by calling [chrome.action.setBadgeText()](/docs/extensions/reference/api/action#method-setBadgeText) and the banner color by calling [chrome.action.setBadgeBackgroundColor()](/docs/extensions/reference/api/action#method-setBadgeBackgroundColor).

![An extension icon without a badge and with a badge.](https://developers.google.com/static/docs/extensions/develop/ui/image/badges.png)

**Figure 3**: An extension icon without a badge (left) and with a badge (right).

To learn to build an action, see [Implement an action](/docs/extensions/reference/api/action#concepts_and_usage), or the [Drink water](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/sample.water_alarm_notification) sample.

## Commands

Commands are key combinations that invoke an extension feature. Define key combinations in the manifest.json file and respond to them using the [Commands API](/docs/extensions/reference/api/commands). To learn to implement a command, see [the API reference](/docs/extensions/reference/api/commands#usage), or the [`chrome.commands`](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/default_command_override) sample.

## Context menu

A context menu appears for the alternate click (frequently called the right click) of a mouse. Define context menus using the [Context Menus API](/docs/extensions/reference/api/contextMenus).

![A nested context menu.](https://developers.google.com/static/docs/extensions/develop/ui/image/context-menu-nested.png)

**Figure 4**: A context menu and a nested sub menu.

To learn to implement a context menu, see the [context menu](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/contextMenus) samples.

## Omnibox

You can interact with users using the Chrome omnibox. When a user enters extension-defined keywords in the omnibox, your extension controls what the user sees in the omnibox. Define keywords in the [manifest.json](/docs/extensions/reference/manifest) and respond to them using the [Omnibox API](/docs/extensions/reference/api/omnibox).

![The browser's omnibox.](https://developers.google.com/static/docs/extensions/develop/ui/image/omnibox.png)

**Figure 5**: The browser's omnibox.

To learn to override the omnibox, see Trigger actions from the omnibox, or the [quick API reference](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/functional-samples/tutorial.quick-api-reference) sample.

## Override pages

An extension can override one of these built-in Chrome pages:

-   History
-   New tab
-   Bookmarks

![An example of a custom history page.](https://developers.google.com/static/docs/extensions/develop/ui/image/custom-history.png)

**Figure 6**: An example of a custom history page.

To learn to override Chrome pages, see [Override Chrome pages](/docs/extensions/develop/ui/override-chrome-pages), or the [override](https://github.com/GoogleChrome/chrome-extensions-samples/blob/main/api-samples/override/blank_ntp/README.md) sample.

## Popups

A popup is an [action](#actions) that displays a window letting users invoke multiple extension features. Popups can be opened if the user clicks the [action icon](#action-icons), via a keyboard shortcut or by calling [`chrome.action.openPopup()`](/docs/extensions/reference/api/action#method-openPopup).

![An example of a popup.](https://developers.google.com/static/docs/extensions/develop/ui/image/popup.png)

**Figure 7**: An example of a popup.

To learn to build a popup, see, [Add a popup](/docs/extensions/develop/ui/add-popup). You can also download a step through one of the [action samples](https://github.com/GoogleChrome/chrome-extensions-samples/tree/main/api-samples/action).

## Side panels

A side panel lets users invoke extension features alongside web pages (see the image). A side panel can attach to a single tab or to a whole window. A side panel is controlled using the [Side Panel API](/docs/extensions/reference/api/sidePanel).

![Dictionary extension defining the word ](https://developers.google.com/static/docs/extensions/develop/ui/image/dictionary-side-panel.png)

**Figure 8**: Dictionary extension defining the word "Extensions".

To learn to build a side panel, see the [side panel use cases](/docs/extensions/reference/api/sidePanel#use-cases), or examine the side panel samples.

## Tooltips

A tooltip is a way to show, when a user hovers a mouse of your [action icon](#action-icons), what your extension's [action](#actions) does. By default, the tooltip displays the name of the extension.

![An example tooltip for an action icon.](https://developers.google.com/static/docs/extensions/develop/ui/image/tooltip.png)

**Figure 9**: An example tooltip for an action icon.

To learn to add a tooltip, use the [`"default_title"`](/docs/extensions/reference/api/action#manifest) member of the manifest files `"action"` key.

## DevTools

You can add custom panels (what tabs are called in DevTools) to DevTools using the [DevTools Panels API](/docs/extensions/reference/api/devtools/panels). Other DevTools APIs let you monitor [windows](/docs/extensions/reference/api/devtools/inspectedWindow) and [network traffic](/docs/extensions/reference/api/devtools/network). You can also customize the DevTools [recorder panel](/docs/extensions/reference/api/devtools/recorder). Chrome DevTools' own Lighthouse panel started life as a DevTools extension.

## Notifications

Post messages to a user's system tray using either the extensions [Notifications API](/docs/extensions/reference/api/notifications) or the web platforms [Notifications API](https://developer.mozilla.org/docs/Web/API/Notifications_API).

![An extension notification on mac.](https://developers.google.com/static/docs/extensions/develop/ui/image/mac-os-notification.png)

**Figure 10**: An extension notification on mac.

To learn to use notifications, see [Notify users](/docs/extensions/how-to/ui/notifications).

## Themes

A theme is a special kind of extension that changes the way the browser looks. Themes are packaged like regular extensions, but they don't contain JavaScript or HTML code.

![](https://developers.google.com/static/docs/extensions/develop/ui/image/themes.png)

**Figure 11**: An example theme.

To learn to build a theme, see [What are themes?](/docs/extensions/develop/ui/themes).

## Other ways of interacting with users

This section describes other ways that your extension can interact with users. Although not strictly needed for a basic extension, they can be important parts of your extension. For many users, some of these features are absolutely essential to using the extension.

### Accessibility

For many users, accessibility literally is the user interface, and its features can often be useful to those who don't need accessibility as a primary means of interacting with your extension. Learn the basics of [making your extension accessible](/docs/extensions/develop/ui/a11y).

### Internationalization

Speak to users in their own language. Learn to [internationalize the interface](/docs/Extensions/develop/ui/i18n).
