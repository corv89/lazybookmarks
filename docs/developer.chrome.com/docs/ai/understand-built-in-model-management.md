---
Source: https://developer.chrome.com/docs/ai/understand-built-in-model-management
Generated: 2026-03-03
Updated: 2026-03-03
---

![Thomas Steiner](https://web.dev/images/authors/thomassteiner.jpg)

Thomas Steiner

[GitHub](https://github.com/tomayac) [LinkedIn](https://www.linkedin.com/in/thomassteinerlinkedin) [Mastodon](https://toot.cafe/@tomayac) [Bluesky](https://bsky.app/profile/tomayac.com) [Homepage](https://blog.tomayac.com/)

Published: October 21, 2025

The [built-in AI capabilities](/docs/ai/built-in-apis) powered by Gemini Nano are designed to be seamless for both users and developers. When you use a built-in AI API, the model management happens automatically in the background. This document describes how Chrome handles Gemini Nano model downloads, updates, and purges.

## Initial model download

When a user downloads or updates Chrome, Gemini Nano is [downloaded on demand](/docs/ai/inform-users-of-model-download) to ensure Chrome downloads the correct model for the user's hardware. The initial model download is triggered by the first call to a `*.create()` function (for example, `Summarizer.create()`) of any [built-in AI API](/docs/ai/built-in-apis) that depends on Gemini Nano. When this happens, Chrome runs a series of checks to determine the best course of action. First, Chrome estimates the device's GPU performance by running a representative shader. Based on these results, it decides to either:

-   Download a larger, more capable Gemini Nano variant (such as 4B parameters).
-   Download a smaller, more efficient Gemini Nano variant (such as 2B parameters).
-   Fall back to [CPU-based inference](/blog/gemini-nano-cpu-support) if the device meets separate static requirements. If the device doesn't meet the [hardware requirements](/docs/ai/get-started#hardware), the model is not downloaded.

The download process is built to be resilient:

-   If the internet connection is interrupted, the download continues from where it left off once connectivity is restored.
-   If the tab that triggered the download is closed, the download continues in the background.
-   If the browser is closed, the download will resume on the next restart, provided the browser opens within 30 days.

Sometimes, calling `availability()` can trigger the model download. This occurs if the call happens shortly after a fresh user profile starts up and if the [Gemini Nano powered scam detection](https://security.googleblog.com/2025/05/using-ai-to-stop-tech-support-scams-in.html) feature is active.

### LoRA weights download

Some APIs, like the Proofreader API, rely on Low-Rank Adaptation (LoRA) weights that are applied to the base model to specialize its function. If the API depends on LoRA, the LoRA weights are downloaded alongside the base model. LoRA weights for other APIs are not proactively downloaded.

## Automatic model updates

Gemini Nano model updates are released on a regular basis. Chrome checks for these updates when the browser starts up. Additionally, Chrome checks for updates to supplementary resources, like LoRA weights, on a daily basis. While you can't programmatically query the model version from JavaScript, you can [manually check which version is installed](/docs/ai/debug-gemini-nano) on `chrome://on-device-internals`. The update process is designed to be seamless and non-disruptive:

-   Chrome keeps operating with the current model while downloading the new version in the background.
-   Once the updated model is downloaded, it's **hot swapped**, which means the models are switched with **no downtime**. Any new AI API call will immediately use the new model. Note: It's possible for a prompt running at the exact moment of the swap to fail.
-   Every update is a full new model download, not a partial download. This is because model weights can be significantly different between versions, and computing and applying deltas for such large files can be slow.

Updates are subject to the same requirements as the initial download. However, the initial disk space check is waived if a model is already installed. LoRA weights can also be updated. A new version of LoRA weights can be applied to an existing base model. However, a new base model version always requires a new set of LoRA weights.

## Model deletion

Chrome actively manages disk space to ensure the user doesn't run out. The Gemini Nano model is automatically deleted if the device's free disk space drops below a certain threshold. Additionally, the model is purged if an enterprise policy disables the feature, or if a user hasn't met other eligibility criteria for 30 days. Eligibility may include API usage and device capability. The purge process has the following characteristics:

-   The model can be deleted at any time, even mid-session, without regard for running prompts. This means an API that was available at the start of a session could suddenly become unavailable.
-   After being purged, the model is **not** automatically re-downloaded. A new download must be triggered by an application calling a `*.create()` function.
-   When the base model is purged, any related LoRA weights are also purged after a 30-day grace period.

## Your role in model management

Having a good understanding of the built-in AI model's lifecycle is key to getting the user experience right. You're not done with downloading the model once, you also need to be aware of the possibility of the model to suddenly disappear again under disk space pressure, or the model to be updated when a new version comes out. This is all taken care of by the browser.

By following [best practices around downloading the model](/docs/ai/inform-users-of-model-download), you'll create a good user experience on initial download, re-downloads, and updates.
