#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"

if [[ -z "$target" ]]; then
  echo "usage: $0 <ops/dev/module|ops/prod/module>"
  exit 2
fi

cd "$target"
terragrunt init
terragrunt plan
