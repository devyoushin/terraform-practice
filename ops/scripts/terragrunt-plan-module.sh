#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"

if [[ -z "$target" ]]; then
  echo "usage: $0 <ops/live/nonprod/ap-northeast-2/dev/module|ops/live/prod/ap-northeast-2/prod/module>"
  exit 2
fi

cd "$target"
terragrunt init
terragrunt plan
