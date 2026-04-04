---
Source: https://ai.google.dev/edge/mediapipe/solutions/text/text_embedder/web_js
Generated: 2026-03-03
Updated: 2026-03-03
---

The MediaPipe Text Embedder  lets you create a numeric representation of text data to capture its semantic meaning. These instructions show you how to use the Text Embedder for web and JavaScript apps.

For more information about the capabilities, models, and configuration options of this , see the [Overview](https://ai.google.dev/edge/mediapipe/solutions/text/text_embedder/index).

## Code example

The example code for Text Embedder provides a complete implementation of this  in JavaScript for your reference. This code helps you test this  and get started on building your own text embedding app. You can view, run, and edit the Text Embedder [example code](https://codepen.io/mediapipe-preview/pen/XWBVZmE) using just your web browser.

## Setup

This section describes key steps for setting up your development environment and code projects specifically to use Text Embedder. For general information on setting up your development environment for using MediaPipe tasks, including platform version requirements, see the [Setup guide for Web](/mediapipe/solutions/setup_web).

### JavaScript packages

Text Embedder code is available through the [`@mediapipe/tasks-text`](https://www.npmjs.com/package/@mediapipe/tasks-text) package. You can find and download these libraries from links provided in the platform [Setup guide](/mediapipe/solutions/setup_web).

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

The MediaPipe Text Embedder  requires a trained model that is compatible with this . For more information on available trained models for Text Embedder, see the  overview [Models section](https://ai.google.dev/edge/mediapipe/solutions/text/text_embedder/index#models).

Select and download a model, and then store it within your project directory:

```
<dev-project-root>/app/shared/models
```

## Create the

Use one of the Text Embedder `createFrom...()` functions to prepare the  for running inferences. You can use the `createFromModelPath()` function with a relative or absolute path to the trained model file. The code example below demonstrates using the `createFromOptions()` function. For more information on the available configuration options, see [Configuration options](#configuration_options).

The following code demonstrates how to build and configure this :

```javascript
async function createEmbedder() {
  const textFiles = await FilesetResolver.forTextTasks("https://cdn.jsdelivr.net/npm/@mediapipe/tasks-text@latest/wasm/");
  textEmbedder = await TextEmbedder.createFromOptions(
    textFiles,
    {
      baseOptions: {
        modelAssetPath: `https://storage.googleapis.com/mediapipe-tasks/text_embedder/universal_sentence_encoder.tflite`
      },
      quantize: true
    }
  );
}
createEmbedder();
```

### Configuration options

This  has the following configuration options for Web and JavaScript applications:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| l2Normalize | Whether to normalize the returned feature vector with L2 norm. Use this option only if the model does not already contain a native L2_NORMALIZATION TFLite Op. In most cases, this is already the case and L2 normalization is thus achieved through TFLite inference with no need for this option. | Boolean | False |
| quantize | Whether the returned embedding should be quantized to bytes via scalar quantization. Embeddings are implicitly assumed to be unit-norm and therefore any dimension is guaranteed to have a value in [-1.0, 1.0]. Use the l2Normalize option if this is not the case. | Boolean | False |

## Prepare data

Text Embedder works with text (`string`) data. The  handles the data input preprocessing, including tokenization and tensor preprocessing. All preprocessing is handled within the `embed` function. There is no need for additional preprocessing of the input text beforehand.

```javascript
const inputText = "The input text to be embedded.";
```

## Run the

The Text Embedder uses the `embed` function to trigger inferences. For text embedding, this means returning the embedding vectors for the input text.

The following code demonstrates how execute the processing with the  model.

```
// Wait to run the function until inner text is set
const embeddingResult = textEmbedder.embed(
  inputText
);
```

## Handle and display results

The Text Embedder outputs a `TextEmbedderResult` that contains a list of embeddings (either floating-point or scalar-quantized) for the input text.

The following shows an example of the output data from this :

```
TextEmbedderResult:
  Embedding #0 (sole embedding head):
    float_embedding: {0.2345f, 0.1234f, ..., 0.6789f}
    head_index: 0
```

You can compare the semantic similarity of two embeddings using the `TextEmbedder.cosineSimilarity` function. See the following code for an example.

```
// Compute cosine similarity.
const similarity = TextEmbedder.cosineSimilarity(
  embeddingResult.embeddings[0],
  otherEmbeddingResult.embeddings[0]);
```

The Text Embedder example code demonstrates how to display the embedder results returned from the , see the [code example](https://codepen.io/mediapipe-preview/pen/XWBVZmE) for details.
