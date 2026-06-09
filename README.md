# Offdesk

A small macOS menu-bar app that tidies your Desktop on a schedule — moving files
into a destination folder and grouping them into dated subfolders like
`2026 June`. A modern, native Swift/SwiftUI menu-bar utility.

## Download

Grab the latest `Offdesk.dmg` from the
[**Releases**](https://github.com/carlrosell/offdesk/releases/latest) page, open
it, and drag **Offdesk** into Applications. Builds are signed with Developer ID
and notarized by Apple, so they open without Gatekeeper warnings.

Offdesk keeps itself up to date via [Sparkle](https://sparkle-project.org): it
checks for new versions in the background and offers them in place. You can also
check any time from the menu bar or the **Info** tab → **Check for Updates…**.

> Maintainers: see [RELEASING.md](RELEASING.md) for how releases are built,
> signed, and published from a `v*` git tag.

## What it does

- Lives in the menu bar (no Dock icon — it's an `LSUIElement` agent app).
- On a schedule, moves everything from your **source folders** (default: `~/Desktop`)
  into a **destination folder**, optionally grouped:
  - **Don't group** — one flat folder
  - **Group by month** — `2026 June`
  - **Group by day** — `2026 June 04`
- **Frequency**: a background timer wakes every 60 minutes and acts when
  - *daily*: the calendar day has changed since the last clean, or
  - *weekly*: the last clean was 7+ days ago.
- **Skip items with labels**: leaves any file carrying a Finder tag/label in place.
- **Undo last clean**: moves the most recent batch back to where it came from.
- Optional **launch at login** (via `SMAppService`) and **completion notifications**.

### Menu

`Last clean: …` · `Clean now` · `Open folder with cleaned items` · `Open app`
· `Undo last clean` · `Quit & Stop cleaning` · `Quit`

- **Quit** leaves automatic cleaning and the login item enabled (resumes next login).
- **Quit & Stop cleaning** disables automatic cleaning + the login item, then quits.

### Preferences window

Three tabs matching the original — **Status**, **Settings**, **Info**.

## Project layout

```
Offdesk.xcodeproj        # hand-authored, uses a synchronized file group
Offdesk/
  OffdeskApp.swift       # @main App: MenuBarExtra + preferences Window + AppDelegate
  Models/
    AppSettings.swift    # UserDefaults-backed, observable settings
    Grouping.swift       # none / month / day + folder-name formatting
    Frequency.swift      # daily / weekly "is a clean due?" logic
    CleanRecord.swift    # a clean's moves (for status + undo)
  Core/
    CleanEngine.swift    # the file mover (pure I/O, runs off the main thread)
    CleanController.swift# ties settings + scheduler + engine + history together
    Scheduler.swift      # 60-min timer + wake-from-sleep re-check
    LoginItemManager.swift
    Notifier.swift
    CleanHistoryStore.swift
  Views/                 # MenuContent + Preferences tabs
  Assets.xcassets/       # empty AppIcon set (drop your icon in) + AccentColor
```

The Xcode project uses a `PBXFileSystemSynchronizedRootGroup`, so any file you add
under `Offdesk/` is compiled automatically — no need to register it in the project.

## Build & run

Open in Xcode:

```sh
open Offdesk.xcodeproj
```

Then select the **Offdesk** scheme and press ⌘R. In **Signing & Capabilities**, pick
your team (automatic signing) the first time.

From the command line:

```sh
# Compile-check (no signing required)
xcodebuild -project Offdesk.xcodeproj -scheme Offdesk -configuration Debug \
  -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build

# Build a signed, runnable app with your team
xcodebuild -project Offdesk.xcodeproj -scheme Offdesk -configuration Release \
  DEVELOPMENT_TEAM=XXXXXXXXXX build
```

The built `Offdesk.app` is under Xcode's DerivedData (`Build/Products/...`). For
launch-at-login to work reliably, move `Offdesk.app` to `/Applications` and launch
it from there.

## Permissions

- **Desktop / Documents access**: the first time it reads `~/Desktop` or writes to
  a folder in `~/Documents`, macOS shows a TCC prompt — allow it. (The app is **not**
  sandboxed, which keeps file access simple for a personal utility. If you later want
  to distribute via the App Store, you'd enable the App Sandbox and switch to
  security-scoped bookmarks for the chosen folders.)
- **Notifications**: allowed on first launch if you want completion alerts.
- **Login item**: toggled from Settings → *Launch at login*.

## Defaults

| Setting          | Default                          |
|------------------|----------------------------------|
| Source folder    | `~/Desktop`                      |
| Destination      | `~/Documents/Desktop`            |
| Grouping         | Group by month                   |
| Frequency        | Every day                        |
| Skip labeled     | Off                              |
| Notifications    | On                               |
| Launch at login  | Off                              |

## Notes on behavior

- Grouping uses the **clean date** (when the clean runs), matching how the original
  created a new `YYYY Month` folder the first time it ran each month.
- Name collisions never overwrite: a clashing `report.pdf` becomes `report 2.pdf`.
- Hidden/system files (e.g. `.DS_Store`) are skipped.
- The destination folder is never moved into itself, even if it lives inside a
  source folder.
