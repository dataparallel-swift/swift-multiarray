#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Linux)
    readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-${ROOT_DIR}/.build}"
    swift build \
      --package-path "${ROOT_DIR}" \
      --scratch-path "${SWIFT_SCRATCH_PATH}" \
      --configuration release \
      --target MultiArray

    readonly BUILD_DIR="$(
      swift build \
        --package-path "${ROOT_DIR}" \
        --scratch-path "${SWIFT_SCRATCH_PATH}" \
        --configuration release \
        --target MultiArray \
        --show-bin-path
    )"
    if [[ -e "${BUILD_DIR}/Modules/MultiArray.swiftmodule" ]]; then
      readonly MODULE_DIR="${BUILD_DIR}/Modules"
    else
      readonly MODULE_DIR="${BUILD_DIR}"
    fi
    if [[ ! -e "${MODULE_DIR}/MultiArray.swiftmodule" ]]; then
      echo "error: could not find the built MultiArray module" >&2
      exit 1
    fi

    # A positive client typecheck cannot distinguish `sending` from an ordinary
    # closure parameter on all supported compilers. Guard that source-level
    # modifier explicitly, while the client checks the actual built API.
    if ! grep -Fq 'initializingWith body: sending(' \
      "${ROOT_DIR}/Sources/MultiArray/Extensions/MultiArray+async.swift"; then
      echo "error: async initializer lost its sending body parameter" >&2
      exit 1
    fi

    readonly -a SWIFTC_ARGS=(
      -typecheck
      -parse-as-library
      -swift-version 6
      -strict-concurrency=complete
      -warnings-as-errors
      -I "${MODULE_DIR}"
    )

    swiftc "${SWIFTC_ARGS[@]}" "${ROOT_DIR}/Fixtures/Concurrency/Signatures.swift"

    if diagnostics="$(swiftc "${SWIFTC_ARGS[@]}" "${ROOT_DIR}/Fixtures/Concurrency/NonSendableBuffer.swift" 2>&1)"; then
      echo "error: non-Sendable initialization buffer unexpectedly compiled" >&2
      exit 1
    fi
    if ! grep -Fq 'Sendable' <<<"${diagnostics}"; then
      echo "error: non-Sendable initialization buffer failed without a Sendable diagnostic" >&2
      echo "${diagnostics}" >&2
      exit 1
    fi

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
readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-/workspace/.build}"
readonly CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-swift-multiarray-concurrency-signatures}"

exec podman run --rm \
  --hostname "${CONTAINER_HOSTNAME}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  --env SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH}" \
  "${SWIFT_IMAGE}" \
  scripts/check-concurrency-signatures.sh
