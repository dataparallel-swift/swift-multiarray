#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Linux)
    SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-${ROOT_DIR}/.build}"
    exec swift build \
      --package-path "${ROOT_DIR}" \
      --scratch-path "${SWIFT_SCRATCH_PATH}" \
      --configuration release \
      "$@"
    ;;
  Darwin) ;;
  *)
    echo "error: build-linux.sh supports only Linux and macOS hosts" >&2
    exit 1
    ;;
esac

readonly SWIFT_IMAGE="${SWIFT_IMAGE:-docker.io/library/swift:6.3.3-noble}"
readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-/workspace/.build}"
readonly CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-swift-multiarray-builder}"

exec podman run --rm \
  --hostname "${CONTAINER_HOSTNAME}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  --env SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH}" \
  "${SWIFT_IMAGE}" \
  scripts/build-linux.sh \
  "$@"
