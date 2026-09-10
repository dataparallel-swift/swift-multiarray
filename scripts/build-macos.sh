#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRATCH_PATH="${MULTIARRAY_SCRATCH_PATH:-/tmp/swift-multiarray-macos-release}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: build-macos.sh requires a macOS host" >&2
  exit 1
fi

exec swift build \
  --package-path "${ROOT_DIR}" \
  --scratch-path "${SCRATCH_PATH}" \
  --configuration release \
  "$@"
