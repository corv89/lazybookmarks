---
Source: https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/web_js
Generated: 2026-03-03
Updated: 2026-03-03
---

The MediaPipe Text Classifier  lets you classify text into a set of defined categories, such as positive or negative sentiment. The categories are determined the model you use and how that model was trained. These instructions show you how to use the Text Classifier for web and JavaScript apps.

You can see this  in action by viewing the [demo](https://mediapipe-studio.webapps.google.com/demo/text_classifier). For more information about the capabilities, models, and configuration options of this , see the [Overview](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/index).

## Code example

The example code for Text Classifier provides a complete implementation of this  in JavaScript for your reference. This code helps you test this  and get started on building your own text classification app. You can view, run, and edit the [Text Classifier example code](https://codepen.io/mediapipe-preview/pen/wvXebMW/26650bf59f281a09db9a3fb60900135e) using just your web browser.

## Setup

This section describes key steps for setting up your development environment and code projects specifically to use Text Classifier. For general information on setting up your development environment for using MediaPipe Tasks, including platform version requirements, see the [Setup guide for Web](/mediapipe/solutions/setup_web).

### JavaScript packages

Text Classifier code is available through the [`@mediapipe/tasks-text`](https://www.npmjs.com/package/@mediapipe/tasks-text) package. You can find and download these libraries from links provided in the platform [Setup guide](/mediapipe/solutions/setup_web).

**Attention:** This MediaPipe Solutions Preview is an early release. [Learn more](/edge/mediapipe/solutions/about#notice).

You can install the required packages with the following code for local staging using the following command:

```
npm install @mediapipe/tasks-text
```

If you want to deploy to a server, you can use a content delivery network (CDN) service, such as [jsDelivr](https://www.jsdelivr.com/) to add code directly to your HTML page, as follows:

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text@0.1/text-bundle.js"
    crossorigin="anonymous"></script>
</head>
```

### Model

The MediaPipe Text Classifier  requires a trained model that is compatible with this . For more information on available trained models for Text Classifier, see the  overview [Models section](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/index#models).

Select and download a model, and then store it within your project directory:

```
<dev-project-root>/assets/bert_text_classifier.tflite
```

Specify the path of the model with the `baseOptions` object `modelAssetPath` parameter, as shown below:

```
baseOptions: {
        modelAssetPath: `/assets/bert_text_classifier.tflite`
      }
```

## Create the

Use one of the Text Classifier `TextClassifier.createFrom...()` functions to prepare the  for running inferences. You can use the `createFromModelPath()` function with a relative or absolute path to the trained model file. The code example below demonstrates using the `TextClassifier.createFromOptions()` function. For more information on the available configuration options, see [Configuration options](#configuration_options).

The following code demonstrates how to build and configure this :

```javascript
async function createClassifier() {
  const textFiles = await FilesetResolver.forTextTasks("https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text@latest/wasm/");
  textClassifier = await TextClassifier.createFromOptions(
    textFiles,
    {
      baseOptions: {
        modelAssetPath: `https://storage.googleapis.com/mediapipe-tasks/text_classifier/bert_text_classifier.tflite`
      },
      maxResults: 5
    }
  );
}
createClassifier();
```

### Configuration options

This  has the following configuration options for Web and JavaScript applications:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| displayNamesLocale | Sets the language of labels to use for display names provided in the metadata of the 's model, if available. Default is en for English. You can add localized labels to the metadata of a custom model using the TensorFlow Lite Metadata Writer API | Locale code | en |
| maxResults | Sets the optional maximum number of top-scored classification results to return. If < 0, all available results will be returned. | Any positive numbers | -1 |
| scoreThreshold | Sets the prediction score threshold that overrides the one provided in the model metadata (if any). Results below this value are rejected. | Any float | Not set |
| categoryAllowlist | Sets the optional list of allowed category names. If non-empty, classification results whose category name is not in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryDenylist and using both results in an error. | Any strings | Not set |
| categoryDenylist | Sets the optional list of category names that are not allowed. If non-empty, classification results whose category name is in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryAllowlist and using both results in an error. | Any strings | Not set |

## Prepare data

Text Classifier works with text (`String`) data. The  handles the data input preprocessing, including tokenization and tensor preprocessing.

All preprocessing is handled within the `classify()` function. There is no need for additional preprocessing of the input text beforehand.

```javascript
const inputText = "The input text to be classified.";
```

## Run the

The Text Classifier uses the `classify()` function to trigger inferences. For text classification, this means returning the possible categories for the input text.

The following code demonstrates how to execute the processing with the  model.

```
// Wait to run the function until inner text is set
const result: TextClassifierResult = await textClassifier.classify(
  inputText
);
```

## Handle and display results

The Text Classifier outputs a `TextClassifierResult` which contains the list of possible categories for the input text. The categories are defined by the model you use, so if you want different categories, pick a different model, or retrain an existing one.

The following shows an example of the output data from this :

```
TextClassificationResult:
  Classification #0 (single classification head):
    ClassificationEntry #0:
      Category #0:
        category name: "positive"
        score: 0.8904
        index: 0
      Category #1:
        category name: "negative"
        score: 0.1096
        index: 1
```

This result has been obtained by running the [BERT-classifier](https://storage.googleapis.com/mediapipe-assets/bert_text_classifier.tflite) on the input text: `"an imperfect but overall entertaining mystery"`.
