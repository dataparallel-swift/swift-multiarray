#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Foundation Process.run() leaks weak-reference bookkeeping on Linux Swift 6.4.
# These compiler subprocess tests still run in the normal debug/release suites;
# exclude only them here, keeping leak detection enabled for library storage.
exec "${ROOT_DIR}/scripts/test-linux.sh" \
  --sanitize address \
  --skip MacroDiagnosticCompilationTests \
  "$@"
