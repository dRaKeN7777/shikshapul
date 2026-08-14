#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
model_dir="$repo_root/assets/models"
model_path="$model_dir/qwen-0.5b-q3_k_m.gguf"
partial_path="$model_path.part"
expected_sha="590d2479d401db206fe12a4562294d2de6211e06338a6e34fbad64b32f1469d0"
model_url="https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q3_k_m.gguf?download=true"

mkdir -p "$model_dir"

if [[ -f "$model_path" ]] && [[ "$(shasum -a 256 "$model_path" | awk '{print $1}')" == "$expected_sha" ]]; then
  echo "Verified model already present: $model_path"
  exit 0
fi

rm -f "$partial_path"
curl -L --fail --retry 3 --progress-bar "$model_url" -o "$partial_path"

actual_sha="$(shasum -a 256 "$partial_path" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
  rm -f "$partial_path"
  echo "Model checksum mismatch: expected $expected_sha, got $actual_sha" >&2
  exit 1
fi

mv "$partial_path" "$model_path"
echo "Downloaded and verified: $model_path"
