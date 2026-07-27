# CafeineX Architecture and Xcode Workflow

## Current architecture

CafeineX uses a feature-first shell with explicit boundaries:

1. `CafeineXApp` is the composition root. It creates the SwiftData schema and launches `TodayView`.
2. `TodayView` owns presentation and observes a bounded 30-day SwiftData query.
3. `TodayViewModel` coordinates local persistence, calculation, and HealthKit reconciliation on the main actor.
4. `CaffeineEngine` accepts persistence-independent `CaffeineDose` values and returns `CaffeineStatus`.
5. `HealthKitProviding` isolates Apple Health from the feature and gives tests a deterministic substitute.
6. `CaffeineEntry` persists the local record and the HealthKit UUID used for idempotent synchronization.

The dashboard keeps the 30-day synchronization window in memory but renders only the 20 most recent rows. Older records remain in SwiftData and are not deleted.

## Data flow

Manual entry:

`TodayView -> TodayViewModel -> SwiftData save -> CaffeineEngine -> optional HealthKit save`

Apple Health sync:

`HealthKitService -> TodayViewModel reconciliation -> SwiftData save -> CaffeineEngine -> TodayView`

The local save happens before the optional HealthKit write. A HealthKit failure therefore cannot erase a user's log.

## Xcode workflow

- Shared scheme: `CafeineX`
- Language mode: Swift 6
- Concurrency checking: complete
- Default scheme tests: `CafeineXTests`
- Command-line DerivedData: `/tmp/CafeineXDerivedData`

Fast verification:

```sh
./Scripts/cx build
./Scripts/cx test
```

Static analyzer:

```sh
./Scripts/cx analyze
```

Override the DerivedData location when needed:

```sh
CAFEINEX_DERIVED_DATA_PATH=/tmp/CafeineXExperiment ./Scripts/cx build
```

## Local machine warning found during the audit

`~/.zshenv` currently sources `~/.cargo/env` unconditionally, but that file does not exist. This prints an error before every shell/Xcode command. Replace the line locally with:

```sh
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
```

This is a user-level shell setting, not a repository file, so it is intentionally not changed by CafeineX.

## Next architectural gates

Before adding watchOS, widgets, App Intents, or stimulant-interaction features:

1. Add user-owned bedtime and caffeine-sensitivity settings behind a dedicated settings domain.
2. Add migration tests before changing the SwiftData schema.
3. Add a separate history feature before exposing the complete retained timeline.
4. Keep nicotine or other exposures in a separate model and engine; do not merge their quantities into caffeine milligrams.
5. Add background HealthKit delivery only after foreground synchronization has device-level reliability evidence.

