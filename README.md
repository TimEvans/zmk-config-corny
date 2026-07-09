# zmk-config-corny

Personal [ZMK](https://zmk.dev) firmware config for a **Corne v3 (42-key)** split
keyboard on two **nice!nano v2** controllers, connected over Bluetooth.

This is a config repo (keymap + Kconfig), not a fork of ZMK — ZMK is pulled in as
a west dependency (`config/west.yml`, pinned to `v0.3`). Builds are local; see
[`CLAUDE.md`](CLAUDE.md) and [`docs/`](docs/) for the toolchain setup and workflow.

## Keymap

Four layers, referenced by index. `L1`/`L2`/`L3` are momentary layer holds
(`&mo`); `▽` is a transparent key (falls through to the layer below).

### Layer 0 — Default (QWERTY + home-row mods)

```
 Tab    Q     W     E     R     T   │   Y     U     I     O     P    Bksp
 Ctrl   A     S     D     F     G   │   H     J     K     L     ;     '  
 Shft   Z     X     C     V     B   │   N     M     ,     .     /    Esc 
                   Alt    L2   Ent  │  Spc    L1   GUI 
```

**Home-row mods** — held, these keys act as modifiers; tapped, they type the
letter (hold-tap, 250 ms term):

| Finger | Left | Right | Modifier |
|--------|------|-------|----------|
| index  | `F`  | `J`   | Ctrl     |
| middle | `D`  | `K`   | Shift    |
| ring   | `S`  | `L`   | GUI      |
| (lower)| `V`  | `M`   | Alt      |

### Layer 1 — Lower (symbols, navigation, media)

Held via the right inner thumb (`L1`).

```
 Tab    &     @     /     \     ^   │  Home  PgDn  PgUp  End   Mute  Bksp
 Ctrl   !     ?     #     $     %   │   ←     ↓     ↑     →     :    Del 
 Shft   `     ▽     ▽    Bri-  Bri+ │  Prev  Vol-  Vol+  Next  Play  Esc 
                   Alt    L3   Ent  │  Spc    ▽    GUI 
```

### Layer 2 — Raise (numbers, math, brackets)

Held via the left inner thumb (`L2`).

```
 Tab    *     7     8     9     -   │   _     =     (     )     |    Bksp
 Ctrl   /     4     5     6     +   │   -     +     [     ]     :    Del 
 Shft   0     1     2     3     .   │   *     <     {     }     >     ~  
                   Alt    L3   Ent  │  Spc    L3   GUI 
```

### Layer 3 — Adjust (function keys, system, Bluetooth)

Reached by holding `L3` from Lower or Raise. `Rset` = soft reset, `Boot` =
bootloader (for flashing), `BTclr` = clear the active Bluetooth bond.

```
 Rset  Boot   F7    F8    F9   F10  │   ▽     ▽     ▽     ▽     ▽   BTclr
  ▽     ▽     F4    F5    F6   F11  │   ▽     ▽     ▽     ▽     ▽     ▽  
 Shft   ▽     F1    F2    F3   F12  │   ▽     ▽     ▽     ▽     ▽    Esc 
                   Alt    ▽    Ent  │  Spc    ▽    GUI 
```

## Build & flash

```bash
source .venv/bin/activate   # west must be on PATH
./build.sh                  # both halves -> firmware-builds/*.uf2
./flash.sh left             # double-tap reset first, mounts as NICENANO
./flash.sh right
```

Every change is compile-time — rebuild and reflash **both** halves after editing
the keymap. Full setup and recovery steps are in
[`docs/corne-v3-this-repo.md`](docs/corne-v3-this-repo.md).
