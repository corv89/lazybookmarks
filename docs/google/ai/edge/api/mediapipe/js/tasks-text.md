---
Source: https://ai.google.dev/edge/api/mediapipe/js/tasks-text
Generated: 2026-01-05
Updated: 2026-01-05
---

## Classes

| Class | Description |
| --- | --- |
| FilesetResolver | Resolves the files required for the MediaPipe Task APIs.This class verifies whether SIMD is supported in the current environment and loads the SIMD files only if support is detected. The returned filesets require that the Wasm files are published without renaming. If this is not possible, you can invoke the MediaPipe Tasks APIs using a manually created WasmFileset. |
| LanguageDetector | Predicts the language of an input text. |
| TextClassifier | Performs Natural Language classification. |
| TextEmbedder | Performs embedding extraction on text. |

## Interfaces

| Interface | Description |
| --- | --- |
| Category | A classification category. |
| Classifications | Classification results for a given classifier head. |
| Embedding | List of embeddings with an optional timestamp.One and only one of the two 'floatEmbedding' and 'quantizedEmbedding' will contain data, based on whether or not the embedder was configured to perform scalar quantization. |
| LanguageDetectorOptions | Options to configure the MediaPipe Language Detector Task |
| LanguageDetectorPrediction | A language code and its probability. |
| LanguageDetectorResult | The result of language detection. |
| TextClassifierOptions | Options to configure the MediaPipe Text Classifier Task |
| TextClassifierResult | Classification results of a model. |
| TextEmbedderOptions | Options to configure the MediaPipe Text Embedder Task |
| TextEmbedderResult | Embedding results for a given embedder model. |
