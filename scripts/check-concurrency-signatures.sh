#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Linux)
    swiftc \
      -typecheck \
      -parse-as-library \
      -swift-version 6 \
      -strict-concurrency=complete \
      -warnings-as-errors \
      "${ROOT_DIR}/Fixtures/Concurrency/Signatures.swift"

    echo "concurrency signature check passed"
    exit 0
    ;;
  Darwin) ;;
  *)
    echo "error: check-concurrency-signatures.sh supports only Linux and macOS hosts" >&2
    exit 1
    ;;
esac

readonly SWIFT_IMAGE="${SWIFT_IMAGE:-docker.io/library/swift:6.4.0-noble}"
readonly CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-swift-multiarray-concurrency-signatures}"

exec podman run --rm \
  --hostname "${CONTAINER_HOSTNAME}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  "${SWIFT_IMAGE}" \
  scripts/check-concurrency-signatures.sh
