---
Source: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/web_js
Generated: 2026-01-05
Updated: 2026-01-05
---

**Note:** Use of the MediaPipe LLM Inference API is subject to the [Generative AI Prohibited Use Policy](https://policies.google.com/terms/generative-ai/use-policy).

The LLM Inference API lets you run large language models (LLMs) completely on-device for Web applications, which you can use to perform a wide range of tasks, such as generating text, retrieving information in natural language form, and summarizing documents. The  provides built-in support for multiple text-to-text large language models, so you can apply the latest on-device generative AI models to your Web apps. If you are using the latest Gemma-3n models, then image and audio inputs are also supported.

To quickly add the LLM Inference API to your Web application, follow the [Quickstart](#quickstart). For a basic example of a Web application running the LLM Inference API, see the [sample application](#sample-application). For a more in-depth understanding of how the LLM Inference API works, refer to the [configuration options](#configuration-options), [model conversion](#model-conversion), and [LoRA tuning](#lora-customization) sections.

You can see this  in action with the [MediaPipe Studio demo](https://mediapipe-studio.webapps.google.com/studio/demo/llm_inference). For more information about the capabilities, models, and configuration options of this , see the [Overview](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/index).

## Quickstart

Use the following steps to add the LLM Inference API to your Web application. The LLM Inference API requires a web browser with WebGPU compatibility. For a full list of compatible browsers, see [GPU browser compatibility](https://developer.mozilla.org/en-US/docs/Web/API/GPU#browser_compatibility).

### Add dependencies

The LLM Inference API uses the [`@mediapipe/tasks-genai`](https://www.npmjs.com/package/@mediapipe/tasks-genai) package.

Install the required packages for local staging:

```
npm install @mediapipe/tasks-genai
```

To deploy to a server, use a content delivery network (CDN) service like [jsDelivr](https://www.jsdelivr.com/) to add code directly to your HTML page:

```
<head>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai/genai_bundle.cjs"
    crossorigin="anonymous"></script>
</head>
```

### Download a model

Download Gemma-3n [E4B](https://huggingface.co/google/gemma-3n-E4B-it-litert-lm/blob/main/gemma-3n-E4B-it-int4-Web.litertlm) or [E2B](https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/blob/main/gemma-3n-E2B-it-int4-Web.litertlm) from HuggingFace. Models with "-Web" in the name are converted specifically for web usage, so it's highly recommended to always use one of these.

For more information on the available models, see the [Models documentation](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/index#models), or browse our [HuggingFace Community page](https://huggingface.co/litert-community/models), which offers several additional Gemma 3 variants not covered in the documentation, but which have been converted specially for web, like [270M](https://huggingface.co/litert-community/gemma-3-270m-it), [4B](https://huggingface.co/litert-community/Gemma3-4B-IT), [12B](https://huggingface.co/litert-community/Gemma3-12B-IT), [27B](https://huggingface.co/litert-community/Gemma3-27B-IT), and [MedGemma-27B-Text](https://huggingface.co/litert-community/MedGemma-27B-IT).

Store the model within your project directory:

```
<dev-project-root>/assets/gemma-3n-E4B-it-int4-Web.litertlm
```

Specify the path of the model with the `baseOptions` object `modelAssetPath` parameter:

```
baseOptions: { modelAssetPath: `/assets/gemma-3n-E4B-it-int4-Web.litertlm`}
```

### Initialize the Task

Initialize the  with basic configuration options:

```javascript
const genai = await FilesetResolver.forGenAiTasks(
    // path/to/wasm/root
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai@latest/wasm"
);
llmInference = await LlmInference.createFromOptions(genai, {
    baseOptions: {
        modelAssetPath: '/assets/gemma-3n-E4B-it-int4-Web.litertlm'
    },
    maxTokens: 1000,
    topK: 40,
    temperature: 0.8,
    randomSeed: 101
});
```

### Run the Task

Use the `generateResponse()` function to trigger inferences.

```javascript
const response = await llmInference.generateResponse(inputPrompt);
document.getElementById('output').textContent = response;
```

To stream the response, use the following:

```javascript
llmInference.generateResponse(
  inputPrompt,
  (partialResult, done) => {
        document.getElementById('output').textContent += partialResult;
});
```

### Multimodal prompting

For Gemma-3n models, the LLM Inference API Web APIs support multimodal prompting. With multimodality enabled, users can include an ordered combination of images, audio, and text in their prompts. The LLM then provides a text response.

To get started, use either [Gemma-3n E4B](https://huggingface.co/google/gemma-3n-E4B-it-litert-lm/blob/main/gemma-3n-E4B-it-int4-Web.litertlm) or [Gemma-3n E2B](https://huggingface.co/google/gemma-3n-E2B-it-litert-lm/blob/main/gemma-3n-E2B-it-int4-Web.litertlm), in MediaPipe- and Web-compatible format. For more information, see the [Gemma-3n documentation](https://ai.google.dev/gemma/docs/gemma-3n).

To enable vision support, ensure `maxNumImages` is set to a positive value. This determines the maximum number of image pieces the LLM can process in a single prompt.

To enable audio support, ensure `supportAudio` is set to `true`.

```
llmInference = await LlmInference.createFromOptions(genai, {
    baseOptions: {
        modelAssetPath: '/assets/gemma-3n-E4B-it-int4-Web.litertlm'
    },
    maxTokens: 1000,
    topK: 40,
    temperature: 0.8,
    randomSeed: 101,
    maxNumImages: 5,
    supportAudio: true,
});
```

Responses can now be generated as before, but using an ordered array of strings, images, and audio data:

```javascript
const response = await llmInference.generateResponse([
  '<start_of_turn>user\n',
  'Describe ',
  {imageSource: '/assets/test_image.png'},
  ' and then transcribe ',
  {audioSource: '/assets/test_audio.wav'},
  '<end_of_turn>\n<start_of_turn>model\n',
]);
```

**Note:** All of our web-converted instruction-tuned Gemma models follow the same [prompt template](https://ai.google.dev/gemma/docs/core/prompt-structure).

For vision, image URLs and most common image, video, or canvas objects are supported. For audio, only single-channel AudioBuffer and mono-channel audio file URLs are supported. More details can be found by browsing the [source code](https://cs.opensource.google/mediapipe/mediapipe/+/master:mediapipe/web/graph_runner/graph_runner_llm_inference_lib.ts).

## Sample application

The sample application is an example of a basic text generation app for Web, using the LLM Inference API. You can use the app as a starting point for your own Web app, or refer to it when modifying an existing app. The example code is hosted on [GitHub](https://github.com/google-ai-edge/mediapipe-samples/tree/main/examples/llm_inference/js).

Clone the git repository using the following command:

git clone https://github.com/google-ai-edge/mediapipe-samples

For more information, see the [Setup Guide for Web](/mediapipe/solutions/setup_web).

## Configuration options

Use the following configuration options to set up a Web app:

| Option Name | Description | Value Range | Default Value |
| --- | --- | --- | --- |
| modelPath | The path to where the model is stored within the project directory. | PATH | N/A |
| maxTokens | The maximum number of tokens (input tokens + output tokens) the model handles. | Integer | 512 |
| topK | The number of tokens the model considers at each step of generation. Limits predictions to the top k most-probable tokens. | Integer | 40 |
| temperature | The amount of randomness introduced during generation. A higher temperature results in more creativity in the generated text, while a lower temperature produces more predictable generation. | Float | 0.8 |
| randomSeed | The random seed used during text generation. | Integer | 0 |
| loraRanks | LoRA ranks to be used by the LoRA models during runtime. Note: this is only compatible with GPU models. | Integer array | N/A |

## Model conversion

The LLM Inference API is compatible with the following types of models, some of which require model conversion. Use the table to identify the required steps method for your model.

| Models | Conversion method | Compatible platforms | File type |
| --- | --- | --- | --- |
| Gemma-3 1B | No conversion required | Android, web | . |
| Gemma 2B, Gemma 7B, Gemma-2 2B | No conversion required | Android, iOS, web | .bin |
| Phi-2, StableLM, Falcon | MediaPipe conversion script | Android, iOS, web | .bin |
| All PyTorch LLM models | AI Edge Torch Generative library | Android, iOS | . |

To learn how you can convert other models, see the [Model Conversion](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/index#convert-model) section.

## LoRA customization

The LLM Inference API supports LoRA (Low-Rank Adaptation) tuning using the [PEFT](https://huggingface.co/docs/peft/main/en/index) (Parameter-Efficient Fine-Tuning) library. LoRA tuning customizes the behavior of LLMs through a cost-effective training process, creating a small set of trainable weights based on new training data rather than retraining the entire model.

The LLM Inference API supports adding LoRA weights to attention layers of the [Gemma-2 2B](https://huggingface.co/google/gemma-2-2b), [Gemma 2B](https://huggingface.co/google/gemma-2b) and [Phi-2](https://huggingface.co/microsoft/phi-2) models. Download the model in the `safetensors` format.

The base model must be in the `safetensors` format in order to create LoRA weights. After LoRA training, you can convert the models into the FlatBuffers format to run on MediaPipe.

### Prepare LoRA weights

Use the [LoRA Methods](https://huggingface.co/docs/peft/main/en/task_guides/lora_based_methods) guide from PEFT to train a fine-tuned LoRA model on your own dataset.

The LLM Inference API only supports LoRA on attention layers, so only specify the attention layers in `LoraConfig`:

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

After training on the prepared dataset and saving the model, the fine-tuned LoRA model weights are available in `adapter_model.safetensors`. The `safetensors` file is the LoRA checkpoint used during model conversion.

### Model conversion

Use the MediaPipe Python Package to convert the model weights into the Flatbuffer format. The `ConversionConfig` specifies the base model options along with the additional LoRA options.

**Note:** Since the API only supports LoRA inference with GPU, the backend must be set to `'gpu'`.

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
  lora_output_tflite_file=LORA_OUTPUT_FILE,
)

converter.convert_checkpoint(config)
```

The converter will produce two MediaPipe-compatible files, one for the base model and another for the LoRA model.

### LoRA model inference

Web supports dynamic LoRA during runtime, meaning users declare the LoRA ranks during initialization. This means you can swap out different LoRA models during runtime.

```javascript
const genai = await FilesetResolver.forGenAiTasks(
    // path/to/wasm/root
    "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai@latest/wasm"
);
const llmInference = await LlmInference.createFromOptions(genai, {
    // options for the base model
    ...
    // LoRA ranks to be used by the LoRA models during runtime
    loraRanks: [4, 8, 16]
});
```

Load the LoRA models during runtime, after initializing the base model. Trigger the LoRA model by passing the model reference when generating the LLM response.

```javascript
// Load several LoRA models. The returned LoRA model reference is used to specify
// which LoRA model to be used for inference.
loraModelRank4 = await llmInference.loadLoraModel(loraModelRank4Url);
loraModelRank8 = await llmInference.loadLoraModel(loraModelRank8Url);

// Specify LoRA model to be used during inference
llmInference.generateResponse(
  inputPrompt,
  loraModelRank4,
  (partialResult, done) => {
        document.getElementById('output').textContent += partialResult;
});
```
