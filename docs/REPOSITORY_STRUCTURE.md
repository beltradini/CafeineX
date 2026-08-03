# CafeineX Repository Structure

## Application repository

This repository contains only inputs needed to build, test, review, and operate
the CafeineX iOS application:

- `CafeineX`: app composition, domain logic, persistence, features, and shared UI.
- `CafeineXTests`: deterministic unit and migration tests.
- `CafeineXUITests`: end-to-end interface and launch tests.
- `CafeineX.xcodeproj`: targets, shared scheme, capabilities, and build settings.
- `Scripts`: reproducible build, test, and analysis commands.
- `docs`: architecture, migration, privacy, and completed phase records.

The source target follows four stable boundaries:

- `App`: composition root and navigation shell.
- `Core`: models, engines, persistence, settings, and system integrations.
- `Features`: user-facing vertical slices.
- `Shared`: reusable presentation components and design tokens.

Do not create placeholder directories for future features. Add a directory only
when it owns at least one source file and has a clear responsibility.

## Companion workspace

Brand identity, campaign production, exported creative assets, and the public
website live in the separate `CafeineX Brand` workspace. They are deliberately
not application build inputs.

That workspace should have its own version-control strategy. The website already
has an independent Git repository; Branding and Marketing should also be placed
under a dedicated repository before the removals from this app repository are
committed.

## Change rules

1. Keep generated build products and dependency caches outside Git.
2. Keep the app icon used by Xcode inside `CafeineX/CafeineX.icon`.
3. Keep source artwork and campaign exports in the companion workspace.
4. Keep release and compliance evidence with the release process, not the app target.
5. Re-run `./Scripts/cx build` after every structural change.
6. Re-run the complete test suite before any TestFlight build.
