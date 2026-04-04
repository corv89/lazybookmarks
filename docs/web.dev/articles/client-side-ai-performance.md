---
Source: https://web.dev/articles/client-side-ai-performance
Generated: 2026-03-03
Updated: 2026-03-03
---

![Maud Nalpas](https://web.dev/images/authors/maudn.jpg)

Maud Nalpas

[X](https://twitter.com/maudnals) [GitHub](https://github.com/maudnals)

**Important:** This document doesn't cover [Chrome's built-in AI](https://developer.chrome.com/docs/ai/built-in), which also perform client-side inference. Built-in AI relies on APIs and models built into the browser, downloaded on-demand to be used by any web application.

While most AI features on the web rely on servers, client-side AI runs directly in the user's browser. This offers many benefits, including low latency, reduced server-side costs, no API key requirements, increased user privacy, and offline access. You can implement client-side AI that works across browsers with JavaScript libraries like [TensorFlow.js](https://www.tensorflow.org/js), [Transformers.js](https://huggingface.co/docs/transformers.js/), and [MediaPipe GenAI](https://www.npmjs.com/package/@mediapipe/tasks-genai).

Client-side AI also introduces performance challenges: users have to download more files, and their browser has to work harder. To make it work well, consider:

-   **Your use case**. Is client-side AI the right pick for your feature? Is your feature on a critical user journey, and if so, do you have a fallback?
-   **Good practices for model download and usage**. Keep reading to learn more.

## Before model download

### Mind library and model size

To implement client-side AI you'll need a model and usually a library. When choosing the library, assess its size like you would any other tool.

Model size matters, too. What's considered large for an AI model depends. 5MB can be a useful rule of thumb: it's also the [75th percentile of the median web page size](https://httparchive.org/reports/page-weight?lens=top10k&start=2018_09_15&end=latest&view=list#bytesTotal). A laxer number would be [10MB](https://developer.android.com/guide/playcore/feature-delivery/ux-guidelines#:%7E:text=are%20relatively%20small%20\(-,less%20than%2010MB,-\)%2C%20and%20there%20aren%27t).

Here are some important considerations about model size:

-   **Many -specific AI models can be really small**. A model like [BudouX](https://github.com/google/budoux), for accurate character breaking in Asian languages, is only 9.4KB GZipped. MediaPipe's [language detection model](https://ai.google.dev/edge/mediapipe/solutions/text/language_detector#language_detector_model_recommended:%7E:text=This%20model%20is%20built%20to%20be%20lightweight%20%28315%20KB%29) is 315KB.
-   **Even vision models can be reasonably sized**. The [Handpose](https://storage.googleapis.com/tfjs-models/demos/handtrack/index.html) model and all related resources total 13.4MB. While this is much larger than most minified frontend packages, it's comparable to the median web page, which is [2.2MB](https://httparchive.org/reports/page-weight?lens=top10k&start=2018_09_15&end=latest&view=list#bytesTotal) ([2.6MB](https://httparchive.org/reports/page-weight?lens=top10k&start=2018_09_15&end=latest&view=list#bytesTotal) on desktop).
-   **Gen AI models can exceed the recommended size for web resources**. [DistilBERT](https://huggingface.co/docs/transformers/en/model_doc/distilbert), which is considered either a very small LLM or a simple NLP model (opinions vary), weighs in at 67MB. Even small LLMs, such as [Gemma 2B](https://www.kaggle.com/models/google/gemma/tfLite), can reach 1.3GB. This is over 100 times the size of the median web page.

**Note:** For LLMs specifically, read [Understand LLM sizes](/articles/llm-sizes).

You can assess the exact download size of the models you're planning to use with your browsers' developer tools.

![](https://developers.google.com/static/articles/client-side-ai-performance/image/lang-detection-fetch.png)

In the Chrome DevTools Network panel, download size for the MediaPipe language detection model. Demo.

![](https://developers.google.com/static/articles/client-side-ai-performance/image/model-size-mediapipe.png)

In the Chrome DevTools Network panel, download size for Gen AI models: Gemma 2B (Small LLM), DistilBERT (Small NLP / Very small LLM).

### Optimize model size

-   **Compare model quality and download sizes**. A smaller model may have sufficient accuracy for your use case, while being much smaller. Fine tuning and [model shrinking techniques](/articles/llm-sizes#model-shrinking) exist to significantly reduce a model's size while maintaining sufficient accuracy.
-   **Pick specialized models** when possible. Models that are tailored to a certain  tend to be smaller. For example, if you're looking to perform specific tasks like sentiment or toxicity analysis, use models specialized in these tasks rather than a generic LLM.

![](https://developers.google.com/static/articles/client-side-ai-performance/image/model-selection.png)

Model selector for a [client-side AI-based transcription demo](https://jordismit.com/tools/ai-based-transcription-in-the-browser/) by [j0rd1smit](https://github.com/j0rd1smit).

While all these models perform the same , with varying accuracy, their sizes vary widely: from 3MB to 1.5GB.

### Check if the model can run

Not all devices can run AI models. Even devices that have sufficient hardware specs may struggle, if other expensive processes are running or are started while the model is in use.

**Note:** As of today, there isn't a way to know ahead of download if a model can run on your user's device. One solution is under discussion in [MediaPipe Gen AI](https://github.com/google-ai-edge/mediapipe/issues/5468) and [Transformers.js](https://github.com/microsoft/onnxruntime/issues/20998). You can show support by upvoting or commenting on the issues where this solution is discussed.

Until a solution is available, here's what you can do today:

-   **Check for WebGPU support**. Several client-side AI libraries including Transformers.js version 3 and [MediaPipe](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/web_js#browser_compatibility) use WebGPU. At the moment, some of these libraries don't automatically fallback to Wasm if WebGPU isn't supported. You can mitigate that by enclosing your AI-related code within a [WebGPU feature detection check](https://gpuweb.github.io/gpuweb/#example-abcf3590), if you know that your client-side AI library needs WebGPU.
-   **Rule out underpowered devices**. Use [Navigator.hardwareConcurrency](https://developer.mozilla.org/docs/Web/API/Navigator/hardwareConcurrency), [Navigator.deviceMemory](https://developer.mozilla.org/docs/Web/API/Navigator/deviceMemory) and the [Compute Pressure API](https://developer.mozilla.org/docs/Web/API/Compute_Pressure_API) to estimate device capabilities and pressure. These APIs are not supported in all browsers and are intentionally [imprecise](https://www.w3.org/TR/device-memory/#computing-device-memory-value) to prevent fingerprinting, but they can still help rule out devices that seem very underpowered.

### Signal large downloads

For large models, warn users before downloading. Desktop users are more likely to be OK with large downloads than mobile users. To detect mobile devices, use [`mobile`](https://developer.mozilla.org/docs/Web/API/NavigatorUAData/mobile) from the User-Agent Client Hints API (or the User-Agent string if UA-CH is unsupported).

**Note:** The [`Save-Data` HTTP Header](https://developer.mozilla.org/docs/Web/HTTP/Headers/Save-Data) or the user's [connection type](https://developer.mozilla.org/docs/Web/API/NetworkInformation/effectiveType) can be useful to assess whether the user is likely to be okay with large downloads. But they're not widely supported across browsers, and to protect users' privacy, the connection type won't actually indicate whether the user is on Wifi or data.

### Limit large downloads

-   **Only download what's necessary**. Especially if the model is large, download it only once there's reasonable certainty the AI features will be used. For example, if you have a type-ahead suggestion AI feature, only download when the user starts using typing features.
-   [**Explicitly cache the model**](https://developer.chrome.com/docs/ai/cache-models) on the device using the [Cache API](https://developer.mozilla.org/docs/Web/API/Cache), to avoid downloading it at every visit. Don't just rely on the implicit HTTP browser cache.
-   **Chunk the model download**. [fetch-in-chunks](https://www.npmjs.com/package/fetch-in-chunks) splits a large download into smaller chunks.

## Model download and preparation

### Don't block the user

Prioritize a smooth user experience: allow key features to function even if the AI model isn't fully loaded yet.

![Ensure users can still post.](https://developers.google.com/static/articles/client-side-ai-performance/image/post-review-before-model-ready.gif)

Users can still post their review, even when the client-side AI feature isn't ready yet. Demo by [@maudnals](https://x.com/maudnals).

### Indicate progress

As you download the model, indicate progress completed and time remaining.

-   If model downloads are handled by your client-side AI library, use the download progress status to display it to the user. If this feature isn't available, consider opening an issue to request it (or contribute it!).
-   If you handle model downloads in your own code, you can fetch the model in chunks using a library, such as [fetch-in-chunks](https://github.com/tomayac/fetch-in-chunks?tab=readme-ov-file#with-progress-callback), and display download progress to the user.
    -   For more advice, refer to [Best practices for animated progress indicators](https://www.smashingmagazine.com/2016/12/best-practices-for-animated-progress-indicators/) and [Designing for long waits and interruptions](https://www.nngroup.com/articles/designing-for-waits-and-interruptions/).

![](https://developers.google.com/static/articles/client-side-ai-performance/image/mediapipe-download.png)

Model download progress display. Custom implementation with [fetch-in-chunks](https://github.com/tomayac/fetch-in-chunks?tab=readme-ov-file#with-progress-callback). [Demo](https://mediapipe-llm.glitch.me/) by [@tomayac](https://twitter.com/tomayac).

### Handle network interruptions gracefully

Model downloads can take different amounts of time, depending on their size. Consider how to handle network interruptions if the [user goes offline](/articles/offline-ux-design-guidelines). When possible, inform the user of a broken connection, and continue the download when the connection is restored.

Flaky connectivity is another reason to download in chunks.

**Note:** The [Background Fetch API](https://developer.chrome.com/blog/background-fetch) provides a method for managing downloads that may take a long time, even with network interruptions, but it's only supported in Chrome.

### Offload expensive tasks to a web worker

Expensive tasks, for example model preparation steps after download, can block your main thread, causing a jittery user experience. Moving these tasks over to a web worker helps.

Find a demo and full implementation based on a web worker:

-   [script.js](https://github.com/GoogleChromeLabs/web-ai-demos/tree/main/perf-worker-gemma/src/script.js#L16)
-   [worker.js](https://github.com/GoogleChromeLabs/web-ai-demos/tree/main/perf-worker-gemma/src/worker.js)

![Performance trace in Chrome DevTools.](https://developers.google.com/static/articles/client-side-ai-performance/image/perf-gemma-worker.png)

Top: With a web worker. Bottom: No web worker.

## During inference

Once the model is downloaded and ready, you can run inference. Inference can be computationally expensive.

**Key Term:** [*Inference*](https://developer.nvidia.com/topics/ai/ai-inference#:%7E:text=AI%20inference%20is%20the%20process%20of%20generating%20outputs%20from%20a%20model%20by%20providing%20it%20inputs) is essentially model thinking time: it's when the model generates outputs from a provided input. For example, if you gave your model a user-written product review, inference occurs when the model generates text that completes the user's review or analyzes the sentiment of the review.

### Move inference to a web worker

If inference occurs through WebGL, WebGPU or WebNN, it relies on the GPU. This means it occurs in a separate process that doesn't block the UI.

But for CPU-based implementations (such as Wasm, which can be a fallback for WebGPU, if WebGPU is unsupported), moving inference to a web worker keeps your page responsive—just like during model preparation.

Your implementation may be simpler if all your AI-related code (model fetch, model preparation, inference) lives in the same place. So, you may choose a web worker, whether or not the GPU is in use.

### Handle errors

Even though you've checked that the model should run on the device, the user may start another process that extensively consumes resources later on. To mitigate this:

-   **Handle inference errors**. Enclose inference in `try`/`catch` blocks, and handle corresponding runtime errors.
-   **Handle WebGPU errors**, both [unexpected](https://gpuweb.github.io/gpuweb/#dom-gpudevice-onuncapturederror) and [GPUDevice.lost](https://gpuweb.github.io/gpuweb/#dom-gpudevice-lost), which occurs when the GPU is actually reset because the device struggles.

### Indicate inference status

If inference takes more time than what would feel [immediate](https://www.nngroup.com/articles/response-times-3-important-limits/), signal to the user that the model is thinking. Use animations to ease the wait and ensure the user that the application is working as intended.

![Example animation during inference.](https://developers.google.com/static/articles/client-side-ai-performance/image/animation-ai.gif)

Demo by [@maudnals](https://x.com/maudnals) and [@argyleink](https://x.com/argyleink)

### Make inference cancellable

Allow the user to refine their query on the fly, without the system wasting resources generating a response the user will never see.
