#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "error: format requires SwiftFormat (the swiftformat executable)" >&2
  exit 1
fi

echo "format: formatting maintained Swift sources"
swiftformat --cache ignore \
  "${ROOT_DIR}/Package.swift" \
  "${ROOT_DIR}/Sources" \
  "${ROOT_DIR}/Tests" \
  "${ROOT_DIR}/Benchmarks" \
  "${ROOT_DIR}/Snippets"

echo "format complete"
