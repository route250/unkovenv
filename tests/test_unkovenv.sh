#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=tests/common.sh
source "$TEST_DIR/common.sh"

for f in "$TEST_DIR"/categories/*.sh; do
  # shellcheck disable=SC1090
  source "$f"
done

main() {
  init_suite

  local category_fn
  for category_fn in "${CATEGORIES[@]}"; do
    "$category_fn"
  done

  finish_suite
}

main "$@"