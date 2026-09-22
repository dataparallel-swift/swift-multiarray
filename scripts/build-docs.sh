#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOCC_BUILD_DIR="${DOCC_BUILD_DIR:-${ROOT_DIR}/.build/docc}"
readonly SYMBOL_GRAPH_DIR="${DOCC_BUILD_DIR}/symbol-graphs"
readonly CONTAINER_SWIFT_SCRATCH_PATH="/workspace/.build/docc/swiftpm"
readonly CATALOG="${ROOT_DIR}/Sources/MultiArray/MultiArray.docc"
readonly OUTPUT="${DOCC_BUILD_DIR}/MultiArray.doccarchive"
readonly STATIC_OUTPUT="${DOCC_BUILD_DIR}/html"
readonly DOCC_PORT="${DOCC_PORT:-0}"

usage() {
  cat <<EOF
Usage: scripts/build-docs.sh [--serve]

Build MultiArray's documentation with the DocC included in Xcode.

Options:
  --serve  Serve the generated documentation on 127.0.0.1.
  --help   Show this help.

Environment:
  DOCC_BUILD_DIR  Build and output directory. Defaults to .build/docc.
  DOCC_PORT       Local server port. Defaults to an available port selected by
                  the operating system.
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: build-docs.sh requires macOS and the DocC tools bundled with Xcode" >&2
  exit 1
fi

if ! xcrun --find docc >/dev/null; then
  echo "error: DocC was not found in the active Xcode toolchain" >&2
  exit 1
fi

readonly SNIPPET_EXTRACT="$(dirname "$(xcrun --find swiftc)")/snippet-extract"
if [[ ! -x "${SNIPPET_EXTRACT}" ]]; then
  echo "error: snippet-extract was not found in the active Xcode toolchain" >&2
  exit 1
fi

if [[ ! -d "${CATALOG}" ]]; then
  echo "error: documentation catalog was not found at ${CATALOG}" >&2
  exit 1
fi

rm -rf \
  "${SYMBOL_GRAPH_DIR}" \
  "${DOCC_BUILD_DIR}/swiftpm" \
  "${OUTPUT}" \
  "${STATIC_OUTPUT}"
mkdir -p "${SYMBOL_GRAPH_DIR}"

SWIFT_SCRATCH_PATH="${CONTAINER_SWIFT_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" \
  --product Guide

SWIFT_SCRATCH_PATH="${CONTAINER_SWIFT_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" \
  --product Vectorization

SWIFT_SCRATCH_PATH="${CONTAINER_SWIFT_SCRATCH_PATH}" \
  "${ROOT_DIR}/scripts/build-linux.sh" \
  --target MultiArray \
  -Xswiftc -emit-symbol-graph \
  -Xswiftc -emit-symbol-graph-dir \
  -Xswiftc /workspace/.build/docc/symbol-graphs

# -Xswiftc flags also reach package dependencies. Keep only this module's
# symbol graphs so their documentation diagnostics do not pollute this build.
find "${SYMBOL_GRAPH_DIR}" \
  -type f \
  -name '*.symbols.json' \
  ! -name 'MultiArray.symbols.json' \
  ! -name 'MultiArray@*.symbols.json' \
  -delete

snippet_files=("${ROOT_DIR}"/Snippets/*.swift)
if [[ ! -e "${snippet_files[0]}" ]]; then
  echo "error: no documentation snippets were found at ${ROOT_DIR}/Snippets" >&2
  exit 1
fi

"${SNIPPET_EXTRACT}" \
  --output "${SYMBOL_GRAPH_DIR}/swift-multiarray-snippets.symbols.json" \
  --module-name swift-multiarray \
  "${snippet_files[@]}"

xcrun docc convert "${CATALOG}" \
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

  xcrun docc process-archive transform-for-static-hosting \
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
