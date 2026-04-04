---
Source: https://ai.google.dev/edge/mediapipe/solutions/customization/text_classifier
Generated: 2026-03-03
Updated: 2026-03-03
---

| Run in Colab | View on GitHub |
| --- | --- |

### License information

Toggle code

```bash

# Copyright 2023 The MediaPipe Authors.

# Licensed under the Apache License, Version 2.0 (the "License");

#

# you may not use this file except in compliance with the License.

# You may obtain a copy of the License at

#

# https://www.apache.org/licenses/LICENSE-2.0

#

# Unless required by applicable law or agreed to in writing, software

# distributed under the License is distributed on an "AS IS" BASIS,

# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

# See the License for the specific language governing permissions and

# limitations under the License.
```

The MediaPipe Model Maker package is a simple, low-code solution for customizing on-device machine learning (ML) Models. This notebook shows the end-to-end process of customizing a text classification model for the specific use case of performing sentiment analysis on movie reviews.

## Prerequisites

Install the MediaPipe Model Maker package.

```
pip install --upgrade pip
```

Import the required libraries.

```python
import os
import tensorflow as tf
assert tf.__version__.startswith('2')

from mediapipe_model_maker import text_classifier
```

## Get the Dataset

The following code block downloads the [SST-2](https://nlp.stanford.edu/sentiment/index.html) (Stanford Sentiment Treebank) dataset which contains 67,349 movie reviews for training and 872 movie reviews for testing. The dataset has two classes: positive and negative movie reviews. Positive reviews are labelled with `1` and negative reviews with `0`. We will use this dataset to train the two text classifiers featured in this tutorial.

*Disclaimer: The dataset linked in this Colab is not owned or distributed by Google, and is made available by third parties. Please review the terms and conditions made available by the third parties before using the data.*

```
data_path = tf.keras.utils.get_file(
    fname='SST-2.zip',
    origin='https://dl.fbaipublicfiles.com/glue/data/SST-2.zip',
    extract=True)
data_dir = os.path.join(os.path.dirname(data_path), 'SST-2')  # folder name
```

The SST-2 dataset is stored as a TSV file. The only difference between the TSV and CSV formats is that TSV uses a tab `\t` character as its delimiter and CSV uses a comma `,`.

The following code block extracts the training and validation data from their TSV files using the `Dataset.from_csv` method.

```
csv_params = text_classifier.CSVParams(
    text_column='sentence', label_column='label', delimiter='\t')
train_data = text_classifier.Dataset.from_csv(
    filename=os.path.join(os.path.join(data_dir, 'train.tsv')),
    csv_params=csv_params)
validation_data = text_classifier.Dataset.from_csv(
    filename=os.path.join(os.path.join(data_dir, 'dev.tsv')),
    csv_params=csv_params)
```

## Average Word Embedding Model

Model Maker's Text Classifier supports two classifiers with distinct model architectures: an average word embedding model and a BERT model. The first demo classifier wil use an average word embedding architecture.

To create and train a text classifier we need to set some `TextClassifierOptions`. These options require us to specify a `supported_model`, which can take the value `AVERAGE_WORD_EMBEDDING_CLASSIFIER` or `MOBILEBERT_CLASSIFIER`. We'll use `AVERAGE_WORD_EMBEDDING_CLASSIFIER` for now.

For more information on the `TextClassifierOptions` class and its fields, see the TextClassifierOptions section below.

```
supported_model = text_classifier.SupportedModels.AVERAGE_WORD_EMBEDDING_CLASSIFIER
hparams = text_classifier.AverageWordEmbeddingHParams(epochs=10, batch_size=32, learning_rate=0, export_dir="awe_exported_models")
options = text_classifier.TextClassifierOptions(supported_model=supported_model, hparams=hparams)
```

Now we can use the training and validation data with the `TextClassifierOptions` we've defined to create and train a text classifier. To do so, we use the `TextClassifier.create` function.

```
model = text_classifier.TextClassifier.create(train_data, validation_data, options)
```

Evaluate the model on the validation data and print the loss and accuracy.

```python
metrics = model.evaluate(validation_data)
print(f'Test loss:{metrics[0]}, Test accuracy:{metrics[1]}')
```

After training the model we can export it as a TFLite file for on-device applications. We can also export the labels used during training.

```
model.export_model()
model.export_labels(export_dir=options.hparams.export_dir)
```

You can download the TFLite model using the left sidebar of Colab.

## BERT-classifier

Now let's train a text classifier based on the [MobileBERT](https://arxiv.org/abs/2004.02984) model.

```
supported_model = text_classifier.SupportedModels.MOBILEBERT_CLASSIFIER
hparams = text_classifier.BertHParams(epochs=2, batch_size=48, learning_rate=3e-5, export_dir="bert_exported_models")
options = text_classifier.TextClassifierOptions(supported_model=supported_model, hparams=hparams)
```

Create and train the text classifier like we did with the average word embedding-based classifier.

**Warning:** This can take ~25 minutes on a GPU runtime and nearly 7 hours on CPU. We strongly recommend using a GPU runtime.

```
bert_model = text_classifier.TextClassifier.create(train_data, validation_data, options)
```

Evaluate the model. Note the improved performance compared to the average word embedding-based classifier.

```python
metrics = bert_model.evaluate(validation_data)
print(f'Test loss:{metrics[0]}, Test accuracy:{metrics[1]}')
```

The MobileBERT model is over 100MB so when we export the BERT-based classifier as a TFLite model, it will help to use quantization which can bring the TFLite model size down to 28MB.

```python
from mediapipe_model_maker import quantization
quantization_config = quantization.QuantizationConfig.for_dynamic()
bert_model.export_model(quantization_config=quantization_config)
bert_model.export_labels(export_dir=options.hparams.export_dir)
```

## TextClassifierOptions

We can configure text classifier training with `TextClassifierOptions`, which takes one required parameter:

-   `supported_model` which describes the model architecture that the text classifier is based on. It can be either an `AVERAGE_WORD_EMBEDDING_CLASSIFIER` or a `MOBILEBERT_CLASSIFIER`.

`TextClassifierOptions` can also take two optional parameters:

-   `hparams` which describes hyperparameters used during model training. This takes an `HParams` object.
-   `model_options` which describes configurable parameters related to the model architecture or data preprocessing. For an average word-embedding classifier, this field takes an `AverageWordEmbeddingModelOptions` object. For a BERT-based classifier, this field takes a `BertModelOptions` object.

If these fields aren't set, model creation and training will be run with predefined default values.

`HParams` has the following list of customizable parameters which affect model accuracy:

-   `learning_rate`: The learning rate to use for gradient descent-based optimizers. Defaults to 3e-5 for the BERT-based classifier and 0 for the average word-embedding classifier because it does not need such an optimizer.
-   `batch_size`: Batch size for training. Defaults to 32 for the average word-embedding classifier and 48 for the BERT-based classifier.
-   `epochs`: Number of training iterations over the dataset. Defaults to 10 for the average word-embedding classifier and 3 for the BERT-based classifier.
-   `steps_per_epoch`: An optional integer that indicates the number of training steps per epoch. If not set, the training pipeline calculates the default steps per epoch as the training dataset size divided by batch size.
-   `shuffle`: True if the dataset is shuffled before training. Defaults to False.

Additional `HParams` parameters that do not affect model accuracy:

-   `export_dir`: The location of the model checkpoint files and exported model files.

`AverageWordEmbeddingModelOptions` has the following list of customizable parameters related to the model architecture:

-   `seq_len`: the length of the input sequence for the model. Defaults to 256.
-   `wordvec_dim`: the dimension of the word embeddings. Defaults to 16.
-   `dropout_rate`: The rate used in the model's dropout layer. Defaults to 0.2.

It also has the following customizable parameters related to data preprocessing:

-   `do_lower_case`: whether text input is converted to lower case before training or inference. Defaults to True.
-   `vocab_size`: the maximum size of the vocab generated from the set of text data.

`BertModelOptions` has the following list of customizable parameters related to the model architecture:

-   `seq_len`: the length of the input sequence for the BERT-encoder. Defaults to 128
-   `dropout_rate`: the rate used in the classifier's dropout layer. Defaults to 0.1.
-   `do_fine_tuning`: whether the BERT-encoder is unfrozen and should be trainable along with the classifier layers. Defaults to True.

## Benchmarks

Below is a summary of our benchmarking results for the average word-embedding and BERT-based classifiers featured in this tutorial. To optimize model performance for your use-case, it's worthwhile to experiment with different model and training parameters in order to obtain the highest test accuracy. Refer to the TextClassifierOptions section for more information on customizing these parameters.

| Model architecture | Test Accuracy | Model Size | CPU 1 Thread Latency on Pixel 6 (ms) | GPU Latency on Pixel 6 (ms) |
| --- | --- | --- | --- | --- |
| Average Word-Embedding | 81.0% | 776K | 0.03 | 0.43 |
| MobileBERT | 90.36% | 28.4MB | 53.38 | 74.22 |
