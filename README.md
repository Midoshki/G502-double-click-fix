# Double Click Destroyer 5000

Stops the side buttons of a Logitech **G502** from double-clicking, and keeps **G HUB** and your macros.

Worn mouse switches "chatter": one press arrives as two. This tool ignores a second press that
comes within a short time (150 ms by default) of the previous release of the same button.

## Use

1. Download `DoubleClickDestroyer.cmd`.
2. Double-click it. If Windows SmartScreen warns, choose *More info → Run anyway*.
3. Tick the buttons that double-click and press **Enter**.

| Key | Does |
|---|---|
| Up / Down | move between buttons |
| Space | fix on / off for that button |
| Left / Right | shorter / longer ignore time (10 ms steps) |
| Enter | apply |
| R | untick everything (then Enter removes the fix) |
| P | next G HUB profile |
| Esc | quit |

Side buttons start at 150 ms. Left, right and wheel click start at 50 ms, which is short enough
that real double-clicks still work.

Nothing to install. It needs Windows 10 or 11 and G HUB. Run it again at any time to see what
is set up, change it, or remove the fix.

## How it works

G HUB can run a small Lua script per profile. The tool:

- turns off the button's normal G HUB action and moves it to that button's unused **G-Shift** slot,
- writes a script that runs that action once per real press and ignores chatter,
- closes and restarts G HUB to apply this.

Your macros stay in G HUB. Removing the fix puts every button back the way it was.
Before every change it saves a backup to `%LOCALAPPDATA%\dcd5000\backups`.

## Measuring chatter (optional)

`tools/clicklog.ps1` records how far apart button presses arrive, without changing anything.
Useful for picking an ignore time:

```
powershell -ExecutionPolicy Bypass -File tools\clicklog.ps1 -Seconds 60
```

## Limits

- **First time on a profile:** only G HUB can create a profile's script. If the tool asks, open the
  profile in G HUB → *Scripting* → create a new Lua script → save it empty, then run the tool again.
- Works on buttons assigned to a macro, a keystroke, a key or a mouse button (left, right, middle,
  back, forward). Buttons with other built-in functions (DPI, wheel tilt, ...) are shown in grey.
  Assign one of the supported actions in G HUB to make them fixable.
- A button whose G-Shift slot is already in use can't be fixed.
- **Left click:** while fixed, every left click goes through G HUB's script. If G HUB ever stops the
  script, left click stops working until you remove the fix. You can do that with the keyboard
  alone: run the tool, press R, then Enter.
- The fix ignores repeats *after* a release. If a switch chatters while you **hold** it (a drag
  that drops), that is not fixed.
- Does not work when G HUB is in **onboard memory** mode, because scripts only run in software mode.
- Tested on a G502 LIGHTSPEED with G HUB 2026.7. Other G502 models should work but are untested.
