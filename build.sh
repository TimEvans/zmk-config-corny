#!/bin/bash

# Build ZMK firmware locally for the Corne (nice_nano_v2).
#
# Requires a one-time toolchain setup (see docs/corne-v3-this-repo.md):
#   - a uv venv with `west` and `cmake<4` (activate it before running)
#   - Zephyr SDK 0.16.x (arm-zephyr-eabi)
#   - `west init -l config && west update && west zephyr-export` run once
#
# Outputs UF2 files into firmware-builds/ with the names flash.sh expects.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZMK_APP="$SCRIPT_DIR/zmk/app"
ZMK_CONFIG="$SCRIPT_DIR/config"
BUILD_DIR="$SCRIPT_DIR/build"
OUT_DIR="$SCRIPT_DIR/firmware-builds"
BOARD="nice_nano_v2"

show_usage() {
    echo "Usage: $0 [left|right|reset|all]   (default: all)"
    echo ""
    echo "  left   Build left half firmware"
    echo "  right  Build right half firmware"
    echo "  reset  Build settings_reset firmware"
    echo "         (flash to BOTH halves to clear stale BLE/split bonds,"
    echo "          then build+flash real firmware again)"
    echo "  all    Build left + right (default)"
    exit 1
}

require_toolchain() {
    if ! command -v west >/dev/null 2>&1; then
        echo "Error: 'west' is not on PATH. Activate your Zephyr venv first." >&2
        echo "See docs/corne-v3-this-repo.md for one-time setup." >&2
        exit 1
    fi
    if [[ ! -d "$ZMK_APP" ]]; then
        echo "Error: $ZMK_APP not found." >&2
        echo "Run 'west init -l config && west update' in the repo root first." >&2
        exit 1
    fi
}

# build_shield <shield-name> <output-basename>
build_shield() {
    local shield="$1" name="$2"
    echo "==> Building $shield ..."
    west build -p -s "$ZMK_APP" -d "$BUILD_DIR/$name" -b "$BOARD" -- \
        -DSHIELD="$shield" -DZMK_CONFIG="$ZMK_CONFIG"
    mkdir -p "$OUT_DIR"
    cp "$BUILD_DIR/$name/zephyr/zmk.uf2" "$OUT_DIR/${name}-${BOARD}-zmk.uf2"
    echo "==> Wrote $OUT_DIR/${name}-${BOARD}-zmk.uf2"
}

require_toolchain

case "${1:-all}" in
    left)  build_shield corne_left  corne_left ;;
    right) build_shield corne_right corne_right ;;
    reset) build_shield settings_reset settings_reset ;;
    all)
        build_shield corne_left  corne_left
        build_shield corne_right corne_right
        ;;
    *) show_usage ;;
esac

echo "Done."
