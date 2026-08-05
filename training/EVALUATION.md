# Adapter release gate

An adapter is not production-ready merely because training loss decreased.
Evaluate on records excluded by `source_id`, plus an independent challenge set
written after training.

Required per subject before release:

- At least 100 expert-reviewed held-out items and 50 adversarial challenge items.
- 100% correct final option/value on deterministic MCQs and numerical problems.
- At least 95% on a two-reviewer explanation rubric covering method, units,
  assumptions, clarity, and syllabus relevance.
- Zero invented sources, fake past-paper claims, unsafe medical advice, or
  unsupported exam rules.
- No regression greater than two percentage points on the other three subjects
  after adapters are merged or composed.
- Re-test the final quantized GGUF on representative low-memory Android devices;
  evaluation of the unquantized training checkpoint is not sufficient.

Store the signed evaluation report, dataset manifest hash, exact base-model
revision, adapter hash, GGUF hash, reviewers, and approval date with every app
release. Failed models must not be merged into the GGUF shipped in
`assets/models/` or included in production builds.
