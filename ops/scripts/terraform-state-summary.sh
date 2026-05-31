#!/usr/bin/env bash
set -euo pipefail

terraform state list \
  | sed -E 's/\[[0-9]+\]//' \
  | sort \
  | uniq -c \
  | sort -nr
