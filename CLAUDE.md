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
- `config/west.yml` — west manifest; pins ZMK to revision **v0.2**.
- `build.yaml` — GitHub Actions build matrix (`corne_left` + `corne_right` on
  `nice_nano_v2`).
- `.github/workflows/build.yml` — builds firmware on push, then **auto-commits**
  the `.uf2` artifacts into `firmware-builds/`.
- `firmware-builds/*.uf2` — committed build outputs, consumed by `flash.sh`.
- `flash.sh` — local flashing helper.

## Common tasks

- **Change the keymap:** edit `config/corne.keymap`. Keep each main row at 12
  bindings (6 per side) and the thumb row at 6, or the build fails. All changes
  are compile-time — a rebuild + reflash is required for anything to take effect.
- **Build firmware:** `git push`. CI builds both halves and commits the updated
  `.uf2` files back to `firmware-builds/` (commit `Auto-update firmware builds`).
  There is no local build step in this repo; building happens in GitHub Actions.
- **Flash firmware:** `./flash.sh left` and `./flash.sh right`. Put each half in
  bootloader mode first (double-tap reset, or the `&bootloader` key on layer 3);
  it mounts as a `NICENANO` drive and the script copies the matching `.uf2`.
  Flash **both** halves after a keymap change.

## Conventions

- Layers are referenced by **index** (0-3), not name; `&mo N` order matters and
  matches file order in the keymap.
- Key positions for `hold-trigger-key-positions` / future combos are 0-indexed
  left-to-right, top-to-bottom — see the position map in the repo-specific doc.
- The `firmware-builds/` `.uf2` files are CI-generated; don't hand-edit them.
  Commits there are made automatically by the build workflow.
