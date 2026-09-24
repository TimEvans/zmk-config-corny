# zmk-config-corny

Personal [ZMK](https://zmk.dev) firmware config for a **Corne v3 (42-key)** split
keyboard on two **nice!nano v2** controllers, connected over Bluetooth.

This is a config repo (keymap + Kconfig), not a fork of ZMK — ZMK is pulled in as
a west dependency (`config/west.yml`, pinned to `v0.3`). Builds are local; see
[`CLAUDE.md`](CLAUDE.md) and [`docs/`](docs/) for the toolchain setup and workflow.

## Keymap

Six layers, referenced by index. `L1`/`L2`/`L4`/`L5` are momentary layer
holds (`&mo`), `TG3` toggles the gaming layer (`&tog 3`), and `▽` is a
transparent key (falls through to the next active layer below).

### Layer 0 — Default (QWERTY + home-row mods)

```
 Tab    Q     W     E     R     T   │   Y     U     I     O     P    Bksp
 Ctrl   A     S     D     F     G   │   H     J     K     L     ;     '  
 Shft   Z     X     C     V     B   │   N     M     ,     .     /    Esc 
                   Alt    L2   Ent  │  Spc    L1   GUI 
```

**Home-row mods** (right hand only) — held, these keys act as modifiers;
tapped, they type the letter (hold-tap, 250 ms term). The left hand has no
home-row mods so `WASD` and the surrounding keys behave as plain keys for
gaming:

| Finger | Right | Modifier |
|--------|-------|----------|
| index  | `J`   | Ctrl     |
| middle | `K`   | Shift    |
| ring   | `L`   | GUI      |
| (lower)| `M`   | Alt      |

### Layer 1 — Lower (symbols, navigation, media)

Held via the right inner thumb (`L1`).

```
 Tab    &     @     /     \     ^   │  Home  PgDn  PgUp  End   Mute  Bksp
 Ctrl   !     ?     #     $     %   │   ←     ↓     ↑     →     :    Del 
 Shft   `     ▽     ▽    Bri-  Bri+ │  Prev  Vol-  Vol+  Next  Play  Esc 
                   Alt    L5   Ent  │  Spc    ▽    GUI 
```

### Layer 2 — Raise (numbers, math, brackets)

Held via the left inner thumb (`L2`).

```
 Tab    *     7     8     9     -   │   _     =     (     )     |    Bksp
 Ctrl   /     4     5     6     +   │   -     +     [     ]     :    Del 
 Shft   0     1     2     3     .   │   *     <     {     }     >     ~  
                   Alt    L5   Ent  │  Spc    L5   GUI 
```

### Layer 3 — Game (toggled)

Toggled on and off with `TG3` on the Fn layer (`Y` position). It stays on until
toggled off again, so the momentary layers below can be held and released on top
of it without leaving gaming mode. Left hand is the default layout with Space on
the inner thumb and the game numpad (`L4`) on the middle thumb; the right hand
is plain keys (no home-row mods) with Enter on the middle thumb for chat.

```
 Tab    Q     W     E     R     T   │   Y     U     I     O     P    Bksp
 Ctrl   A     S     D     F     G   │   H     J     K     L     ;     '  
 Shft   Z     X     C     V     B   │   N     M     ,     .     /    Esc 
                   Alt    L4   Spc  │  Spc   Ent   GUI 
```

Enter gaming from Base: right thumb (`L1`), left middle thumb (`L5`), `Y`.
Leave it from Game: left middle thumb (`L4`), shift (`L5`), `Y`.

### Layer 4 — Game numpad (held from Game)

Same numpad as Raise, one-handed. The shift position holds the Fn layer, which
turns the numpad into F-keys in the same columns (7 8 9 becomes F7 F8 F9).

```
  ▽     *     7     8     9     -   │   ▽     ▽     ▽     ▽     ▽     ▽  
  ▽     /     4     5     6     +   │   ▽     ▽     ▽     ▽     ▽     ▽  
  L5    0     1     2     3     .   │   ▽     ▽     ▽     ▽     ▽     ▽  
                    ▽     ▽     ▽   │   ▽     ▽     ▽  
```

### Layer 5 — Fn (function keys, system, Bluetooth)

Reached by holding `L5` from Lower, Raise or the Game numpad. Must remain the
highest-index layer: it is activated while Game and Game numpad are also active,
and the highest active index wins. `Rset` = soft reset, `Boot` = bootloader (for
flashing), `BTclr` = clear the active Bluetooth bond, `TG3` = toggle Game.

```
 Rset  Boot   F7    F8    F9   F10  │  TG3    ▽     ▽     ▽     ▽   BTclr
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
