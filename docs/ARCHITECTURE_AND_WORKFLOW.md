# CafeineX Architecture and Xcode Workflow

## Current architecture

CafeineX uses a feature-first shell with explicit boundaries:

1. `CafeineXApp` is the composition root. It opens `CafeineXSchemaV3` through `CafeineXMigrationPlan`, injects app-wide preference stores, and launches `AppShellView`.
2. `AppShellView` owns the native adaptive tab shell: Home, History, Profile, and the system Search role. It also presents the single app-wide Quick Add flow.
3. `HomeView` composes focused dashboard components and observes bounded 30-day caffeine and nicotine queries.
4. `HistoryView` queries the complete retained local timeline and provides contextual search, substance/source/date filters, daily grouping, detail, editing, deletion, and separate aggregate totals.
5. `SearchView` performs global search over the same combined exposure representation used by Home and History.
6. `ExposureItem` is a presentation-only adapter over `CaffeineEntry` and `NicotineEntry`. It never merges persisted models or their units.
7. `HomeViewModel` coordinates local persistence, calculation, and HealthKit reconciliation on the main actor.
8. `CaffeineEngine` accepts persistence-independent `CaffeineDose` values and returns `CaffeineStatus`.
9. `HealthKitProviding` isolates Apple Health from the feature and gives tests a deterministic substitute.
10. `CaffeineEntry` persists the local record and the HealthKit UUID used for idempotent synchronization. Imported or Health-linked caffeine events remain read-only in the app to avoid local/Health divergence.
11. `SleepScheduleStore` persists bedtime and cutoff preferences, while `SleepSchedule` remains a testable value passed explicitly into `CaffeineEngine`.
12. `CaffeineSensitivityStore` persists a lower, typical, or higher response profile. Profiles adjust guidance thresholds but never alter calculated caffeine exposure or the general 400 mg reference.
13. `NicotineEntry` persists product, amount, unit, timestamp, source, and an optional note without writing an unsupported nicotine type to HealthKit.
14. `NicotineEngine` turns events into product-specific observation windows and bedtime guidance without claiming absorbed dose.
15. `DailyExposureContext` combines caffeine and nicotine timing, counts same-day temporal overlaps, and keeps all quantities on separate axes.
16. `Drink` is the single source for My Drinks, Home favorites, and Quick Add. Archiving hides a drink without rewriting historical exposure events.
17. `UserProfile` keeps a stable local identity and sync revision. A future Sign in with Apple implementation can associate that identity while keeping credentials in Keychain.
18. `AwarenessCheckIn` and `StreakEngine` maintain awareness and sleep-protection streaks without rewarding stimulant consumption or treating missing data as success.

The dashboard keeps the 30-day synchronization window in memory but renders only the 20 most recent rows. `HistoryView` reads every retained local entry; records are not deleted by the dashboard limit or the HealthKit synchronization window.

## Data flow

Manual entry:

`QuickAddSheet -> AppShellView -> HomeViewModel -> SwiftData save -> CaffeineEngine -> optional HealthKit save`

Nicotine entry:

`QuickAddSheet -> AppShellView -> HomeViewModel -> SwiftData save -> NicotineEngine -> DailyExposureContext`

Apple Health sync:

`HealthKitService -> HomeViewModel reconciliation -> SwiftData save -> CaffeineEngine -> HomeView`

History and search:

`SwiftData queries -> ExposureItem.combined -> ExposureSearchEngine -> History/Search presentation`

The local save happens before the optional HealthKit write. A HealthKit failure therefore cannot erase a user's log.

## Xcode workflow

- Shared scheme: `CafeineX`
- Language mode: Swift 6
- Concurrency checking: complete
- Default scheme tests: `CafeineXTests` and `CafeineXUITests`
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
2. Keep imported and Health-linked caffeine records read-only until coordinated HealthKit deletion and editing are implemented explicitly.
3. Keep any future exposures in separate models and engines; never merge their quantities into caffeine or nicotine totals.
4. Add background HealthKit delivery only after foreground synchronization has device-level reliability evidence.
