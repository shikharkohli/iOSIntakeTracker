# IntakeTracker

A simple iOS + Apple Watch app for tracking water, caffeine, and post-meal fullness. Designed around quick taps — glasses, not milliliters.

## Features

**Water** — One-tap presets: ½ Glass, 1 Glass, Bottle (2 glasses). No mL math.

**Caffeine** — Tap a drink (Coffee 95mg, Espresso 63mg, Tea 40mg, Energy Drink 160mg, Soda 35mg) or enter a custom amount on iOS.

**Fullness** — After a meal, log how full you feel on a 1–5 emoji scale (😋 → 🥴).

**Weight & Waist** — Quick log with +/- buttons pre-filled from your last reading. Units follow your locale (kg/cm on metric, lb/in on imperial).

**History** — Day-grouped list on iOS, filter by type, swipe to delete.

**Watch ↔ Phone sync** — Entries logged on either device sync via WatchConnectivity.

## Architecture

- **SwiftUI** for both targets
- **UserDefaults** for local persistence (`intake.entries.v1`) — no HealthKit, no CoreData; the focus is friction-free logging
- **WatchConnectivity** for sync: deltas via `transferUserInfo`, full snapshots via `updateApplicationContext`
- **Shared/** folder is compiled into both targets — single source of truth for models, store, and sync

```
Shared/
  Models/IntakeEntry.swift     # IntakeType, IntakeEntry, FullnessLevel, *Preset
  Store/IntakeStore.swift      # ObservableObject + UserDefaults persistence
  Sync/SyncService.swift       # WCSessionDelegate
  Formatting.swift             # display helpers
IntakeTracker/                 # iOS app
IntakeTracker Watch App/       # watchOS app (embedded in iOS app)
```

## Setup

Two paths — pick one.

### Option A: XcodeGen (recommended)

A `project.yml` is included. Generate the Xcode project from it:

```sh
brew install xcodegen
cd /path/to/iOSIntakeTracker
xcodegen generate
open IntakeTracker.xcodeproj
```

Re-run `xcodegen generate` whenever you add/remove source files.

### Option B: Create the project manually in Xcode

1. In Xcode 15+, **File → New → Project → iOS → App**, name it `IntakeTracker`, language Swift, interface SwiftUI. Save it inside this repo's root so the existing source folders sit next to it.
2. **File → New → Target → watchOS → App**, name it `IntakeTracker Watch App`, embed in the iOS app when prompted.
3. Delete the auto-generated `ContentView.swift` and `IntakeTrackerApp.swift` from both targets.
4. Drag these folders from Finder into the Xcode navigator (use **"Create groups"**, *not* "Create folder references"):
   - `Shared/` → add to **both** targets
   - `IntakeTracker/` → add to the iOS target only
   - `IntakeTracker Watch App/` → add to the watch target only
5. In each target's **General** tab, confirm the bundle IDs match: iOS = `com.example.IntakeTracker`, watch = `com.example.IntakeTracker.watchkitapp`.

## Before building

- Open the project in Xcode, select each target, and set **Signing & Capabilities → Team** to your Apple ID team. (For the simulator you can leave it unsigned.)
- Bundle IDs use `com.example.*` placeholders — change to your own reverse-DNS prefix if you plan to install on a real device.
- Deployment targets: iOS 17.0, watchOS 10.0.

## Running

- **Simulator**: select the `IntakeTracker` scheme + an iPhone simulator and run. To see the watch app, run the `IntakeTracker Watch App` scheme on a paired Watch simulator.
- **Device**: pair an Apple Watch with your iPhone, install the iOS app, and the watch app will be offered for install on the Watch app's "My Watch" tab.

## Notes

- All data lives in UserDefaults — uninstalling the app clears history.
- HealthKit integration is intentionally omitted; "easy inputs" was the explicit design goal.
