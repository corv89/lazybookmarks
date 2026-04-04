---
Source: https://ai.google.dev/edge/mediapipe/solutions/setup_web
Generated: 2026-03-03
Updated: 2026-03-03
---

This page shows you how to set up your development environment to use MediaPipe Tasks in your JavaScript web applications.

## Supported platforms and versions

To create web applications with MediaPipe Tasks, your development environment requires the following:

-   Chrome or Safari browser
-   A web application that uses Node.js and NPM. Alternatively, you can use script tags to access MediaPipe Tasks through a content delivery network (CDN).

## MediaPipe Tasks dependencies

MediaPipe Tasks provides three prebuilt libraries for vision, text, and audio. Depending on the MediaPipe Task used by the app, import the vision, text, or audio library into your development project.

**Attention:** This MediaPipe Solutions Preview is an early release. [Learn more](/edge/mediapipe/solutions/about#notice).

### Generative AI tasks

The MediaPipe Tasks Generative AI module contains tasks that handle image or text generation. To import the MediaPipe Tasks Generative AI libraries, import the following dependencies into your development project.

#### LLM Inference API

The MediaPipe LLM Inference  is contained within the `tasks-genai` library.

```
npm install @mediapipe/tasks-genai
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/), to add code directly to your HTML page.

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai/genai_bundle.cjs"
    crossorigin="anonymous"></script>
</head>
```

### Vision tasks

The MediaPipe Tasks vision module contains tasks that handle image or video inputs. To import the MediaPipe Tasks vision library, import the following dependency to your into your development project.

```
npm install @mediapipe/tasks-vision
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/), to add code directly to your HTML page.

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision/vision_bundle.mjs"
    crossorigin="anonymous"></script>
</head>
```

### Text tasks

The MediaPipe Tasks text module contains tasks that handle string inputs. To import the MediaPipe Tasks text library, import the following dependency to your into your development project.

```
npm install @mediapipe/tasks-text
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/), to add code directly to your HTML page.

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text/text_bundle.js"
    crossorigin="anonymous"></script>
</head>
```

### Audio tasks

The MediaPipe Tasks audio module contains tasks that handle sound inputs. To import the MediaPipe Tasks audio library, import the following dependency to your into your development project.

```
npm install @mediapipe/tasks-audio
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/), to add code directly to your HTML page.

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-audio/audio_bundle.js"
    crossorigin="anonymous"></script>
</head>
```

## BaseOptions configuration

The BaseOptions allow for general configuration of MediaPipe Task APIs.

| Option name | Description | Accepted values |
| --- | --- | --- |
| modelAssetBuffer | The model asset file contents as a Uint8Array typed array. | Uint8Array |
| modelAssetPath | The path of the model asset to open and map into memory. | TrustedResourceUrl |
| Delegate | Enables hardware acceleration through a device delegate to run the MediaPipe pipeline. Default value: CPU. | [CPU, , GPU] |

## Troubleshooting

For help with technical questions related to MediaPipe, visit the [discussion group](https://groups.google.com/forum/#!forum/mediapipe) or [Stack Overflow](https://stackoverflow.com/questions/tagged/mediapipe) for support from the community. To report bugs or make feature requests, [file an issue on GitHub](https://github.com/google/mediapipe/issues).
