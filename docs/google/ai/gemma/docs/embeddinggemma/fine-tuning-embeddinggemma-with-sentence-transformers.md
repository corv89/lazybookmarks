---
Source: https://ai.google.dev/gemma/docs/embeddinggemma/fine-tuning-embeddinggemma-with-sentence-transformers
Generated: 2026-01-05
Updated: 2026-01-05
---

| View on ai.google.dev | Run in Google Colab | Run in Kaggle | Open in Vertex AI | View source on GitHub |
| --- | --- | --- | --- | --- |

Fine-tuning helps close the gap between a model's general-purpose understanding and the specialized, high-performance accuracy that your application requires. Since no single model is perfect for every , fine-tuning adapts it to your specific domain.

Imagine your company, "Shibuya Financial" offers various complex financial products like investment trusts, NISA accounts (a tax-advantaged savings account), and home loans. Your customer support team uses an internal knowledge base to quickly find answers to customer questions.

## Setup

Before starting this tutorial, complete the following steps:

-   Get access to EmbeddingGemma by logging into [Hugging Face](https://huggingface.co/google/embeddinggemma-300M) and selecting **Acknowledge license** for a Gemma model.
-   Generate a Hugging Face [Access Token](https://huggingface.co/docs/hub/en/security-tokens#how-to-manage-user-access-token) and use it to login from Colab.

This notebook will run on either CPU or GPU.

### Install Python packages

Install the libraries required for running the EmbeddingGemma model and generating embeddings. Sentence Transformers is a Python framework for text and image embeddings. For more information, see the [Sentence Transformers](https://www.sbert.net/) documentation.

```
pip install -U sentence-transformers git+https://github.com/huggingface/transformers@v4.56.0-Embedding-Gemma-preview
```

After you have accepted the license, you need a valid Hugging Face Token to access the model.

```bash

# Login into Hugging Face Hub
from huggingface_hub import login
login()
```

### Load Model

Use the `sentence-transformers` libraries to create an instance of a model class with EmbeddingGemma.

```python
import torch
from sentence_transformers import SentenceTransformer

device = "cuda" if torch.cuda.is_available() else "cpu"

model_id = "google/embeddinggemma-300M"
model = SentenceTransformer(model_id).to(device=device)

print(f"Device: {model.device}")
print(model)
print("Total number of parameters in the model:", sum([p.numel() for _, p in model.named_parameters()]))
```

Device: cuda:0
SentenceTransformer(
  (0): Transformer({'max\_seq\_length': 2048, 'do\_lower\_case': False, 'architecture': 'Gemma3TextModel'})
  (1): Pooling({'word\_embedding\_dimension': 768, 'pooling\_mode\_cls\_token': False, 'pooling\_mode\_mean\_tokens': True, 'pooling\_mode\_max\_tokens': False, 'pooling\_mode\_mean\_sqrt\_len\_tokens': False, 'pooling\_mode\_weightedmean\_tokens': False, 'pooling\_mode\_lasttoken': False, 'include\_prompt': True})
  (2): Dense({'in\_features': 768, 'out\_features': 3072, 'bias': False, 'activation\_function': 'torch.nn.modules.linear.Identity'})
  (3): Dense({'in\_features': 3072, 'out\_features': 768, 'bias': False, 'activation\_function': 'torch.nn.modules.linear.Identity'})
  (4): Normalize()
)
Total number of parameters in the model: 307581696

## Prepare the Fine-Tuning Dataset

This is the most crucial part. You need to create a dataset that teaches the model what "similar" means in your specific context. This data is often structured as triplets: (anchor, positive, negative)

-   Anchor: The original query or sentence.
-   Positive: A sentence that is semantically very similar or identical to the anchor.
-   Negative: A sentence that is on a related topic but semantically distinct.

In this example, we only prepared 3 triplets, but for a real application, you would need a much larger dataset to perform well.

```python
from datasets import Dataset

dataset = [
    ["How do I open a NISA account?", "What is the procedure for starting a new tax-free investment account?", "I want to check the balance of my regular savings account."],
    ["Are there fees for making an early repayment on a home loan?", "If I pay back my house loan early, will there be any costs?", "What is the management fee for this investment trust?"],
    ["What is the coverage for medical insurance?", "Tell me about the benefits of the health insurance plan.", "What is the cancellation policy for my life insurance?"],
]

# Convert the list-based dataset into a list of dictionaries.
data_as_dicts = [ {"anchor": row[0], "positive": row[1], "negative": row[2]} for row in dataset ]

# Create a Hugging Face `Dataset` object from the list of dictionaries.
train_dataset = Dataset.from_list(data_as_dicts)
print(train_dataset)
```

Dataset({
    features: \['anchor', 'positive', 'negative'\],
    num\_rows: 3
})

## Before Fine-Tuning

A search for "tax-free investment" might have given the following results, with similarity scores:

1.  Document: Opening a NISA account (Score: 0.51)
2.  Document: Opening a Regular Saving Account (Score: 0.50) <- *Similar score, potentially confusing*
3.  Document: Home Loan Application Guide (Score: 0.44)

> **Note:** To generate optimal embeddings with EmbeddingGemma, you should add an "instructional prompt" or "" to the beginning of your input text. You will use `STS` for sentence similarity. For details on all available EmbeddingGemma prompts, see the [model card](http://ai.google.dev/gemma/docs/embeddinggemma/model_card#prompt_instructions).

```python
task_name = "STS"

def get_scores(query, documents):
  # Calculate embeddings by calling model.encode()
  query_embeddings = model.encode(query, prompt_name=task_name)
  doc_embeddings = model.encode(documents, prompt_name=task_name)

  # Calculate the embedding similarities
  similarities = model.similarity(query_embeddings, doc_embeddings)

  for idx, doc in enumerate(documents):
    print("Document: ", doc, "-> 🤖 Score: ", similarities.numpy()[0][idx])

query = "I want to start a tax-free installment investment, what should I do?"
documents = ["Opening a NISA Account", "Opening a Regular Savings Account", "Home Loan Application Guide"]

get_scores(query, documents)
```

Document:  Opening a NISA Account -> 🤖 Score:  0.51571906
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.5035889
Document:  Home Loan Application Guide -> 🤖 Score:  0.4406476

## Training

Using a framework like `sentence-transformers` in Python, the base model gradually learns the subtle distinctions in your financial vocabulary.

```python
from sentence_transformers import SentenceTransformerTrainer, SentenceTransformerTrainingArguments
from sentence_transformers.losses import MultipleNegativesRankingLoss
from transformers import TrainerCallback

loss = MultipleNegativesRankingLoss(model)

args = SentenceTransformerTrainingArguments(
    # Required parameter:
    output_dir="my-embedding-gemma",
    # Optional training parameters:
    prompts=model.prompts[task_name],    # use model's prompt to train
    num_train_epochs=5,
    per_device_train_batch_size=1,
    learning_rate=2e-5,
    warmup_ratio=0.1,
    # Optional tracking/debugging parameters:
    logging_steps=train_dataset.num_rows,
    report_to="none",
)

class MyCallback(TrainerCallback):
    "A callback that evaluates the model at the end of eopch"
    def __init__(self, evaluate):
        self.evaluate = evaluate # evaluate function

    def on_log(self, args, state, control, **kwargs):
        # Evaluate the model using text generation
        print(f"Step {state.global_step} finished. Running evaluation:")
        self.evaluate()

def evaluate():
  get_scores(query, documents)

trainer = SentenceTransformerTrainer(
    model=model,
    args=args,
    train_dataset=train_dataset,
    loss=loss,
    callbacks=[MyCallback(evaluate)]
)
trainer.train()
```

Step 3 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.6459116
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.42690125
Document:  Home Loan Application Guide -> 🤖 Score:  0.40419024
Step 6 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.68530923
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.3611964
Document:  Home Loan Application Guide -> 🤖 Score:  0.40812016
Step 9 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.7168733
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.3449782
Document:  Home Loan Application Guide -> 🤖 Score:  0.44477722
Step 12 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.73008573
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.34124148
Document:  Home Loan Application Guide -> 🤖 Score:  0.4676212
Step 15 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.73378766
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.34055778
Document:  Home Loan Application Guide -> 🤖 Score:  0.47503752
Step 15 finished. Running evaluation:
Document:  Opening a NISA Account -> 🤖 Score:  0.73378766
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.34055778
Document:  Home Loan Application Guide -> 🤖 Score:  0.47503752
TrainOutput(global\_step=15, training\_loss=0.009651267528511198, metrics={'train\_runtime': 195.3004, 'train\_samples\_per\_second': 0.077, 'train\_steps\_per\_second': 0.077, 'total\_flos': 0.0, 'train\_loss': 0.009651267528511198, 'epoch': 5.0})

## After Fine-Tuning

The same search now yields much clearer results:

1.  Document: Opening a NISA account (Score: 0.73) <- *Much more confident*
2.  Document: Opening a Regular Saving Account (Score: 0.34) <- *Clearly less relevant*
3.  Document: Home Loan Application Guide (Score: 0.47)

```
get_scores(query, documents)
```

Document:  Opening a NISA Account -> 🤖 Score:  0.73378766
Document:  Opening a Regular Savings Account -> 🤖 Score:  0.34055778
Document:  Home Loan Application Guide -> 🤖 Score:  0.47503752

To upload your model to the Hugging Face Hub, you can use the `push_to_hub` method from the Sentence Transformers library.

Uploading your model makes it easy to access for inference directly from the Hub, share with others, and version your work. Once uploaded, anyone can load your model with a single line of code, simply by referencing its unique model ID `<username>/my-embedding-gemma`

```bash

# Push to Hub
model.push_to_hub("my-embedding-gemma")
```

## Summary and next steps

You have now learned how to adapt an EmbeddingGemma model for a specific domain by fine-tuning it with the Sentence Transformers library.

Explore what more you can do with EmbeddingGemma:

-   [Training Overview](https://sbert.net/docs/sentence_transformer/training_overview.html) in Sentence Transformers Documentation
-   [Generate embeddings with Sentence Transformers](https://ai.google.dev/gemma/docs/embeddinggemma/inference-embeddinggemma-with-sentence-transformers)
-   [Simple RAG example](https://github.com/google-gemini/gemma-cookbook/blob/main/Gemma/%5BGemma_3%5DRAG_with_EmbeddingGemma.ipynb) in the Gemma Cookbook
