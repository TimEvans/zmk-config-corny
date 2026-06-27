# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal [ZMK](https://zmk.dev) firmware config for a **Corne v3 (42-key)**
split keyboard running on two **nice!nano v2** controllers over Bluetooth. It is
a config repo, not a fork of ZMK: it supplies the keymap + Kconfig and pulls ZMK
itself in as a west dependency.

## Reference docs (read these first)

- **[docs/zmk-reference.md](docs/zmk-reference.md)** — condensed ZMK syntax:
  keymap structure, `&kp`/modifiers, layers, hold-tap (home-row mods),
  bluetooth, reset, combos, `.conf`/Kconfig.
- **[docs/corne-v3-this-repo.md](docs/corne-v3-this-repo.md)** — this board's
  layout, key-position map, the four layers, the custom `hrm` behaviors, and the
  build/flash workflow.

## Key files

- `config/corne.keymap` — the keymap: `behaviors` node (custom `hrm`,
  `hrm_pinky` home-row mods) + four layers (`default`, `lower`, `raise`,
  `layer_3`). Devicetree syntax.
- `config/corne.conf` — Kconfig feature toggles (currently just `CONFIG_BT=y`).
  Shared across both halves.
- `config/west.yml` — west manifest; pins ZMK to revision **v0.3** (Zephyr
  `v3.5.0+zmk-fixes`, so the local toolchain needs **Zephyr SDK 0.16.x**).
- `build.sh` — local build helper (`west build` for each half; also a
  `settings_reset` target). Outputs `.uf2` into `firmware-builds/`.
- `flash.sh` — local flashing helper (copies a `.uf2` to the NICENANO drive).
- `firmware-builds/*.uf2` — build outputs consumed by `flash.sh`.

Builds are **local only** — there is no CI. The previous GitHub Actions workflow
and `build.yaml` matrix were removed; recover them from git history if ever
needed.

## Common tasks

- **Change the keymap:** edit `config/corne.keymap`. Keep each main row at 12
  bindings (6 per side) and the thumb row at 6, or the build fails. All changes
  are compile-time — a rebuild + reflash is required for anything to take effect.
- **Build firmware:** `./build.sh` (both halves) or `./build.sh left|right`.
  Requires the one-time local toolchain setup — see
  [docs/corne-v3-this-repo.md](docs/corne-v3-this-repo.md). Outputs `.uf2` into
  `firmware-builds/`.
- **Flash firmware:** `./flash.sh left` and `./flash.sh right`. Put each half in
  bootloader mode first (double-tap reset, or the `&bootloader` key on layer 3);
  it mounts as a `NICENANO` drive and the script copies the matching `.uf2`.
  Flash **both** halves after a keymap change.
- **Halves won't talk over BLE (e.g. after swapping a controller):** build
  `./build.sh reset`, flash that `settings_reset` UF2 to **both** halves, then
  build + flash real firmware again, and re-pair the host. See the repo doc.

## Conventions

- Layers are referenced by **index** (0-3), not name; `&mo N` order matters and
  matches file order in the keymap.
- Key positions for `hold-trigger-key-positions` / future combos are 0-indexed
  left-to-right, top-to-bottom — see the position map in the repo-specific doc.
- The `firmware-builds/` `.uf2` files are produced by `build.sh`. The local west
  workspace (`zmk/`, `zephyr/`, `modules/`, `.west/`, `build/`, `.venv/`) is
  gitignored — don't commit it.
