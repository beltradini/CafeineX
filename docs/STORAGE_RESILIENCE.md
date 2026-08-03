# Storage resilience

## Pilot behavior

CafeineX no longer terminates with `fatalError` when its SwiftData container cannot open. Startup first attempts the current V5 store and the supported legacy V3 recovery path. If neither succeeds, the app presents **CafeineX Support** instead of the main interface.

The support screen offers:

- **Try Again**, which reopens the existing store without deleting it.
- **Preserve Data and Start Fresh**, which requires confirmation, copies `default.store`, `default.store-wal`, and `default.store-shm` when present into `CafeineX Store Recovery/manual-recovery-*`, writes `storage-error.txt`, and only then creates a fresh V5 store.
- TestFlight support instructions and selectable technical details using the `STORAGE-OPEN` prefix.

If backup creation fails, the active store is not removed. If fresh-store creation fails after backup, CafeineX attempts to restore the preserved files and remains on the support screen.

## Save failures

User-triggered SwiftData saves must propagate errors. `PersistenceIssueCenter` presents a visible **Could Not Save** alert with **Try Again** and **Dismiss**. Success UI such as dismissing an editor, haptic feedback, or confirming an action only occurs after `ModelContext.save()` succeeds.

This applies to caffeine and nicotine events, cigarette and drink profiles, profile creation, goals and preferences, history edits/deletes, favorites, archive/restore/reordering, bootstrap/backfill work, and local HealthKit synchronization state.

## HealthKit boundary

Storage recovery only changes CafeineX's local SwiftData store. It does not delete or modify samples imported from Apple Health. HealthKit writes remain governed by their separate authorization and synchronization flow.

## Pilot verification

- `./Scripts/cx build`
- `./Scripts/cx test`
- Confirm the source contains no `fatalError` or `try? ... save()` persistence paths.
- On a disposable test installation, make the local store unreadable, verify the support screen, retry once, then confirm that manual recovery creates the backup family before the fresh store opens.
