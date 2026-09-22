#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$(uname -s)" in
  Linux)
    readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-${ROOT_DIR}/.build}"
    readonly FIXTURE="${ROOT_DIR}/Snippets/Vectorization.swift"
    readonly TEMP_DIR="$(mktemp -d)"
    readonly MODULE_IR="${TEMP_DIR}/VectorizationFixture.ll"
    readonly MOVE_IR="${TEMP_DIR}/move.ll"
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

    swiftc \
      -O \
      -emit-ir \
      -parse-as-library \
      -module-name VectorizationFixture \
      -I "${MODULE_DIR}" \
      -load-plugin-executable "${PLUGIN_PATH}#MultiArrayMacros" \
      "${FIXTURE}" \
      -o "${MODULE_IR}"

    awk '
      /^define .*VectorizationFixture4move/ { printing = 1 }
      printing { print }
      printing && /^}/ { exit }
    ' "${MODULE_IR}" > "${MOVE_IR}"

    if [[ ! -s "${MOVE_IR}" ]]; then
      echo "error: could not find the fixture move function in generated IR" >&2
      exit 1
    fi

    if ! grep -Fq 'vector.body:' "${MOVE_IR}"; then
      echo "error: fixture move IR does not contain a vector loop" >&2
      sed -n '1,240p' "${MOVE_IR}" >&2
      exit 1
    fi

    readonly VECTOR_WIDTH="$({
      sed -nE 's/.*fadd <([0-9]+) x float>.*/\1/p' "${MOVE_IR}" || true
    } | head -n 1)"
    if [[ -z "${VECTOR_WIDTH}" || "${VECTOR_WIDTH}" -lt 2 ]]; then
      echo "error: fixture move IR does not contain a vector float addition" >&2
      sed -n '1,240p' "${MOVE_IR}" >&2
      exit 1
    fi

    for pattern in \
      "load <${VECTOR_WIDTH} x float>" \
      "fadd <${VECTOR_WIDTH} x float>" \
      "store <${VECTOR_WIDTH} x float>"
    do
      if ! grep -Fq "${pattern}" "${MOVE_IR}"; then
        echo "error: fixture move IR does not contain: ${pattern}" >&2
        sed -n '1,240p' "${MOVE_IR}" >&2
        exit 1
      fi
    done

    echo "vectorization check passed (${VECTOR_WIDTH}-wide float operations)"
    exit 0
    ;;
  Darwin) ;;
  *)
    echo "error: check-vectorization.sh supports only Linux and macOS hosts" >&2
    exit 1
    ;;
esac

readonly SWIFT_IMAGE="${SWIFT_IMAGE:-docker.io/library/swift:6.3.3-noble}"
readonly SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH:-/workspace/.build}"
readonly CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-swift-multiarray-vectorization}"

exec podman run --rm \
  --hostname "${CONTAINER_HOSTNAME}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  --env SWIFT_SCRATCH_PATH="${SWIFT_SCRATCH_PATH}" \
  "${SWIFT_IMAGE}" \
  scripts/check-vectorization.sh
