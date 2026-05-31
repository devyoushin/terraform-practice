#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-dev}"

case "$env_name" in
  dev|prod) ;;
  *)
    echo "usage: $0 <dev|prod>"
    exit 2
    ;;
esac

terragrunt run-all plan --terragrunt-working-dir "ops/${env_name}"
