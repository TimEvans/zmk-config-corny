# ZMK Reference

Condensed reference for the ZMK concepts used in this config, compiled from
[zmk.dev/docs](https://zmk.dev/docs). This repo tracks ZMK **v0.3** (see
`config/west.yml`). Syntax below is stable across recent versions, but always
cross-check the live docs for anything new.

For repo-specific layout, custom behaviors, and the build/flash workflow, see
[corne-v3-this-repo.md](./corne-v3-this-repo.md).

---

## Keymap file structure

A `.keymap` file is a devicetree source. Everything lives under the root node:

```dts
#include <behaviors.dtsi>            // defines &kp, &mo, &mt, &bt, etc.
#include <dt-bindings/zmk/keys.h>    // keycode aliases: A, N4, ESC, C_MUTE...
#include <dt-bindings/zmk/bt.h>      // bluetooth command aliases: BT_CLR...

/ {
    behaviors { /* custom behavior definitions */ };

    keymap {
        compatible = "zmk,keymap";   // REQUIRED on the keymap node

        default_layer {              // layer 0
            display-name = "Base";
            bindings = <
                &kp Q  &kp W  &kp E
                &kp A  &kp S  &kp D
            >;
        };
        // more layers...
    };
};
```

- The keymap node **must** have `compatible = "zmk,keymap"`. Node names are
  cosmetic.
- Layers are child nodes, numbered **sequentially from 0** in file order. The
  layer's index (not its name) is what `&mo`/`&to`/`&tog` reference.
- `bindings` is one behavior binding per physical key, ordered
  **left-to-right, top-to-bottom**. Key positions are zero-indexed the same way
  (see the position map in the repo-specific doc).
- All configuration is **compile-time**. Any change requires a rebuild + reflash.

---

## Key press: `&kp`

Sends a standard HID keycode on press/release. Parameter is a keycode alias from
`keys.h` (e.g. `A`, `N4`, `ESC`, `C_MUTE`, `LSHIFT`).

```dts
&kp A
&kp C_VOLUME_UP
```

Keycode categories: Keyboard, Modifiers, Keypad, Editing, Media, Applications,
Input Assist, Power & Lock. Full list:
[list-of-keycodes](https://zmk.dev/docs/keymaps/list-of-keycodes) and the
[keys.h source](https://github.com/zmkfirmware/zmk/blob/main/app/include/dt-bindings/zmk/keys.h).

### Modifier functions

Wrap a keycode to apply modifiers. Nest them to stack modifiers.

| Left            | Right           | Modifier |
| --------------- | --------------- | -------- |
| `LS(x)`         | `RS(x)`         | Shift    |
| `LC(x)`         | `RC(x)`         | Control  |
| `LA(x)`         | `RA(x)`         | Alt      |
| `LG(x)`         | `RG(x)`         | GUI / Win / Cmd |

```dts
&kp LS(A)         // Shift+A
&kp LC(RA(B))     // Ctrl+Alt+B
&kp LG(LS(N4))    // Cmd/Win + Shift + 4
```

Modified keys roll over safely: the modifier releases when the next key is
pressed, so `LS(A)` then `B` yields `Ab`.

### `&trans` and `&none`

- `&trans` — transparent: "fall through" to the same position on the
  next-lower active layer. Use on higher layers for keys you want unchanged.
- `&none` — explicitly does nothing (swallows the press). Use to disable a key.

---

## Layers

| Behavior   | Parameter | Effect |
| ---------- | --------- | ------ |
| `&mo n`    | layer #   | **Momentary** — layer active only while held. |
| `&to n`    | layer #   | Activate layer `n`, disable all others except the default. |
| `&tog n`   | layer #   | Toggle layer `n` on/off. |
| `&lt n KC` | layer #, keycode | **Layer-tap** — hold = layer `n`, tap = `KC` (a hold-tap, see below). |
| `&sl n`    | layer #   | **Sticky layer** — next key press uses layer `n`, then reverts. |

```dts
&mo 1            // hold for layer 1
&to 0            // jump to base layer
&lt 2 SPACE      // tap = space, hold = layer 2
```

`&to` and `&tog` **lock** a layer: a momentary `&mo` cannot turn it off; only
another `&to`/`&tog` can. Use `#define` for readable layer names:

```dts
#define DEF 0
#define LWR 1
#define RSE 2
&mo LWR          // same as &mo 1
```

---

## Hold-tap (the basis of home-row mods)

A hold-tap outputs one behavior when **held** and another when **tapped**.
`&mt` (mod-tap) and `&lt` (layer-tap) are predefined hold-taps; custom ones
(like this repo's `hrm`) are defined in the `behaviors` node.

```dts
hrm: home_row_mod {
    compatible = "zmk,behavior-hold-tap";
    #binding-cells = <2>;            // takes 2 params: <hold> <tap>
    bindings = <&kp>, <&kp>;         // 1st = hold action, 2nd = tap action
    flavor = "tap-preferred";
    tapping-term-ms = <250>;
    quick-tap-ms = <250>;
    require-prior-idle-ms = <250>;
    hold-trigger-key-positions = <16 15 14 13 19 20 21 22>;
};
// usage: &hrm LEFT_SHIFT D   -> hold = Shift, tap = D
```

### Properties

- **`bindings`** — two behaviors: `<&hold>, <&tap>`. The first keymap param
  feeds the hold behavior, the second feeds the tap.
- **`tapping-term-ms`** — how long to hold before it counts as a hold
  (default 200).
- **`flavor`** — how it resolves when another key is pressed mid-hold:
  - `hold-preferred` — hold triggers on term expiry **or** any other key press
    (default for `&mt`).
  - `tap-preferred` — hold triggers **only** on term expiry; other presses are
    ignored (default for `&lt`). Lower accidental-mod risk while typing fast.
  - `balanced` — hold triggers on term expiry **or** when another key is
    pressed *and released* during the hold. Good middle ground for home-row mods.
  - `tap-unless-interrupted` — taps unless another key is pressed before the
    term expires.
- **`quick-tap-ms`** — if the key is tapped then pressed again within this
  window, the second press always repeats the **tap** (enables tap-then-hold,
  e.g. holding a key to auto-repeat).
- **`require-prior-idle-ms`** — if pressed within this window of another
  non-modifier key, it always resolves as a **tap**. This is the main defense
  against accidental mods during fast typing.
- **`hold-trigger-key-positions`** — array of key positions. Hold only triggers
  if one of the listed positions is the next key pressed; otherwise it taps.
  Used to limit home-row mods to cross-hand combos. Positions are zero-indexed
  across the whole keymap.
- **`hold-trigger-on-release`** — evaluate `hold-trigger-key-positions` on key
  *release* instead of press, so you can chain multiple mods.
- **`retro-tap`** — if held and released with no other key pressed, still emit
  the tap.

---

## Bluetooth: `&bt`

Requires `#include <dt-bindings/zmk/bt.h>`. ZMK keeps **5 profiles** (0-4), each
bonded to one host.

| Command       | Effect |
| ------------- | ------ |
| `BT_SEL n`    | Select profile `n` (0-indexed). |
| `BT_NXT`      | Next profile (wraps). |
| `BT_PRV`      | Previous profile (wraps). |
| `BT_CLR`      | Clear the bond on the **current** profile. |
| `BT_CLR_ALL`  | Clear bonds on **all** profiles. |
| `BT_DISC n`   | Disconnect a paired-but-inactive profile. |

```dts
&bt BT_SEL 0     // switch to host 1
&bt BT_NXT
&bt BT_CLR       // forget the current host (also remove the keyboard on that host)
```

Selecting an unpaired/disconnected profile puts the keyboard into advertising
mode. Profile selection is persisted to flash. After `BT_CLR`, also delete the
keyboard from the host's Bluetooth settings or it won't re-pair.

---

## Reset behaviors

| Behavior      | Effect |
| ------------- | ------ |
| `&sys_reset`  | Soft reset — reboot the running firmware. |
| `&bootloader` | Reboot into bootloader (UF2 mass-storage) mode for flashing. |

On a split, both are **source-specific**: they only reset the half whose key was
pressed. Put the binding on both halves to reset each. Double-tapping the
physical reset button also enters bootloader mode.

---

## Combos

Defined in a `combos` node at the root (sibling of `keymap`). Pressing all
`key-positions` within `timeout-ms` fires `bindings`.

```dts
/ {
    combos {
        compatible = "zmk,combos";
        combo_esc {
            timeout-ms = <50>;
            key-positions = <0 1>;   // zero-indexed keymap positions
            bindings = <&kp ESC>;
            // layers = <0>;          // optional: restrict to layer(s)
        };
    };
};
```

- `key-positions` — positions that must be pressed together.
- `bindings` — any behavior (not just `&kp`).
- `timeout-ms` — window for all keys to land.
- `layers` (optional) — limit to specific layers; global if omitted.
- `require-prior-idle-ms` / `slow-release` — advanced tuning.

---

## Configuration (`.conf` / Kconfig)

`.conf` files hold global, compile-time settings as `CONFIG_XXX=value`:

- bool: `CONFIG_BT=y` / `=n`
- int: `CONFIG_ZMK_IDLE_TIMEOUT=30000`
- string: `CONFIG_ZMK_KEYBOARD_NAME="Corny"`

For a split, a shared `corne.conf` applies to **both** halves (per-side
`_left`/`_right` `.conf` files are ignored when a shared one exists). Useful
options: `CONFIG_BT`, `CONFIG_ZMK_SLEEP`, `CONFIG_ZMK_IDLE_TIMEOUT`,
`CONFIG_ZMK_KEYBOARD_NAME`. Full list:
[ZMK config index](https://zmk.dev/docs/config).

Devicetree settings (in `.keymap`) configure hardware/behaviors; Kconfig
settings (in `.conf`) toggle features. Both are compile-time.

---

## Useful links

- Behaviors index: https://zmk.dev/docs/keymaps/behaviors
- Full keycode list: https://zmk.dev/docs/keymaps/list-of-keycodes
- Config index: https://zmk.dev/docs/config
- Hold-tap / home-row mods: https://zmk.dev/docs/keymaps/behaviors/hold-tap
- Corne shield source: https://github.com/foostan/crkbd
