---
Source: https://ai.google.dev/edge/mediapipe/solutions/text/language_detector/web_js
Generated: 2026-03-03
Updated: 2026-03-03
---

The MediaPipe Language Detector  lets you identify the language of a piece of text. These instructions show you how to use the Language Detector for web and JavaScript apps. The code sample described in these instructions is available on [GitHub](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/language_detector/js/).

You can see this  in action by viewing the [demo](https://mediapipe-studio.webapps.google.com/demo/language_detector). For more information about the capabilities, models, and configuration options of this , see the [Overview](https://ai.google.dev/edge/mediapipe/solutions/text/language_detector/index).

## Code example

The example code for Language Detector provides a complete implementation of this  in JavaScript for your reference. This code helps you test this  and get started on building your own language detector feature. You can view, run, and edit the [Language Detector example code](https://codepen.io/mediapipe-preview/pen/RweLdpK) using just your web browser.

## Setup

This section describes key steps for setting up your development environment and code projects specifically to use Language Detector. For general information on setting up your development environment for using MediaPipe tasks, including platform version requirements, see the [Setup guide for Web](/mediapipe/solutions/setup_web).

### JavaScript packages

Language Detector code is available through the [`@mediapipe/tasks-text`](https://www.npmjs.com/package/@mediapipe/tasks-text) package. You can find and download these libraries from links provided in the platform [Setup guide](/mediapipe/solutions/setup_web).

**Attention:** This MediaPipe Solutions Preview is an early release. [Learn more](/edge/mediapipe/solutions/about#notice).

You can install the required packages with the following code for local staging using the following command:

```
npm install @mediapipe/tasks-text
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/), to add code directly to your HTML page, as follows:

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text@latest/index.js"
    crossorigin="anonymous"></script>
</head>
```

### Model

The MediaPipe Language Detector  requires a trained model that is compatible with this . For more information on available trained models for Language Detector, see the  overview [Models section](https://ai.google.dev/edge/mediapipe/solutions/text/language_detector/index#models).

Select and download a model, and then store it within your project directory:

```
<dev-project-root>/app/shared/models
```

Specify the path of the model with the `baseOptions` object `modelAssetPath` parameter, as shown below:

```
baseOptions: {
        modelAssetPath: `/app/shared/models/language_detector.tflite`
      }
```

## Create the

Use one of the Language Detector `LanguageDetector.createFrom...()` functions to prepare the  for running inferences. You can use the `createFromModelPath()` function with a relative or absolute path to the trained model file. The code example below demonstrates using the `createFromOptions()` function. For more information on configuring tasks, see [Configuration options](#configuration_options).

The following code demonstrates how to build and configure this .

```javascript
async function createDetector() {
  const textFiles = await FilesetResolver.forTextTasks(
      "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text@latest/wasm/");
  languageDetector = await languageDetector.createFromOptions(
    textFiles,
    {
      baseOptions: {
        modelAssetPath: `https://storage.googleapis.com/mediapipe-models/language_detector/language_detector/float32/1/language_detector.tflite`
      },
    }
  );
}
createDetector();
```

### Configuration options

This  has the following configuration options for Web and JavaScript applications:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| maxResults | Sets the optional maximum number of top-scored language predictions to return. If this value is less than zero, all available results are returned. | Any positive numbers | -1 |
| scoreThreshold | Sets the prediction score threshold that overrides the one provided in the model metadata (if any). Results below this value are rejected. | Any float | Not set |
| categoryAllowlist | Sets the optional list of allowed language codes. If non-empty, language predictions whose language code is not in this set will be filtered out. This option is mutually exclusive with categoryDenylist and using both results in an error. | Any strings | Not set |
| categoryDenylist | Sets the optional list of language codes that are not allowed. If non-empty, language predictions whose language code is in this set will be filtered out. This option is mutually exclusive with categoryAllowlist and using both results in an error. | Any strings | Not set |

## Prepare data

Language Detector works with text (`string`) data. The  handles the data input preprocessing, including tokenization and tensor preprocessing. All preprocessing is handled within the `detect` function. There is no need for additional preprocessing of the input text beforehand.

```javascript
const inputText = "The input text for the detector.";
```

## Run the

The Language Detector uses the `detect` function to trigger inferences. For language detection, this means returning the possible languages for the input text.

The following code demonstrates how to execute the processing with the  model:

```
// Wait to run the function until inner text is set
const detectionResult = languageDetector.detect(inputText);
```

## Handle and display results

The Language Detector  outputs a `LanguageDetectorResult` consisting of a list of language predictions along with the probabilities for those predictions. The following shows an example of the output data from this :

```
LanguageDetectorResult:
  LanguagePrediction #0:
    language_code: "fr"
    probability: 0.999781
```

This result has been obtained by running the model on the input text: `"Il y a beaucoup de bouches qui parlent et fort peu de têtes qui pensent."`.

For an example of the code required to process and visualize the results of this , see the [Web sample app](https://codepen.io/mediapipe-preview/pen/RweLdpK).
