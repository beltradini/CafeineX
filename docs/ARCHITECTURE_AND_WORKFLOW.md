# CafeineX Architecture and Xcode Workflow

## Current architecture

CafeineX uses a feature-first shell with explicit boundaries:

1. `CafeineXApp` is the composition root. It opens `CafeineXSchemaV2` through `CafeineXMigrationPlan` and launches `TodayView`.
2. `TodayView` owns dashboard presentation and observes bounded 30-day caffeine and nicotine queries.
3. `HistoryView` queries the complete retained local timeline and provides search, substance/source filters, daily grouping, and separate aggregate totals.
4. `TodayViewModel` coordinates local persistence, calculation, and HealthKit reconciliation on the main actor.
5. `CaffeineEngine` accepts persistence-independent `CaffeineDose` values and returns `CaffeineStatus`.
6. `HealthKitProviding` isolates Apple Health from the feature and gives tests a deterministic substitute.
7. `CaffeineEntry` persists the local record and the HealthKit UUID used for idempotent synchronization.
8. `SleepScheduleStore` persists bedtime and cutoff preferences, while `SleepSchedule` remains a testable value passed explicitly into `CaffeineEngine`.
9. `CaffeineSensitivityStore` persists a lower, typical, or higher response profile. Profiles adjust guidance thresholds but never alter calculated caffeine exposure or the general 400 mg reference.
10. `NicotineEntry` persists product, amount, unit, timestamp, source, and an optional note without writing an unsupported nicotine type to HealthKit.
11. `NicotineEngine` turns events into product-specific observation windows and bedtime guidance without claiming absorbed dose.
12. `DailyExposureContext` combines caffeine and nicotine timing, counts same-day temporal overlaps, and keeps all quantities on separate axes.

The dashboard keeps the 30-day synchronization window in memory but renders only the 20 most recent rows. `HistoryView` reads every retained local entry; records are not deleted by the dashboard limit or the HealthKit synchronization window.

## Data flow

Manual entry:

`TodayView -> TodayViewModel -> SwiftData save -> CaffeineEngine -> optional HealthKit save`

Nicotine entry:

`TodayView -> TodayViewModel -> SwiftData save -> NicotineEngine -> DailyExposureContext`

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

1. Extend `CafeineXMigrationPlan` and its disk-backed migration tests before every SwiftData schema change. The V1 compatibility test reproduces the original unversioned store so adopting the plan cannot discard existing data.
2. Define coordinated SwiftData and HealthKit deletion semantics before adding destructive history actions.
3. Keep any future exposures in separate models and engines; never merge their quantities into caffeine or nicotine totals.
4. Add background HealthKit delivery only after foreground synchronization has device-level reliability evidence.
