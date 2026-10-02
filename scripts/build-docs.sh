#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOCC_BUILD_DIR="${DOCC_BUILD_DIR:-${ROOT_DIR}/.build/docc}"
readonly SYMBOL_GRAPH_DIR="${DOCC_BUILD_DIR}/symbol-graphs"
readonly CATALOG="${ROOT_DIR}/Sources/MultiArray/MultiArray.docc"
readonly OUTPUT="${DOCC_BUILD_DIR}/MultiArray.doccarchive"
readonly STATIC_OUTPUT="${DOCC_BUILD_DIR}/html"
readonly DOCC_PORT="${DOCC_PORT:-0}"
export SWIFT_IMAGE="${SWIFT_IMAGE:-docker.io/library/swift:6.4.0-noble}"

usage() {
  cat <<EOF
Usage: scripts/build-docs.sh [--serve]

Build MultiArray's documentation with DocC.

Options:
  --serve  Serve the generated documentation on 127.0.0.1.
  --help   Show this help.

Environment:
  DOCC_BUILD_DIR  Build and output directory. Defaults to .build/docc.
                  On macOS, use an absolute path inside this checkout.
  DOCC_PORT       Local server port. Defaults to an available port selected by
                  the operating system.
  SNIPPET_EXTRACT Path or command name for snippet-extract. If unset, use
                  Xcode's copy on macOS; on Linux, use PATH or build a pinned
                  copy.
  SWIFT_IMAGE     The container image to use on macOS. Defaults to swift:6.4.0-noble.
EOF
}

serve=0
case "${1:-}" in
  "")
    ;;
  --serve)
    serve=1
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

if [[ -z "${DOCC_BUILD_DIR}" || "${DOCC_BUILD_DIR}" == "/" ]]; then
  echo "error: refusing to use unsafe DOCC_BUILD_DIR '${DOCC_BUILD_DIR}'" >&2
  exit 2
fi

case "$(uname -s)" in
  Darwin)
    if ! xcrun --find docc >/dev/null; then
      echo "error: DocC was not found in the active Xcode toolchain" >&2
      exit 1
    fi
    readonly DOCC=(xcrun docc)
    SNIPPET_EXTRACT="${SNIPPET_EXTRACT:-$(dirname "$(xcrun --find swiftc)")/snippet-extract}"
    case "${SYMBOL_GRAPH_DIR}" in
      "${ROOT_DIR}"/*)
        readonly SYMBOL_GRAPH_BUILD_DIR="/workspace${SYMBOL_GRAPH_DIR#"${ROOT_DIR}"}"
        ;;
      *)
        echo "error: on macOS, DOCC_BUILD_DIR must be an absolute path inside ${ROOT_DIR}" >&2
        exit 2
        ;;
    esac
    readonly SWIFT_BUILD_SCRATCH_PATH="/workspace${DOCC_BUILD_DIR#"${ROOT_DIR}"}/swiftpm"
    ;;
  Linux)
    if ! command -v docc >/dev/null; then
      echo "error: docc was not found in the Swift toolchain" >&2
      exit 1
    fi
    readonly DOCC=(docc)
    readonly SYMBOL_GRAPH_BUILD_DIR="${SYMBOL_GRAPH_DIR}"
    readonly SWIFT_BUILD_SCRATCH_PATH="${DOCC_BUILD_DIR}/swiftpm"
    if [[ -z "${SNIPPET_EXTRACT:-}" ]]; then
      if command -v snippet-extract >/dev/null; then
        SNIPPET_EXTRACT="$(command -v snippet-extract)"
      else
        readonly TOOL_DIR="${ROOT_DIR}/.build/docc-tooling/swift-docc-plugin"
        # A snippet-extract executable built by another Swift toolchain (or
        # against another Linux distribution) may crash when reused here.
        toolchain_key="$({
          swift --version
          if [[ -f /etc/os-release ]]; then
            cat /etc/os-release
          fi
        } | sha256sum)"
        readonly TOOL_SCRATCH_DIR="${ROOT_DIR}/.build/docc-tooling/swiftpm-${toolchain_key%% *}"
        SNIPPET_EXTRACT="${TOOL_SCRATCH_DIR}/release/snippet-extract"

        if [[ ! -x "${SNIPPET_EXTRACT}" ]]; then
          if [[ ! -f "${TOOL_DIR}/Package.swift" ]]; then
            mkdir -p "$(dirname "${TOOL_DIR}")"
            git clone --depth 1 --branch 1.4.6 \
              https://github.com/swiftlang/swift-docc-plugin.git "${TOOL_DIR}"
          fi

          swift build \
            --package-path "${TOOL_DIR}" \
            --scratch-path "${TOOL_SCRATCH_DIR}" \
            --configuration release \
            --product snippet-extract
        fi
      fi
    fi
    ;;
  *)
    echo "error: build-docs.sh supports only Linux and macOS" >&2
    exit 1
    ;;
esac

if ! command -v "${SNIPPET_EXTRACT}" >/dev/null; then
  echo "error: snippet-extract was not found; set SNIPPET_EXTRACT to its executable path" >&2
  exit 1
fi

if [[ ! -d "${CATALOG}" ]]; then
  echo "error: documentation catalog was not found at ${CATALOG}" >&2
  exit 1
fi

rm -rf \
  "${SYMBOL_GRAPH_DIR}" \
  "${OUTPUT}" \
  "${STATIC_OUTPUT}"
mkdir -p "${SYMBOL_GRAPH_DIR}"

SWIFT_BUILD_CONFIGURATION=debug \
  SWIFT_SCRATCH_PATH="${SWIFT_BUILD_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" \
  --product Guide

SWIFT_BUILD_CONFIGURATION=debug \
  SWIFT_SCRATCH_PATH="${SWIFT_BUILD_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" \
  --product Vectorization

module_bin_dir="$(SWIFT_BUILD_CONFIGURATION=debug \
  SWIFT_SCRATCH_PATH="${SWIFT_BUILD_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" --show-bin-path)"

# SwiftPM compiles snippets as an executable; run it to check their assertions.
if [[ "$(uname -s)" == Darwin ]]; then
  podman run --rm \
    --hostname "${CONTAINER_HOSTNAME:-swift-multiarray-builder}" \
    --volume "${ROOT_DIR}:/workspace" \
    --workdir /workspace \
    "${SWIFT_IMAGE}" \
    "${module_bin_dir}/Guide"
else
  "${module_bin_dir}/Guide"
fi

# Extract from the compiled module. -Xswiftc -emit-symbol-graph and SwiftPM's
# dump-symbol-graph both change dependency build flags and rebuild SwiftSyntax.
if [[ "$(uname -s)" == Darwin ]]; then
  podman run --rm \
    --hostname "${CONTAINER_HOSTNAME:-swift-multiarray-builder}" \
    --volume "${ROOT_DIR}:/workspace" \
    --workdir /workspace \
    "${SWIFT_IMAGE}" \
    swift symbolgraph-extract \
      -module-name MultiArray \
      -I "${module_bin_dir}" \
      -I "${module_bin_dir}/Modules" \
      -minimum-access-level public \
      -output-dir "${SYMBOL_GRAPH_BUILD_DIR}"
else
  swift symbolgraph-extract \
    -module-name MultiArray \
    -I "${module_bin_dir}" \
    -I "${module_bin_dir}/Modules" \
    -minimum-access-level public \
    -output-dir "${SYMBOL_GRAPH_BUILD_DIR}"
fi
if [[ ! -f "${SYMBOL_GRAPH_DIR}/MultiArray.symbols.json" ]]; then
  echo "error: MultiArray symbol graph was not produced in ${SYMBOL_GRAPH_DIR}" >&2
  exit 1
fi

snippet_files=("${ROOT_DIR}"/Snippets/*.swift)
if [[ ! -e "${snippet_files[0]}" ]]; then
  echo "error: no documentation snippets were found at ${ROOT_DIR}/Snippets" >&2
  exit 1
fi

"${SNIPPET_EXTRACT}" \
  --output "${SYMBOL_GRAPH_DIR}/swift-multiarray-snippets.symbols.json" \
  --module-name swift-multiarray \
  "${snippet_files[@]}"

"${DOCC[@]}" convert "${CATALOG}" \
  --additional-symbol-graph-dir "${SYMBOL_GRAPH_DIR}" \
  --fallback-display-name MultiArray \
  --fallback-bundle-identifier org.dataparallel-swift.multiarray \
  --fallback-default-module-kind framework \
  --output-dir "${OUTPUT}" \
  --warnings-as-errors

echo "Generated documentation archive at ${OUTPUT}"

if [[ ${serve} -eq 1 ]]; then
  if ! command -v python3 >/dev/null; then
    echo "error: python3 is required to serve the generated documentation" >&2
    exit 1
  fi

  "${DOCC[@]}" process-archive transform-for-static-hosting \
    "${OUTPUT}" \
    --output-path "${STATIC_OUTPUT}"

  exec python3 - "${STATIC_OUTPUT}" "${DOCC_PORT}" <<'PYTHON'
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


directory = sys.argv[1]
port = int(sys.argv[2])
handler = partial(NoCacheHandler, directory=directory)

with ThreadingHTTPServer(("127.0.0.1", port), handler) as server:
    host, selected_port = server.server_address
    print("Serving documentation:", flush=True)
    print(
        f"  http://{host}:{selected_port}/documentation/multiarray/",
        flush=True,
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
PYTHON
fi
