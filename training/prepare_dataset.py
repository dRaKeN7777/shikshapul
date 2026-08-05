#!/usr/bin/env python3
"""Validate licensed tutoring records and create leakage-safe train/eval sets."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse

SUBJECTS = {"physics", "chemistry", "mathematics", "biology"}
TOPIC_PREFIX = {
    "physics": "PHYS_",
    "chemistry": "CHEM_",
    "mathematics": "MATH_",
    "biology": "BIO_",
}
REQUIRED = {
    "id",
    "subject",
    "topic_id",
    "prompt",
    "response",
    "source_id",
    "source_url",
    "license",
    "reviewer",
    "expert_verified",
}


def split_for(source_id: str) -> str:
    bucket = int(hashlib.sha256(source_id.encode()).hexdigest()[:8], 16) % 10
    return "eval" if bucket == 0 else "train"


def validate(record: object) -> str | None:
    if not isinstance(record, dict):
        return "record_not_object"
    missing = sorted(REQUIRED - record.keys())
    if missing:
        return f"missing:{','.join(missing)}"
    if record["subject"] not in SUBJECTS:
        return "invalid_subject"
    if not str(record["topic_id"]).startswith(TOPIC_PREFIX[record["subject"]]):
        return "topic_subject_mismatch"
    if record["expert_verified"] is not True:
        return "not_expert_verified"
    license_id = str(record["license"]).strip()
    if license_id.lower() in {"", "unknown", "none", "unlicensed"}:
        return "missing_or_invalid_license"
    if len(str(record["reviewer"]).strip()) < 3:
        return "missing_license_or_reviewer"
    source_url = urlparse(str(record["source_url"]).strip())
    if source_url.scheme not in {"http", "https"} or not source_url.netloc:
        return "invalid_source_url"
    if not str(record["source_id"]).strip():
        return "missing_source_id"
    if len(str(record["prompt"]).strip()) < 12:
        return "prompt_too_short"
    if len(str(record["response"]).strip()) < 40:
        return "response_too_short"
    return None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    accepted: dict[str, list[dict]] = {"train": [], "eval": []}
    rejected = Counter()
    seen_ids: set[str] = set()
    seen_content: set[str] = set()

    with args.input.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                rejected["invalid_json"] += 1
                continue
            reason = validate(record)
            if not isinstance(record, dict):
                rejected[reason or "record_not_object"] += 1
                continue
            if str(record.get("id")) in seen_ids:
                reason = "duplicate_id"
            content_key = hashlib.sha256(
                (
                    str(record.get("prompt", "")).strip().casefold()
                    + "\n"
                    + str(record.get("response", "")).strip().casefold()
                ).encode()
            ).hexdigest()
            if content_key in seen_content:
                reason = "duplicate_content"
            if reason:
                rejected[reason] += 1
                continue
            seen_ids.add(str(record["id"]))
            seen_content.add(content_key)
            split = split_for(str(record["source_id"]))
            accepted[split].append(record)

    for split, records in accepted.items():
        with (args.output / f"{split}.jsonl").open("w", encoding="utf-8") as out:
            for record in records:
                out.write(json.dumps(record, ensure_ascii=False) + "\n")

    manifest = {
        "accepted": {key: len(value) for key, value in accepted.items()},
        "subjects": {
            split: dict(Counter(row["subject"] for row in rows))
            for split, rows in accepted.items()
        },
        "rejected": dict(rejected),
        "split_policy": "sha256(source_id) modulo 10; bucket 0 is eval",
        "input_sha256": hashlib.sha256(args.input.read_bytes()).hexdigest(),
    }
    (args.output / "manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
