"""Train audited per-subject QLoRA adapters on Modal GPUs."""

from __future__ import annotations

import json
from pathlib import Path

import modal

APP_NAME = "shikshapul-subject-adapters"
BASE_MODEL = "Qwen/Qwen2.5-0.5B-Instruct"
BASE_REVISION = "c89bee90d9f811437d9735454613c35b4a3c4dc8"
SUBJECTS = ("physics", "chemistry", "mathematics", "biology")
MIN_TRAIN = 500
MIN_EVAL = 100

app = modal.App(APP_NAME)
volume = modal.Volume.from_name("shikshapul-adapters", create_if_missing=True)
image = (
    modal.Image.debian_slim(python_version="3.12")
    .pip_install(
        "torch==2.7.1",
        "transformers==4.53.2",
        "datasets==4.0.0",
        "trl==0.19.1",
        "peft==0.16.0",
        "accelerate==1.8.1",
        "bitsandbytes==0.46.1",
    )
    .add_local_dir("training/data", remote_path="/data", copy=True)
)


@app.function(
    image=image,
    gpu="A10G",
    timeout=60 * 60 * 4,
    volumes={"/artifacts": volume},
)
def train_subject(subject: str) -> dict:
    import torch
    from datasets import load_dataset
    from peft import LoraConfig
    from transformers import (
        AutoModelForCausalLM,
        AutoTokenizer,
        BitsAndBytesConfig,
    )
    from trl import SFTConfig, SFTTrainer

    if subject not in SUBJECTS:
        raise ValueError(f"Unsupported subject: {subject}")

    dataset = load_dataset(
        "json",
        data_files={
            "train": "/data/processed/train.jsonl",
            "eval": "/data/processed/eval.jsonl",
        },
    )
    dataset = dataset.filter(lambda row: row["subject"] == subject)
    if len(dataset["train"]) < MIN_TRAIN or len(dataset["eval"]) < MIN_EVAL:
        raise ValueError(
            f"{subject} needs at least {MIN_TRAIN} verified train and "
            f"{MIN_EVAL} verified eval records; found "
            f"{len(dataset['train'])}/{len(dataset['eval'])}"
        )

    tokenizer = AutoTokenizer.from_pretrained(
        BASE_MODEL, revision=BASE_REVISION, use_fast=True
    )
    tokenizer.pad_token = tokenizer.eos_token

    def format_row(row: dict) -> dict:
        messages = [
            {
                "role": "system",
                "content": (
                    "You are a careful Nepal entrance tutor. Explain only verified "
                    "content, show calculations step by step, and state uncertainty."
                ),
            },
            {"role": "user", "content": row["prompt"]},
            {"role": "assistant", "content": row["response"]},
        ]
        return {
            "text": tokenizer.apply_chat_template(
                messages, tokenize=False, add_generation_prompt=False
            )
        }

    dataset = dataset.map(format_row)
    model = AutoModelForCausalLM.from_pretrained(
        BASE_MODEL,
        revision=BASE_REVISION,
        quantization_config=BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_compute_dtype=torch.bfloat16,
        ),
        device_map="auto",
    )
    output_dir = f"/artifacts/{subject}"
    trainer = SFTTrainer(
        model=model,
        processing_class=tokenizer,
        train_dataset=dataset["train"],
        eval_dataset=dataset["eval"],
        peft_config=LoraConfig(
            r=16,
            lora_alpha=32,
            lora_dropout=0.05,
            bias="none",
            task_type="CAUSAL_LM",
            target_modules="all-linear",
            modules_to_save=["lm_head", "embed_tokens"],
        ),
        args=SFTConfig(
            output_dir=output_dir,
            dataset_text_field="text",
            max_length=1024,
            packing=True,
            eos_token="<|im_end|>",
            num_train_epochs=2,
            per_device_train_batch_size=8,
            per_device_eval_batch_size=8,
            gradient_accumulation_steps=4,
            learning_rate=1e-4,
            warmup_ratio=0.05,
            logging_steps=10,
            eval_strategy="steps",
            eval_steps=50,
            save_steps=50,
            save_total_limit=2,
            load_best_model_at_end=True,
            metric_for_best_model="eval_loss",
            greater_is_better=False,
            bf16=True,
            report_to="none",
            seed=20260805,
        ),
    )
    trainer.train()
    metrics = trainer.evaluate()
    trainer.save_model(output_dir)
    tokenizer.save_pretrained(output_dir)
    report = {
        "subject": subject,
        "base_model": BASE_MODEL,
        "base_revision": BASE_REVISION,
        "train_records": len(dataset["train"]),
        "eval_records": len(dataset["eval"]),
        "metrics": metrics,
    }
    Path(f"{output_dir}/metrics.json").write_text(json.dumps(report, indent=2))
    volume.commit()
    return {"subject": subject, "output": output_dir, "metrics": metrics}


@app.local_entrypoint()
def main() -> None:
    for result in train_subject.map(SUBJECTS):
        print(json.dumps(result, indent=2))
