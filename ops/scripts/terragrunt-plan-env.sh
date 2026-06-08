#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-dev}"

case "$env_name" in
  dev)
    workdir="ops/live/nonprod/ap-northeast-2/dev"
    ;;
  prod)
    workdir="ops/live/prod/ap-northeast-2/prod"
    ;;
  *)
    echo "usage: $0 <dev|prod>"
    exit 2
    ;;
esac

terragrunt run-all plan --terragrunt-working-dir "${workdir}"
