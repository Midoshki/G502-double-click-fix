# Double Click Destroyer 5000

Stops the buttons of a Logitech **G502** from double-clicking, and keeps **G HUB** and your macros.

Worn mouse switches "chatter": one press arrives as two. This tool ignores a second press that
comes within a short time of the previous release of the same button.

## Download and run

1. Download `DoubleClickDestroyer.cmd` from the
   [latest release](https://github.com/Midoshki/G502-double-click-fix/releases/latest).
2. Double-click it.
3. Tick the buttons that double-click and press **Enter**.

Nothing to install. It needs Windows 10 or 11 and G HUB. Run it again at any time to see what is
set up, change it, or remove the fix.

**"Windows protected your PC":** the file isn't signed, so SmartScreen warns about it. Choose
*More info → Run anyway*. Some antivirus programs are suspicious of any `.cmd` file that starts
PowerShell. The whole tool is the one readable text file, so you can check what it does.

**Work computers** often block PowerShell scripts. The tool then stops with an error and changes
nothing.

## Controls

| Key | Does |
|---|---|
| Up / Down | move between buttons |
| Space | fix on / off for that button |
| Left / Right | shorter / longer ignore time (10 ms steps) |
| Enter | apply |
| R | untick everything (then Enter removes the fix) |
| P | next G HUB profile |
| Esc | quit |

Side buttons start at 150 ms. Left, right and wheel click start at 50 ms, so real double-clicks
still work.

## Choosing the ignore time

- **Too short:** some double clicks get through. Chatter usually arrives 30 to 130 ms after the release.
- **Too long:** fast deliberate clicks get swallowed, because the ignore time limits how fast you can
  click that button.

## Profiles

G HUB keeps separate button settings per profile, and many games get their own profile. The fix
only applies to the profile you set it up on. If a button still double-clicks in a game, press **P**
in the tool to switch to that game's profile and fix it there too. The screen shows which profiles
have the fix.

## Changing a fixed button later

You can keep editing your macros in G HUB. When you next run the tool, it spots buttons that changed
since the fix was applied (marked **!**) and **Enter** updates them:

- a macro renamed, or a new action put on a fixed button: the fix moves to the new action,
- a fixed button reset in G HUB: the fix is put back,
- the button's action deleted: shown as a warning, untick the button to clear it.

## Supported mice

| Mouse | Status |
|---|---|
| G502 LIGHTSPEED | tested |
| G502 HERO (including the special editions) | should work, untested |
| G502 Proteus Spectrum / Proteus Core | should work, untested |
| G502 X / X LIGHTSPEED / X PLUS | unknown |

If yours is a G502 and the tool says no G502 was found, please open an issue with your exact model.

## How it works

G HUB can run a small Lua script per profile. For each button you tick, the tool:

- turns off the button's normal G HUB action and moves it to that button's unused **G-Shift** slot,
- writes a script that runs that action once per real press and ignores chatter.

The tool creates and writes the script through G HUB itself, then closes and restarts G HUB once to
switch the buttons over. It starts G HUB if it isn't running. Removing the fix puts every button back.

## If something goes wrong

Every change starts with a backup in `%LOCALAPPDATA%\dcd5000\backups`, one folder per change, named
by date and time. To go back to how things were before a change:

1. Quit G HUB completely (right-click its tray icon → Quit).
2. Open the backup folder from just before the problem started.
3. Copy the backup's `settings.db` files (`settings.db`, and `settings.db-shm` / `settings.db-wal`
   if present) into `%LOCALAPPDATA%\LGHUB`, replacing the files there. If the backup has no
   `-shm` or `-wal` file, delete that file from `%LOCALAPPDATA%\LGHUB`.
4. If the backup has a `scripts` folder, copy it into `%LOCALAPPDATA%\LGHUB` too.
5. Start G HUB.

If left click stops working while it's fixed, you can remove the fix with the keyboard alone: run
the tool, press R, then Enter.

## Measuring chatter (optional)

`tools/clicklog.ps1` records how far apart button presses arrive, without changing anything.
Useful for picking an ignore time:

```
powershell -ExecutionPolicy Bypass -File tools\clicklog.ps1 -Seconds 60
```

Untick a button in the tool first if you want to see its raw chatter.

## Limits

- Works on buttons assigned to a macro, a keystroke, a key or a mouse button (left, right, middle,
  back, forward). Buttons with other built-in functions (DPI, wheel tilt, ...) are shown in grey.
  Assign one of the supported actions in G HUB to make them fixable.
- Scripts start macros by name, and G HUB allows two macros to share a name. A button whose macro
  shares its name with another one can't be fixed until you rename one of them.
- A button whose G-Shift slot is already in use can't be fixed. If you use a G-Shift button, holding
  it and pressing a fixed button runs that button's action directly, without the fix.
- The fix ignores repeats *after* a release. If a switch chatters while you **hold** it (a drag
  that drops), that is not fixed.
- Does not work when the mouse is in **on-board memory** mode, because scripts only run in software
  mode. The tool warns when it sees that.
- Don't change anything in G HUB during the few seconds the tool is applying a change; G HUB is
  closed during that time and the change could be lost.
- If a profile already has a G HUB script of your own, the tool asks before replacing it.

## License

MIT, see [LICENSE](LICENSE).
