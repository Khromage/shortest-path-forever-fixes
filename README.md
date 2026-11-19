# Forever tracker → Questie tracker attach

A local patch for WoW: Forever that lets the shared Forever tracker column (Shortest Path Forever's journey steps,
and any other Forever addon section) attach to Questie's tracker instead of the game's own.

Status: **working in game** (ForeverCore v1.15.2, Shortest Path Forever v1.43.2, Questie 12.11.0), not yet upstream.

## Why

Questie hides the game's objective tracker and lists quests in its own frame, `Questie_BaseFrame`, wherever the
player put it. ForeverCore's tracker column only knows the game's `ObjectiveTrackerFrame`, so "Attach to quest
tracker" puts the journey steps where the hidden game tracker is, away from the quests.

## What it changes

Built on:

| Addon | Installed version | Upstream commit |
| --- | --- | --- |
| ForeverCore | v1.15.2 | `cjber/forever-core` 676cf21 |
| Shortest Path Forever | v1.43.2 | `cjber/shortest-path-forever` 3786d19 |
| Questie | 12.11.0 | read only, not modified |

### ForeverCore `UI/TrackerHost.lua` (the logic)

- New saved settings `trackerHost.target`: `nil` (game tracker) or `"questie"`, and `trackerHost.above`: `true`
  puts the column over Questie's list instead of under it.
- `QuestieTracker()` looks up `Questie_BaseFrame` on each use; `Tracker()` returns it when the target is
  `"questie"` and it exists, else `ObjectiveTrackerFrame`. Everything that used to read `ObjectiveTrackerFrame`
  for placement (`TrackerEdge`, `PinLeft`, `Anchor`) now reads `Tracker()`.
- **Under**: column's top left corner on the bottom left corner of Questie's frame. A hidden Questie tracker
  (nothing tracked) leaves the column at its top.
- **Above** (`above = true`): column's bottom left corner on Questie's top left corner, so the column grows
  upward and Questie's list never moves it. The probe watches Questie's top left corner instead.
- **Left** / no room under or above: column's top right corner at Questie's top left corner. Placed by coordinates on
  `UIParent`, never anchored to Questie's frame: the column holds protected item buttons, and an anchor would stop
  Questie moving its own tracker in combat.
- `WatchTracker()` runs each layout: re-aims the size probe at the followed tracker's bottom left corner (that is
  what makes the column follow a line added, a resize or a drag), hooks Questie's `OnShow`/`OnHide` once, and starts
  a once-a-second check (two minutes at most) for `Questie_BaseFrame`, which Questie creates some seconds after
  login with no event.
- New API: `ForeverCore.TrackerHost.GetTarget()` → `"game"|"questie"|"questieAbove"`, `SetTarget(value)`.
- Nothing runs in combat, as before; the layout after combat catches up.

### Shortest Path Forever `UI/Settings.lua` (the switch)

- Options → AddOns → Shortest Path Forever → Guidance → **Tracker to attach to**: a dropdown with "Game quest
  tracker", "Above Questie's tracker" and "Under Questie's tracker", under "Attach to quest tracker". Shown only when Questie is enabled and the
  installed ForeverCore has `SetTarget`.

Related existing behaviour worth knowing: **Lock the tracker** places the column once per session and then stops
following, so it should be off when attaching to Questie.

## Layout

- `files/` the patched files, CRLF, ready to drop into `Interface\AddOns`.
- `patches/` the same changes as diffs against the upstream commits above, for re-porting and for the pull requests.
  `forever-core-tests.patch` adds `tests/tracker_questie_spec.lua`.
- `tests/tracker_questie_spec.lua` the spec, for reference.
- `apply.ps1` re-applies after an addon update.

## After an addon update

CurseForge replaces the patched files. From this folder in PowerShell (an elevated one if `Program Files` refuses
the write):

```powershell
.\apply.ps1 -Check    # what state is each file in
.\apply.ps1           # apply; keeps a .orig backup next to each file
.\apply.ps1 -Revert   # back to the .orig backups
```

`apply.ps1` only overwrites a file whose hash is the exact upstream version the patch was built on. `CHANGED` means
upstream touched that file: re-port `patches/*.patch` onto the new version, rebuild `files/`, and update the two
hashes per file in `apply.ps1`.

## Running the spec

In a checkout of `cjber/forever-core` at the commit above, with the patches applied:

```sh
git apply patches/forever-core.patch patches/forever-core-tests.patch
luajit tests/tracker_questie_spec.lua
tools/gate
```

## Open issues

- Confirmed in game after a `/reload`: with target `questie`, placement `under`, Lock off, the column's top left
  corner is on the bottom left corner of `Questie_BaseFrame` (1568.3, 551.9 in both readouts).
- Seen once before that reload and not reproduced: the column sat left of the *game's* tracker position, and
  Questie's header was missing. Lock was on at the time. If it comes back, capture `ForeverTrackerHost.Debug()`.
- "Above" is not yet checked in game.
- The header menu's "Tracker position → Under the quest tracker" still reads "Under" when the target is above
  Questie's tracker; it means "attached" there.
- With Questie's "Sticky Durability Frame" on, the durability figure sits left of Questie's tracker top, the same
  spot the column falls back to when it has no room.
- Not localized beyond the English phrase keys; `Locales/enUS.lua` and `Locales/phrases.txt` need the three new
  phrases before a pull request.

## Upstreaming

Two pull requests, core first: `cjber/forever-core` (logic, spec, a `changes/` fragment), then
`cjber/shortest-path-forever` (dropdown, phrases, a `changes/` fragment) once a core release carries `SetTarget`.
ForeverCore's rule that nothing in it is addon specific may mean the author wants the Questie lookup supplied
differently; raise that in the core PR.

Both addons are GPL-3.0-or-later, and so is this patch.
