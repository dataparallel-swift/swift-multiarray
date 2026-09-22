#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v rg >/dev/null 2>&1; then
  echo "error: preflight requires rg (ripgrep)" >&2
  exit 1
fi
if ! command -v swiftformat >/dev/null 2>&1; then
  echo "error: preflight requires SwiftFormat (the swiftformat executable)" >&2
  exit 1
fi
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "error: preflight requires SwiftLint (the swiftlint executable)" >&2
  exit 1
fi

printf 'preflight: checking lint\n'
swiftlint --quiet --no-cache \
  "${ROOT_DIR}/Package.swift" \
  "${ROOT_DIR}/Sources" \
  "${ROOT_DIR}/Tests" \
  "${ROOT_DIR}/Benchmarks" \
  "${ROOT_DIR}/Snippets"

printf 'preflight: checking formatting\n'
swiftformat --lint --cache ignore \
  "${ROOT_DIR}/Package.swift" \
  "${ROOT_DIR}/Sources" \
  "${ROOT_DIR}/Tests" \
  "${ROOT_DIR}/Benchmarks" \
  "${ROOT_DIR}/Snippets"

echo "preflight: checking shell syntax"
while IFS= read -r script; do
  bash -n "${script}"
done < <(rg --files scripts -g '*.sh' | sort)

echo "preflight: checking conflict markers and whitespace errors"
git diff --check

echo "preflight passed"
