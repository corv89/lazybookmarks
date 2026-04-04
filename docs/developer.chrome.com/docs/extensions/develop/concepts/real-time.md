---
Source: https://developer.chrome.com/docs/extensions/develop/concepts/real-time
Generated: 2026-03-03
Updated: 2026-03-03
---

Real-time updates provide an instant communication path from your servers directly to your extension installations. You can send and receive data as events happen. Whether you use it for instant messaging, triggering background tasks, or syncing device data, it is a critical operation with a number of modern services. There are a number of options to have real-time communication in Chrome extensions.

-   [Web Push](/docs/extensions/how-to/integrate/web-push), or the Push API, is a web standard that lets you send and receive messages in a Chrome extensions from any [Push provider](/docs/extensions/how-to/integrate/web-push#push_providers_and_push_services), or even with your own web server.
-   [chrome.gcm](/docs/extensions/how-to/integrate/chrome.gcm) is a legacy extension specific API that lets you send and receive messages using Firebase Cloud Messaging.
-   [WebSockets](/docs/extensions/how-to/web-platform/websockets) is a low-level protocol that lets you to open a bidirectional connection between your Chrome extension and your server.

## Common scenarios

Here are some common scenarios in Chrome extensions where real-time communication is critical:

### Keep users up-to-date with changes.

If you are syncing files, settings, or other pieces of information between multiple users then Web Push is the perfect way to send silent updates to your extension to let it know to update the state from the server.

Are you letting users report bugs or issues? You can integrate with a Push provider to let them know as soon as you have an update to share, directly in your extension.

### Send notifications to users.

While you can send notifications [completely client side](/docs/extensions/reference/api/notifications), if you have server side logic for who, what, where or when to send a notification than Web Push is the most future proof option.

For sending messages to a only a subset of users, then Push is the best choice. While Firebase Cloud Messaging does offer [Topics](https://firebase.google.com/docs/cloud-messaging/js/topic-messaging) (also known as channels), it is only available in their HTTP Cloud Messaging API. This is different from the legacy version that `chrome.gcm` uses. If you want to send broad messages to all users, including those on legacy versions of Chrome (pre Chrome 121), then `chrome.gcm` is the ideal option. Built on the Legacy Firebase messaging APIs, `chrome.gcm` has been supported in Chrome for over a decade.

You can use Web Push or `chrome.gcm` to send notifications to users when something important to their account happens, such as when a new message arrives or when a file is shared.

### Instant Messaging

Need frequent, two way communication? Then a web socket may be the best option for you. It opens a bidirectional connection between your extension and your server (or even directly to other users). It lets you exchange data and messages in real time. While they are a great option on the web in general, they have [some limitations with extensions](#web-socket-issues) that you need to keep in mind if you plan on using them.

In the rest of this guide we will take a closer look at the available options.

## Push notifications with the Push API

Using the [Push API](https://developer.mozilla.org/docs/Web/API/Push_API) you can use any Push provider to send push notifications and messages. A push from the Push API will be processed by your service worker as soon as it is received. If the extension has been suspended, a Push will wake it back up. [The process to use it in extensions](/docs/extensions/how-to/integrate/web-push) is exactly the same as what you would use it on the open web.

## Push notifications with chrome.gcm

The [chrome.gcm](/docs/extensions/reference/api/gcm) API provides a direct connection to Firebase Cloud Messaging (FCM), a service for sending real-time updates to web applications and mobile apps. This is a Chrome specific extension API that was added many years before [Push](https://developer.mozilla.org/docs/Web/API/Push_API) was available in browsers. It was built using Firebase's (now deprecated) [legacy HTTP APIs](https://firebase.google.com/docs/cloud-messaging/migrate-v1). While those APIs are deprecated elsewhere, they *are not* deprecated in extensions. They will continue to work for the foreseeable future. However, being this is the legacy push backend, it does lack features like [Topics](https://firebase.google.com/docs/cloud-messaging/js/topic-messaging).

While a FCM backend service is a hard requirement for notifications to reach users in Chrome, you don't need to use `chrome.gcm` in order to send messages. All Push providers are able to send and receive messages and events to a Firebase account using the web Push. While this is still a fully supported Chrome Extension API, it is best practice is to prefer web standards like the [Push API](#pushing-notifications) to extension specific ones like this. If your use case is best served with chrome.gcm, there is a [detailed how-to](/docs/extensions/how-to/integrate/chrome.gcm) on how to set up chrome.gcm from scratch.

## Real time messages with WebSockets

[WebSockets](https://developer.mozilla.org/docs/Web/API/WebSockets_API) have been a cornerstone of real time messaging on the web for over a decade. They have been the goto option for real time events on the web, providing a continuous, bi-directional conversation. WebSockets work in [a variety of extension components](/docs/extensions/how-to/web-platform/websockets), be it [content scripts](/docs/extensions/develop/concepts/content-scripts), [popups](/docs/extensions/reference/api/action#show_a_popup), [sidepanels](/docs/extensions/reference/api/sidePanel), and or [background service workers](/docs/extensions/develop/concepts/service-workers). While they are a great option on the web in general, they have some limitations with extensions that you need to keep in mind if you plan on using them.

### Not great for push notifications

Since WebSockets run in the web platform, rather than using an extension platform API like `chrome.gcm`, Chrome has no way to wake up your extension when a Websocket connection is started outside of your extension.

### Active connections only

Chrome suspends extensions that are not being used after 30 seconds. A number of heuristics goes into Chrome determining if the extension is "being used", one of which is an active WebSocket connection. Chrome won't suspend an extension that has sent or received a WebSocket message in the last 30 seconds. If you are using WebSockets in your extension, and need to ensure that is isn't closed prematurely, you can send a [heartbeat](https://developer.mozilla.org/docs/Web/API/WebSockets_API/Writing_WebSocket_servers#pings_and_pongs_the_heartbeat_of_websockets) message to maintain the connection. This involves sending periodic messages to the server, letting both it and Chrome know that you are still active. An example of how to keep a websocket alive indefinitely is available in our [WebSocket documentation](/docs/extensions/how-to/web-platform/websockets).
