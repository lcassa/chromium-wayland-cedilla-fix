# chromium-wayland-cedilla-fix

Make **`' + c` produce `ç`** (and `' + C` produce `Ç`) in **Chromium on native
Wayland** — without an input method framework (no fcitx5, no ibus), keeping the
native Wayland backend.

Targeted at **Arch Linux / Arch Linux ARM** + Wayland compositors (Hyprland,
Sway, river, …) using the **US-International** layout, but the technique works
anywhere.

---

## The problem

On the US-International layout, `'` is a dead key (`dead_acute`). Pressing
`' + c` *should* be configurable to produce the cedilla `ç`, and on most apps it
is — via `~/.XCompose` / the system Compose table.

But **Chromium on native Wayland ignores `~/.XCompose` and `XCOMPOSEFILE`
entirely.** Instead of libxkbcommon, it uses ChromeOS' `ui::CharacterComposer`
with a **compose table compiled into the binary**. That table hardcodes
`dead_acute + c → ć` (LATIN SMALL LETTER C WITH ACUTE, U+0107), so Portuguese /
French / Catalan / Turkish users get `ć` instead of `ç`.

This is a known, still-open Chromium bug:
[crbug 40272818 — *Custom compose key sequences (.XCompose) do not work on
Chrome + Wayland*](https://issues.chromium.org/issues/40272818).

The usual "solutions" each cost you something:

| Workaround | Keeps `'+c`→ç | Native Wayland | No IME |
|---|:--:|:--:|:--:|
| Run Chromium under X11 (`--ozone-platform=x11`) | ✅ | ❌ | ✅ |
| fcitx5 / ibus + `--enable-wayland-ime` | ✅ | ✅ | ❌ |
| **This patch** | ✅ | ✅ | ✅ |

## How it works

The hardcoded compose table stores entries as `[input uint16 LE][output uint16
LE]`. The acute-accent row looks like `a→á, c→ć, e→é, …`. We change **only** the
output of `c`/`C`:

```
c (0x0063) -> ć (0x0107):   63 00 07 01   =>   63 00 e7 00   (ç U+00E7)
C (0x0043) -> Ć (0x0106):   43 00 06 01   =>   43 00 c7 00   (Ç U+00C7)
```

The patch matches by **byte pattern, not by offset**, so it keeps working across
Chromium releases (3 copies of the table exist in the binary; all are patched).
Nothing else is touched — every other accent (`'+a`→á, `'+e`→é, …) is unchanged.

> Heads up: after this, you can no longer type `ć`/`Ć` via `' + c` in Chromium.
> If you need those, type them another way.

## Install (Arch / Arch Linux ARM)

```bash
git clone https://github.com/lcassa/chromium-wayland-cedilla-fix.git
cd chromium-wayland-cedilla-fix
sudo ./install.sh
```

This:
1. installs `chromium-cedilla-patch.py` to `/usr/local/bin/`,
2. installs a **pacman hook** (`/etc/pacman.d/hooks/`) that re-applies the patch
   automatically after every `chromium` upgrade,
3. applies the patch once.

Then **restart Chromium completely** and test `' + c` → `ç`.

If your Chromium binary is not at `/usr/lib/chromium/chromium`, pass the path:

```bash
sudo ./install.sh /path/to/chromium
```

## Uninstall

```bash
sudo ./uninstall.sh
```

Restores the pristine binary from the `.orig` backup and removes the hook/script.

## Caveats (please read)

- **This patches a system binary.** It is unofficial. A pristine `.orig` backup
  is made before the first patch, and a timestamped `.bak-*` on every run.
- If a future Chromium version changes the compose-table layout, the pattern
  won't match — the script then **does nothing and warns** (it never corrupts
  the binary). If that happens, please open an issue.
- The pacman hook keeps it applied across upgrades; if you install Chromium via
  Flatpak/Snap instead, you'll need to adapt the path and re-apply mechanism.

## License

MIT — see [LICENSE](LICENSE).
