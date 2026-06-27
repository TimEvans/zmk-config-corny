# This Keyboard: Corne v3 (42-key) on nice!nano v2

Repo-specific notes. For ZMK syntax/behavior details, see
[zmk-reference.md](./zmk-reference.md).

## Hardware

- **Keyboard:** Corne v3 (CRKBD), 42 keys — 6 columns x 3 rows + 3 thumb keys
  per half, column-staggered split.
- **Controllers:** two `nice_nano_v2` (one per half), connected over BLE.
- **Shields:** `corne_left`, `corne_right` (see `build.yaml`).
- **Connectivity:** Bluetooth (`CONFIG_BT=y` in `config/corne.conf`).

> Note: this is the full 6-column Corne. Some Corne builds drop the outer
> column for a 36-key layout — this config uses all 42 keys, so every row in the
> keymap has 12 bindings (6 per side) and the thumb row has 6.

## Key position map (0-indexed)

ZMK numbers keys left-to-right, top-to-bottom. Use these numbers for
`hold-trigger-key-positions`, `combos`, etc.

```
  0   1   2   3   4   5        6   7   8   9  10  11
 12  13  14  15  16  17       18  19  20  21  22  23
 24  25  26  27  28  29       30  31  32  33  34  35
             36  37  38       39  40  41
```

Mapped to the base (`default_layer`):

```
TAB   Q   W   E   R   T        Y   U   I   O   P   BSPC
LCTL  A   S   D   F   G        H   J   K   L   ;   '
LSFT  Z   X   C   V   B        N   M   ,   .   /   ESC
              LALT MO2 ENT     SPC MO1 RGUI
```

## Layers

Defined in `config/corne.keymap`, indexed in file order:

| # | Node            | Reached by        | Purpose |
| - | --------------- | ----------------- | ------- |
| 0 | `default_layer` | (base)            | Alphas + home-row mods. |
| 1 | `lower_layer`   | hold right thumb — `&mo 1` (pos 40) | Symbols (left), nav + media (right). |
| 2 | `raise_layer`   | hold left thumb — `&mo 2` (pos 37)  | Numbers + math/bracket symbols. |
| 3 | `layer_3`       | `&mo 3` (pos 37 & 40, present **only** on the raise layer) | F-keys, `&bootloader`, `&sys_reset`, `&bt BT_CLR`. |

Reaching layer 3: only the **raise** layer (2) maps its thumbs to `&mo 3` — the
lower layer leaves them `&trans`. So the access path is hold the **left** thumb
(`&mo 2` -> raise), then the **right** thumb (now `&mo 3` -> layer 3). On the
raise layer either thumb is `&mo 3`.

## Home-row mods (custom `hrm` / `hrm_pinky` behaviors)

Two custom hold-tap behaviors live in the `behaviors` node:

- **`hrm`** — `tapping-term-ms = 250`, `flavor = "tap-preferred"`,
  `quick-tap-ms = 250`, `require-prior-idle-ms = 250`.
- **`hrm_pinky`** — same shape but `300ms` timings (pinkies are slower).
  > Defined but **not currently referenced** in the keymap.

Both restrict activation with:

```
hold-trigger-key-positions = <16 15 14 13 19 20 21 22>;
```

Those positions are the eight home-row alpha keys: `13 14 15 16` = `A S D F`
(left) and `19 20 21 22` = `J K L ;` (right).

Current base-layer mod assignments (`&hrm <mod> <tap>`):

| Pos | Key | Mod (hold) |
| --- | --- | ---------- |
| 14  | S   | Left GUI/Meta |
| 15  | D   | Left Shift |
| 16  | F   | Left Ctrl |
| 28  | V   | Left Alt |
| 19  | J   | Right Ctrl |
| 20  | K   | Right Shift |
| 21  | L   | Right Meta |
| 31  | M   | Right Alt |

> Heads-up for future edits: `hold-trigger-key-positions` here lists **both**
> hands' home rows in a single shared list, so the standard "hold only fires on
> a cross-hand key" guarantee isn't strict — a same-hand home-row neighbor can
> also trigger the hold. If you ever get spurious mods, consider splitting into
> per-hand behaviors (left HRMs trigger only on right-hand positions, and vice
> versa). See the hold-tap section in [zmk-reference.md](./zmk-reference.md).

## Editing the keymap

- Edit `config/corne.keymap` (layers/behaviors) and `config/corne.conf`
  (feature toggles). Keep each row's binding count matching the physical layout
  (12 per main row, 6 thumbs) or the build fails.
- Changes are compile-time: every edit needs a rebuild + reflash.

## Build & flash

**Build (GitHub Actions):** pushing to the repo triggers
`.github/workflows/build.yml`, which builds via ZMK's reusable
`build-user-config.yml` and then auto-commits the resulting `.uf2` files back
into `firmware-builds/` (commit message `Auto-update firmware builds`). The
matrix is defined in `build.yaml` (`corne_left` + `corne_right` on
`nice_nano_v2`).

**Flash (local):** use the helper script — see
[../flash.sh](../flash.sh):

```bash
./flash.sh left      # flash the left half
./flash.sh right     # flash the right half
```

To flash, put a half into bootloader mode (double-tap its reset button, or use
the `&bootloader` key on layer 3). It mounts as a `NICENANO` USB drive; the
script finds/mounts it and copies
`firmware-builds/corne_<side>-nice_nano_v2-zmk.uf2` onto it. The board
auto-reboots when done. Flash both halves after a keymap change.

## Visual editor

The keymap also opens in the ZMK Keymap Editor / Nick Coutsos editor
(https://nickcoutsos.github.io/keymap-editor/) for a GUI view of layers.
