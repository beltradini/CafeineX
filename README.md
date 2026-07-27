# CafeineX

CafeineX is an iOS caffeine-intelligence app built with SwiftUI, SwiftData, and HealthKit. It estimates active caffeine as a range against a configurable sleep schedule and response sensitivity, provides a searchable full-history timeline, and reconciles authorized caffeine records with Apple Health without duplicating app-owned samples.

## Open and verify

Open `CafeineX.xcodeproj` in Xcode 26.6 or newer and select the shared `CafeineX` scheme.

From Terminal:

```sh
./Scripts/cx build
./Scripts/cx test
./Scripts/cx analyze
```

The helper keeps DerivedData in `/tmp/CafeineXDerivedData`, disables signing for command-line builds, and runs only the fast unit-test target by default.

## Project map

- `CafeineX/App`: composition root and SwiftData container.
- `CafeineX/Core`: calculation, persistence models, and HealthKit boundary.
- `CafeineX/Features`: user-facing feature slices.
- `CafeineX/Shared`: reusable visual system.
- `CafeineXTests`: deterministic engine and HealthKit reconciliation tests.
- `docs`: architecture, workflow, and phase boundaries.

See [architecture and workflow](docs/ARCHITECTURE_AND_WORKFLOW.md) and [phase 0–1 scope](docs/PHASE_0_1_FOUNDATION.md).
