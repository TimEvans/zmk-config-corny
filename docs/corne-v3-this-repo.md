# This Keyboard: Corne v3 (42-key) on nice!nano v2

Repo-specific notes. For ZMK syntax/behavior details, see
[zmk-reference.md](./zmk-reference.md).

## Hardware

- **Keyboard:** Corne v3 (CRKBD), 42 keys — 6 columns x 3 rows + 3 thumb keys
  per half, column-staggered split.
- **Controllers:** two `nice_nano_v2` (or a SuperMini nRF52840 clone) — one per
  half, connected over BLE.
- **Shields:** `corne_left`, `corne_right`.
- **Connectivity:** Bluetooth (`CONFIG_BT=y` in `config/corne.conf`).
- **ZMK version:** pinned to `v0.3` in `config/west.yml` (Zephyr
  `v3.5.0+zmk-fixes`).

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

## Power management

`config/corne.conf` enables deep sleep for wireless battery life:

```ini
CONFIG_ZMK_SLEEP=y                     # enable deep sleep (off by default)
CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=1800000  # 30 min of inactivity -> deep sleep
CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y     # connection-stability tweaks for
                                       # reliable reconnect after sleep
```

Two separate timers:

- **Idle: 30s** (`CONFIG_ZMK_IDLE_TIMEOUT`, default). Lowers the BLE poll rate
  and, with the OLED on, blanks the screen (`CONFIG_ZMK_DISPLAY_BLANK_ON_IDLE`
  defaults `y` for SSD1306). Tap any key to wake it.
- **Deep sleep: 30 min** (set above). Powers the board down to ~µA and drops
  BLE; wake takes ~1s and reconnects. Each half sleeps independently, and a
  keypress only wakes the half it lands on — the left (central) half must be
  woken for the host connection to come back, and the wake keypress itself is
  not sent.

Battery reporting is on by default for `nice_nano_v2`.

## OLED displays

`CONFIG_ZMK_DISPLAY=y` turns on the two SSD1306 OLEDs. The Corne shield's
`Kconfig.defconfig` auto-enables `I2C`, `SSD1306`, and the LVGL settings, so the
single line is all `config/corne.conf` needs.

- **Left (central)** OLED shows the default status screen: battery %, active
  layer, and BLE/output status.
- **Right (peripheral)** OLED shows a connection/status screen.

To see **both** halves' batteries, the config also sets:

```ini
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING=y  # central reads peripheral level
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y     # report it to the host too
```

The host's Bluetooth UI will then show two batteries. Note: the *left* OLED's
battery widget shows only the left half's level — putting the right half's
battery on-screen would need a custom LVGL widget (not done here).

See the power section in [zmk-reference.md](./zmk-reference.md).

## Local toolchain setup (one-time)

Builds are done **locally** with the native west toolchain (no CI), using `uv`
to manage the Python environment. ZMK `v0.3` uses Zephyr `3.5.0`, so you need
**Zephyr SDK 0.16.x** (not 0.17+). On Arch, Zephyr 3.5 is incompatible with
CMake 4 (the system `cmake`), so we pin `cmake<4` inside the uv venv.

```bash
# 1. Host packages (uv provides Python; CMake is pinned in the venv below)
sudo pacman -S --needed git ninja gperf dtc base-devel

# 2. uv venv with west + a CMake 3.x
uv venv                       # if not already created
source .venv/bin/activate
uv pip install west "cmake<4"

# 3. Fetch ZMK + Zephyr into the (gitignored) local workspace
west init -l config
west update
west zephyr-export
uv pip install -r zephyr/scripts/requirements.txt

# 4. Zephyr SDK 0.16.x (ARM target only is enough for nice_nano_v2)
#    Download from:
#    https://github.com/zephyrproject-rtos/sdk-ng/releases (pick a 0.16.x tag)
#    Extract, then run its ./setup.sh and register it, e.g.:
#      cd ~/zephyr-sdk-0.16.8 && ./setup.sh -t arm-zephyr-eabi -c
```

`west init -l config` makes this repo the manifest and clones `zmk/`, `zephyr/`,
and `modules/` into the repo root — all gitignored. (Purist alternative: nest
this repo inside a dedicated workspace dir instead; not required.)

After setup, activate the venv (`source .venv/bin/activate`) in any shell before
building.

## Build & flash

**Build** with [../build.sh](../build.sh) (outputs to `firmware-builds/`):

```bash
./build.sh            # both halves
./build.sh left       # just the left half
./build.sh right      # just the right half
./build.sh reset      # settings_reset firmware (see below)
```

**Flash** with [../flash.sh](../flash.sh):

```bash
./flash.sh left       # flash the left half
./flash.sh right      # flash the right half
```

Put a half into bootloader mode (double-tap its reset button, or the
`&bootloader` key on layer 3). It mounts as a `NICENANO` USB drive; the script
finds/mounts it and copies
`firmware-builds/corne_<side>-nice_nano_v2-zmk.uf2` onto it. The board
auto-reboots. Flash **both** halves after a keymap change.

## Fixing split halves that won't talk over BLE

The two halves keep a bond with each other that is separate from host BLE
profiles. Replacing or reflashing a controller breaks it, and `&bt BT_CLR` does
**not** fix it (that only clears host profiles). Symptom: works wired, but the
peripheral (right) half is dead over Bluetooth.

Fix — reset stored settings on **both** halves, in order:

```bash
./build.sh reset      # builds firmware-builds/settings_reset-nice_nano_v2-zmk.uf2
```

1. Bootloader the left half; copy `settings_reset-...uf2` onto its NICENANO drive.
2. Bootloader the right half; copy the same `settings_reset-...uf2` onto it.
3. `./build.sh` then `./flash.sh left` and `./flash.sh right` to restore real
   firmware on both.
4. Reset both halves at about the same time, then forget + re-pair the keyboard
   on the host.

`settings_reset` has Bluetooth disabled on purpose so the halves don't re-bond to
stale data before both are wiped. This erases all stored settings (BT profiles,
output selection, etc.).

## Visual editor

The keymap also opens in the ZMK Keymap Editor / Nick Coutsos editor
(https://nickcoutsos.github.io/keymap-editor/) for a GUI view of layers.
