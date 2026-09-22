#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Linux)
    readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-${ROOT_DIR}/.build}"
    readonly FIXTURE_DIR="${ROOT_DIR}/Fixtures/Sendability"
    readonly TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TEMP_DIR}"' EXIT

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
    if [[ -x "${BUILD_DIR}/MultiArrayMacros-tool" ]]; then
      readonly PLUGIN_PATH="${BUILD_DIR}/MultiArrayMacros-tool"
    else
      readonly PLUGIN_PATH="${BUILD_DIR}/MultiArrayMacros"
    fi
    if [[ ! -e "${MODULE_DIR}/MultiArray.swiftmodule" || ! -x "${PLUGIN_PATH}" ]]; then
      echo "error: could not find the built MultiArray module and macro plugin" >&2
      exit 1
    fi

    readonly -a SWIFTC_ARGS=(
      -typecheck
      -parse-as-library
      -swift-version 6
      -strict-concurrency=complete
      -warnings-as-errors
      -I "${MODULE_DIR}"
      -load-plugin-executable "${PLUGIN_PATH}#MultiArrayMacros"
      "${FIXTURE_DIR}/Support.swift"
    )

    swiftc "${SWIFTC_ARGS[@]}" "${FIXTURE_DIR}/Positive.swift"
    swiftc "${SWIFTC_ARGS[@]}" "${FIXTURE_DIR}/SemanticArrayDataContract.swift"

    check_rejected() {
      local fixture="$1"
      local expected="$2"
      local diagnostics="${TEMP_DIR}/${fixture}.txt"

      if swiftc "${SWIFTC_ARGS[@]}" "${FIXTURE_DIR}/${fixture}.swift" >"${diagnostics}" 2>&1; then
        echo "error: ${fixture}.swift unexpectedly compiled" >&2
        exit 1
      fi
      if ! grep -Fq "${expected}" "${diagnostics}"; then
        echo "error: ${fixture}.swift failed without the expected ${expected} diagnostic" >&2
        cat "${diagnostics}" >&2
        exit 1
      fi
    }

    check_rejected NonSendableElement Sendable
    check_rejected NonSendableRepresentation Sendable

    echo "sendability check passed"
    exit 0
    ;;
  Darwin) ;;
  *)
    echo "error: check-sendability.sh supports only Linux and macOS hosts" >&2
    exit 1
    ;;
esac

readonly SWIFT_IMAGE="${SWIFT_IMAGE:-docker.io/library/swift:6.3.3-noble}"
readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-/workspace/.build}"
readonly CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-swift-multiarray-sendability}"

exec podman run --rm \
  --hostname "${CONTAINER_HOSTNAME}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  --env SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH}" \
  "${SWIFT_IMAGE}" \
  scripts/check-sendability.sh
