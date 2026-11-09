#!/bin/sh
# Builds cert_check.wasm for the browserless wasm32 target without a libc.
# Requires clang with the wasm32 backend and wasm-ld (LLVM 13 or later).
# Not run in this environment: the installed Apple clang has no wasm32 target
# and no wasm-ld is installed.
set -e
cd "$(dirname "$0")"
clang --target=wasm32 -std=c99 -O2 -DCC_WASM -nostdlib -fno-builtin \
  -Wl,--no-entry -Wl,--export-dynamic \
  -o cert_check.wasm cert_check.c
