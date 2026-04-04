---
Source: https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier
Generated: 2026-03-03
Updated: 2026-03-03
---

![Example UI that shows a positive movie review as the input and the output as
five stars and a thumbs
up](https://developers.google.com/static/mediapipe/images/solutions/examples/text_classifier.png)

MediaPipe Text Classifier  lets you classify text into a set of defined categories, such as positive or negative sentiment. The categories are defined during the training of the model. This  operates on text data with a machine learning (ML) model as static data and outputs a list of categories and their likelihood scores.

[Try it!](https://mediapipe-studio.webapps.google.com/demo/text_classifier)

## Get Started

Start using this  by following one of these implementation guides for the platform you are working on:

-   **Android** - [Code example](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/text_classification/android)
    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/android)
-   **Python** - [Code example](https://colab.research.google.com/github/googlesamples/mediapipe/blob/main/examples/text_classification/python/text_classifier.ipynb)
    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/python)
-   **Web** - [Code example](https://codepen.io/mediapipe-preview/pen/wvXebMW) - [Guide](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/web_js)
-   **iOS** - [Code example](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/text_classification/ios)
    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/ios)

These platform-specific guides walk you through a basic implementation of this , including a recommended model, and code example with recommended configuration options.

## Task details

This section describes the capabilities, inputs, outputs, and configuration options of this .

### Features

-   **Input text processing** - Support out-of-graph tokenization for models without in-graph tokenization
-   **Multiple classification heads** - Each head can use its own category set
-   **Label map locale** - Set the language used for display names
-   **Score threshold** - Filter results based on prediction scores
-   **Top-k classification results** - Filter the number of detection results
-   **Label allowlist and denylist** - Specify the categories detected

| Task inputs | Task outputs |
| --- | --- |
| Text Classifier accepts the following input data type: , String | Text Classifier outputs a list of categories containing: , Category index: the index of the category in the model outputs , Score: the confidence score for this category, expressed as a probability between zero and one as floating point value. , Category name (optional): the name of the category as specified in the TensorFlow Lite Model Metadata, if available. , Category display name (optional): a display name for the category as specified in the TensorFlow Lite Model Metadata, in the language specified through display names locale options, if available. |

**Note:** This  supports modification of the provided ML models and custom models. For more information on using modified or custom models for this , see [Custom models](#custom_models).

### Configuration options

This  has the following configuration options:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| displayNamesLocale | Sets the language of labels to use for display names provided in the metadata of the 's model, if available. Default is en for English. You can add localized labels to the metadata of a custom model using the TensorFlow Lite Metadata Writer API | Locale code | en |
| maxResults | Sets the optional maximum number of top-scored classification results to return. If < 0, all available results will be returned. | Any positive numbers | -1 |
| scoreThreshold | Sets the prediction score threshold that overrides the one provided in the model metadata (if any). Results below this value are rejected. | Any float | Not set |
| categoryAllowlist | Sets the optional list of allowed category names. If non-empty, classification results whose category name is not in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryDenylist and using both results in an error. | Any strings | Not set |
| categoryDenylist | Sets the optional list of category names that are not allowed. If non-empty, classification results whose category name is in this set will be filtered out. Duplicate or unknown category names are ignored. This option is mutually exclusive with categoryAllowlist and using both results in an error. | Any strings | Not set |

## Models

Text Classifier can be used with more than one ML model. Start with the default, recommended model for your target platform when you start developing with this . The other available models typically make trade-offs between performance, accuracy, resolution, and resource requirements, and in some cases, include additional features.

The pretrained models are trained for sentiment analysis, and predict whether the input text's sentiment is positive or negative. The models were trained on the [SST-2](https://nlp.stanford.edu/sentiment/index.html) (Stanford Sentiment Treebank) dataset, which consists of movie reviews labeled as either positive or negative. Note that the models only support English. Since they were trained on a dataset of movie reviews, you may see reduced quality for text covering other topic areas.

**Attention:** This MediaPipe Solutions Preview is an early release. [Learn more](/edge/mediapipe/solutions/about#notice).

### BERT-classifier model (recommended)

This model uses a BERT-based architecture (specifically, [the MobileBERT model](https://arxiv.org/abs/2004.02984)) and is recommended because of its high accuracy. It contains metadata that allows the  to perform out-of-graph BERT tokenization.

| Model name | Input shape | Quantization type | Versions |
| --- | --- | --- | --- |
| BERT-classifier | [1x128],[1x128],[1x128] | dynamic range | Latest |

### Average word embedding model

This model uses an average word-embedding architecture. This model offers a smaller model size and lower latency at the cost of a lower prediction accuracy compared to the BERT-classifier. Customizing this model through additional training is also faster than doing training of the BERT-based classifier. This model contains metadata that allows the  to perform out-of-graph regex tokenization.

| Model name | Input shape | Quantization type | Versions |
| --- | --- | --- | --- |
| Average word embedding | 1 x 256 | None (float32) | Latest |

### Task benchmarks

Here's the  benchmarks for the whole pipeline based on the above pre-trained models. The latency result is the average latency on Pixel 6 using CPU / GPU.

| Model Name | CPU Latency | GPU Latency |
| --- | --- | --- |
| Average word embedding | 0.14ms | - |
| BERT-classifier | 57.68ms | - |

### Custom models

You can use a customized ML model with this  if you want to improve or alter the capabilities of the provided models. You can use Model Maker to modify the existing models or build a model using tools like TensorFlow. Custom models used with MediaPipe must be in [TensorFlow Lite](/edge/lite/models/trained) format and must include specific [metadata](/edge/lite/models/metadata) describing the operating parameters of the model. You should consider using Model Maker to modify the provided models for this  before building your own.

**Note:** If you are interested in creating a custom Text Classifier using your own dataset, refer to the [Text classifier customization](https://ai.google.dev/edge/mediapipe/solutions/text/text_classifier/customize) tutorial.
