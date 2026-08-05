# ShikshaPul subject-adapter pipeline

This directory trains four LoRA adapters: Physics, Chemistry, Mathematics, and
Biology. It deliberately refuses unlicensed or unreviewed material. A model
trained on plausible-looking generated answers is not safe for exam preparation.

## Required source data

Place newline-delimited JSON in `training/data/source.jsonl`. Every record must
contain:

```json
{"id":"unique-id","subject":"physics","topic_id":"PHYS_KIN","prompt":"student question","response":"expert-verified worked answer","source_id":"licensed-book-or-paper-id","source_url":"https://...","license":"permission or license identifier","reviewer":"reviewer name/id","expert_verified":true}
```

Allowed subjects are `physics`, `chemistry`, `mathematics`, and `biology`.
Do not copy copyrighted past papers without permission. Keep source and reviewer
records so every training item is auditable.

## Validate and split

```bash
python3 training/prepare_dataset.py \
  --input training/data/source.jsonl \
  --output training/data/processed
```

The split is grouped by `source_id`, preventing questions from the same paper or
book leaking into both train and evaluation sets. The command writes a manifest
with rejection reasons and subject counts.

## Train on Modal

Install and authenticate the Modal CLI, then run:

```bash
modal run training/train_adapters_modal.py
```

The job trains one adapter per subject on a GPU and stores checkpoints in the
`shikshapul-adapters` Modal Volume. Training is intentionally blocked when a
subject lacks enough verified train and evaluation examples.

After training, evaluate each adapter against a teacher-approved held-out set.
Only adapters meeting the documented factual-accuracy threshold may proceed.

The app currently uses `llama_flutter_android` 0.2.6, whose public Dart API does
not load or switch LoRA adapters. Therefore the deployable artifact must be made
offline: merge the approved subject adapters into the **exact** Qwen 2.5 0.5B
base model, run the combined held-out evaluation again, quantize that merged
model to GGUF, and replace `assets/models/qwen-0.5b-q3_k_m.gguf`. Update
`assets/models/model_manifest.json` with the new hash, licenses, evaluation
report, and reviewer sign-off. Do not place unused adapters in the app bundle.

Adapter training does not itself prove educational quality, and an adapter that
passes alone can still fail after merging or quantization.

References: [Modal fine-tuning examples](https://modal.com/docs/examples/llm-finetuning),
[KU official KUCAT syllabus](https://apply.ku.edu.np/syllabi/2026/Test_Syllabus_2026.pdf).
