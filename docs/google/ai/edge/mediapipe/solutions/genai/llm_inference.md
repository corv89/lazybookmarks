---
Source: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference
Generated: 2026-01-05
Updated: 2026-01-05
---

**Note:** Use of the MediaPipe LLM Inference API is subject to the [Generative AI Prohibited Use Policy](https://policies.google.com/terms/generative-ai/use-policy).

The LLM Inference API lets you run large language models (LLMs) completely on-device, which you can use to perform a wide range of tasks, such as generating text, retrieving information in natural language form, and summarizing documents. The  provides built-in support for multiple text-to-text large language models, so you can apply the latest on-device generative AI models to your apps and products.

[Try it!](https://mediapipe-studio.webapps.google.com/demo/llm_inference)

The  provides built-in support for a variety of LLMs. Models hosted on the [LiteRT Community](https://huggingface.co/litert-community) page are available in a MediaPipe-friendly format and don't require any adiitional conversion or compilation steps.

You can use [AI Edge Torch](https://github.com/google-ai-edge/ai-edge-torch) to export PyTorch models into multi-signature LiteRT (`tflite`) models, which are bundled with tokenizer parameters to create Task Bundles. Models converted with AI Edge Torch are compatible with the LLM Inference API and can run on the CPU backend, making them appropriate for Android and iOS applications.

## Get Started

Start using this  by following one of these implementation guides for your target platform. These platform-specific guides walk you through a basic implementation of this , with code examples that use an available model and the recommended configuration options:

-   **Web**:

    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/web_js)
    -   [Code example](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/llm_inference/js)
-   **Android**:

    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android)
    -   [Code example](https://github.com/google-ai-edge/gallery)
-   **iOS**

    -   [Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios)
    -   [Code example](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/llm_inference/ios)

## Task details

This section describes the capabilities, inputs, outputs, and configuration options of this .

### Features

The LLM Inference API contains the following key features:

1.  **Text-to-text generation** - Generate text based on an input text prompt.
2.  **LLM selection** - Apply multiple models to tailor the app for your specific use cases. You can also retrain and apply customized weights to the model.
3.  **LoRA support** - Extend and customize the LLM capability with LoRA model either by training on your all dataset, or taking prepared prebuilt LoRA models from the open-source community (not compatible with models converted with the AI Edge Torch Generative API).

| Task inputs | Task outputs |
| --- | --- |
| The LLM Inference API accepts the following inputs: , Text prompt (e.g., a question, an email subject, a document to be summarized) | The LLM Inference API outputs the following results: , Generated text based on the input prompt (e.g., an answer to the question, an email draft, a summary of the document) |

### Configurations options

This  has the following configuration options:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| modelPath | The path to where the model is stored within the project directory. | PATH | N/A |
| maxTokens | The maximum number of tokens (input tokens + output tokens) the model handles. | Integer | 512 |
| topK | The number of tokens the model considers at each step of generation. Limits predictions to the top k most-probable tokens. | Integer | 40 |
| temperature | The amount of randomness introduced during generation. A higher temperature results in more creativity in the generated text, while a lower temperature produces more predictable generation. | Float | 0.8 |
| randomSeed | The random seed used during text generation. | Integer | 0 |
| loraPath | The absolute path to the LoRA model locally on the device. Note: this is only compatible with GPU models. | PATH | N/A |
| resultListener | Sets the result listener to receive the results asynchronously. Only applicable when using the async generation method. | N/A | N/A |
| errorListener | Sets an optional error listener. | N/A | N/A |

## Models

The LLM Inference API supports many text-to-text large language models, including built-in support for several models that are optimized to run on browsers and mobile devices. These lightweight models can be used to run inferences completely on-device.

Before initializing the LLM Inference API, download a model and store the file within your project directory. You can use a pre-converted model from the [LiteRT Community](https://huggingface.co/litert-community) HuggingFace repository, or convert a model to a MediaPipe-compatible format with the [AI Edge Torch Generative Converter](https://github.com/google-ai-edge/ai-edge-torch/tree/main/ai_edge_torch/generative).

If you don't already have an LLM to use with the LLM Inference API, get started with one of the following models.

### Gemma-3n

Gemma-3n E2B and E4B are the latest models in the Gemma family of lightweight, state-of-the-art open models built from the same research and technology used to create the [Gemini](https://ai.google.dev/docs) models. Gemma 3n models are designed for efficient execution on low-resource devices. They are capable of multimodal input, handling text, image, and audio input, and generating text outputs.

Gemma 3n models use selective parameter activation technology to reduce resource requirements. This technique allows the models to operate at an effective size of 2B and 4B parameters, which is lower than the total number of parameters they contain

**Note:** Gemma-3n is an openly available model. You are responsible for complying with any applicable license terms.

[Download Gemma-3n E2B](https://huggingface.co/google/gemma-3n-E2B-it-litert-lm)

[Download Gemma-3n E4B](https://huggingface.co/google/gemma-3n-E4B-it-litert-lm)

The Gemma-3n E2B and E4B models from HuggingFace are available in the `.litertlm` format, and are ready to use with the LLM Inference API for Android and Web.

### Gemma-3 1B

**Note:** Gemma-3 is an openly available model. You are responsible for complying with any applicable license terms.

[Gemma-3 1B](https://huggingface.co/litert-community/Gemma3-1B-IT) is the lightest model in the Gemma family of lightweight, state-of-the-art open models built from the same research and technology used to create the [Gemini](https://ai.google.dev/docs) models. The model contains 1B parameters and open weights.

[Download Gemma-3 1B](https://huggingface.co/litert-community/Gemma3-1B-IT)

The Gemma-3 1B model from [HuggingFace](https://huggingface.co/litert-community/Gemma3-1B-IT) is available in the `.`/[`.litertlm`](https://github.com/google-ai-edge/LiteRT-LM?tab=readme-ov-file#quick-start) format, and ready to use with the LLM Inference API for Android and Web applications.

When running Gemma-3 1B with the LLM Inference API, configure the following options accordingly:

-   `preferredBackend`: Use this option to choose between a `CPU` or `GPU` backend. This option is only available for Android.
-   `supportedLoraRanks`: The LLM Inference API cannot be configured to support Low-Rank Adaptation (LoRA) with the Gemma-3 1B model. Do not use the `supportedLoraRanks` or `loraRanks` options.
-   `maxTokens`: The value for `maxTokens` must match the context size built into the model. This can also be referred to as the Key-Value (KV) cache or context length.
-   `numResponses`: Must always be 1. This option is only available for Web.

When running Gemma-3 1B on web applications, initialization can cause a lengthy block in the current thread. If possible, always run the model from a worker thread.

### Gemma-2 2B

**Note:** Gemma-2 is an openly available model. You are responsible for complying with any applicable license terms.

[Gemma-2 2B](https://huggingface.co/litert-community/Gemma2-2B-IT) is a 2B variant of Gemma-2, and works on all platforms.

[Download Gemma-2 2B](https://huggingface.co/litert-community/Gemma2-2B-IT)

The model contains 2B parameters and open weights. Gemma-2 2B is known for state-of-the art reasoning skills for models in its class.

## PyTorch Model conversion

**Note:** The AI Edge Torch library is in early development. The API is unstable and contains some [known issues](https://github.com/google-ai-edge/ai-edge-torch/tree/main/ai_edge_torch/generative#known-issues).

PyTorch generative models can be converted to a MediaPipe-compatible format with the [AI Edge Torch Generative API](https://github.com/google-ai-edge/ai-edge-torch/tree/main/ai_edge_torch/generative). You can use the API to convert PyTorch models into multi-signature LiteRT (TensorFlow Lite) models. For more details on mapping and exporting models, visit the AI Edge Torch [GitHub page](https://github.com/google-ai-edge/ai-edge-torch).

Converting a PyTorch model with the [AI Edge Torch Generative API](https://github.com/google-ai-edge/ai-edge-torch/tree/main/ai_edge_torch/generative) involves the following steps:

1.  Download the PyTorch model checkpoints.
2.  Use the AI Edge Torch Generative API to author, convert, and quantize the model to a MediaPipe-compatible file format (`.tflite`).
3.  Create a Task Bundle (`.`/`.litertlm`) from the tflite file and the model tokenizer.

The Torch Generative converter only converts for CPU and requires a Linux machine with at least 64 GBs of RAM.

To create a Task Bundle, use the [bundling script](https://colab.sandbox.google.com/github/googlesamples/mediapipe/blob/main/examples/llm_inference/bundling/llm_bundling.ipynb) to create a *Task Bundle*. The bundling process packs the mapped model with additional metadata (e.g., Tokenizer Parameters) needed to run end-to-end inference.

The model bundling process requires the MediaPipe PyPI package. The conversion script is available in all MediaPipe packages after `0.10.14`.

**Note:** To avoid compatibility issues, use the [Model bundling colab](https://colab.sandbox.google.com/github/googlesamples/mediapipe/blob/main/examples/llm_inference/bundling/llm_bundling.ipynb).

Install and import the dependencies with the following:

```bash
$ python3 -m pip install mediapipe
```

Use the `genai.bundler` library to bundle the model:

```python
import mediapipe as mp
from mediapipe.tasks.python.genai import bundler

config = bundler.BundleConfig(
    tflite_model=TFLITE_MODEL,
    tokenizer_model=TOKENIZER_MODEL,
    start_token=START_TOKEN,
    stop_tokens=STOP_TOKENS,
    output_filename=OUTPUT_FILENAME,
    enable_bytes_to_unicode_mapping=ENABLE_BYTES_TO_UNICODE_MAPPING,
)
bundler.create_bundle(config)
```

| Parameter | Description | Accepted Values |
| --- | --- | --- |
| tflite_model | The path to the AI Edge exported TFLite model. | PATH |
| tokenizer_model | The path to the SentencePiece tokenizer model. | PATH |
| start_token | Model specific start token. The start token must be present in the provided tokenizer model. | STRING |
| stop_tokens | Model specific stop tokens. The stop tokens must be present in the provided tokenizer model. | LIST[STRING] |
| output_filename | The name of the output  bundle file. | PATH |

## LoRA customization

Mediapipe LLM inference API can be configured to support Low-Rank Adaptation (LoRA) for large language models. Utilizing fine-tuned LoRA models, developers can customize the behavior of LLMs through a cost-effective training process.

LoRA support of the LLM Inference API works for all Gemma variants and Phi-2 models for the GPU backend, with LoRA weights applicable to attention layers only. This initial implementation serves as an experimental API for future developments with plans to support more models and various types of layers in the coming updates.

### Prepare LoRA models

Follow the [instructions on HuggingFace](https://huggingface.co/docs/peft/main/en/task_guides/lora_based_methods) to train a fine tuned LoRA model on your own dataset with supported model types, Gemma or Phi-2. [Gemma-2 2B](https://huggingface.co/google/gemma-2-2b), [Gemma 2B](https://huggingface.co/google/gemma-2b) and [Phi-2](https://huggingface.co/microsoft/phi-2) models are both available on HuggingFace in the safetensors format. Since LLM Inference API only supports LoRA on attention layers, only specify attention layers while creating the `LoraConfig` as following:

```bash

# For Gemma
from peft import LoraConfig
config = LoraConfig(
    r=LORA_RANK,
    target_modules=["q_proj", "v_proj", "k_proj", "o_proj"],
)

# For Phi-2
config = LoraConfig(
    r=LORA_RANK,
    target_modules=["q_proj", "v_proj", "k_proj", "dense"],
)
```

For testing, there are publicly accessible fine-tuned LoRA models which fit LLM Inference API available on HuggingFace. For example, [monsterapi/gemma-2b-lora-maths-orca-200k](https://huggingface.co/monsterapi/gemma-2b-lora-maths-orca-200k) for Gemma-2B and [lole25/phi-2-sft-ultrachat-lora](https://huggingface.co/lole25/phi-2-sft-ultrachat-lora) for Phi-2.

After training on the prepared dataset and saving the model, you obtain an `adapter_model.safetensors` file containing the fine-tuned LoRA model weights. The safetensors file is the LoRA checkpoint used in the model conversion.

As the next step, you need convert the model weights into a TensorFlow Lite Flatbuffer using the MediaPipe Python Package. The `ConversionConfig` should specify the base model options as well as additional LoRA options. Notice that since the API only supports LoRA inference with GPU, the backend must be set to `'gpu'`.

```python
import mediapipe as mp
from mediapipe.tasks.python.genai import converter

config = converter.ConversionConfig(
  # Other params related to base model
  ...
  # Must use gpu backend for LoRA conversion
  backend='gpu',
  # LoRA related params
  lora_ckpt=LORA_CKPT,
  lora_rank=LORA_RANK,
  lora_output_tflite_file=LORA_OUTPUT_TFLITE_FILE,
)

converter.convert_checkpoint(config)
```

The converter will output two TFLite flatbuffer files, one for the base model and the other for the LoRA model.

### LoRA model inference

The Web, Android and iOS LLM Inference API are updated to support LoRA model inference.

Android supports static LoRA during initialization. To load a LoRA model, users specify the LoRA model path as well as the base LLM.

```
// Set the configuration options for the LLM Inference
val options = LlmInferenceOptions.builder()
        .setModelPath('<path to base model>')
        .setMaxTokens(1000)
        .setTopK(40)
        .setTemperature(0.8)
        .setRandomSeed(101)
        .setLoraPath('<path to LoRA model>')
        .build()

// Create an instance of the LLM Inference
llmInference = LlmInference.createFromOptions(context, options)
```

To run LLM inference with LoRA, use the same `generateResponse()` or `generateResponseAsync()` methods as the base model.
