# Historical V3 store recovery

## Purpose

Some development installations were written with a schema identified as
`3.0.0` whose structural checksum does not match the frozen migration path.
Core Data rejects those stores with error `134504`: “Cannot use staged
migration with an unknown model version.”

CafeineX keeps the normal `CafeineXMigrationPlan` as the first and preferred
path. The recovery path runs only after normal container creation fails and the
SQLite store passes every V3-specific validation.

## Eligibility

A store is eligible only when:

- SQLite opens read-only and `PRAGMA quick_check` returns `ok`.
- Core Data metadata contains the single version identifier `3.0.0`.
- Every expected V3 table exists.
- V4-only `DrinkDetails` and `PhaseCSchemaState` tables do not exist.
- Required UUIDs, text values, dates, and positive quantities can be decoded.
- Unique identifiers are actually unique.

Other unknown, damaged, or future stores are not replaced, deleted, or imported
by the recovery path. Core Data may still update internal SQLite bookkeeping
while attempting its initial normal open.

## Transaction boundary

1. Read and validate the complete V3 snapshot without changing the source.
2. Copy `default.store`, `default.store-wal`, and `default.store-shm` into a
   timestamped `CafeineX Store Recovery` directory.
3. Write a JSON manifest containing the source version, original error, and
   record counts.
4. Remove the active V3 store family only after the backup succeeds.
5. Create an empty V4 container and import all supported records with their
   original identifiers and timestamps.
6. Run the idempotent Phase C details backfill.
7. If creation, import, or saving fails, remove the incomplete V4 files and
   restore the original V3 store family from the backup.

The backup is intentionally retained after success. CafeineX never silently
replaces an unsupported store and never treats an unknown layout as recoverable.

## Preserved data

- Caffeine entries, including source and HealthKit UUID.
- Drinks, categories, favorite state, and creation dates.
- Nicotine entries, units, notes, and sources.
- Profile identity, avatar bytes, goal, sync identity, and revision.
- Awareness check-ins.
- Legacy drink metadata used by the V4 details backfill.
- Pending HealthKit outbox items.

## Regression gates

`LegacyV3StoreRecoveryTests` creates a sanitized unknown-V3 SQLite fixture and
opens it through the same `CafeineXStoreFactory` used at app launch. It verifies
record preservation, V4 relationships, archived metadata, avatar bytes, and the
backup manifest.

An optional local gate accepts `CAFEINEX_LEGACY_V3_STORE` and validates the same
path against a private historical store without adding personal data to the
repository.
