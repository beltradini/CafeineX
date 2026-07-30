# Phase C — SwiftData beverage evolution

## Versioning decision

The Phase C product scope was planned as “SwiftData V3”, but V3 was already a
released, writable schema containing the persistent profile, awareness
check-ins, legacy drink metadata, and HealthKit outbox.

Changing any V3 model after stores have been created would change its checksum
and make those stores unrecognizable. Therefore:

- V1, V2, and V3 are frozen.
- V2 → V3 remains a lightweight, disk-tested migration.
- Phase C is persisted in V4.
- V3 → V4 is lightweight, followed by an idempotent application-level backfill.

## V4 beverage model

`Drink` remains the stable identity and keeps fields that existed in historical
schemas. `DrinkDetails` adds:

- brand or café
- serving amount and unit
- personal notes
- archive flag and archive date
- persisted favorite order
- usage count and latest-use date
- update date
- nullable `Drink` relationship with a nullify delete rule

The existing `drinkID` is retained as a unique external key. It makes the
backfill deterministic and protects against duplicate detail records while the
model relationship enables native SwiftData navigation.

## Backfill contract

After opening V4, `DrinkLibrary.backfillDetailsIfNeeded`:

1. Reads all drinks, current details, and V3 `DrinkMetadata`.
2. Creates only missing `DrinkDetails`.
3. Copies archive state, usage count, latest-use date, and update date.
4. Gives active favorites a stable rank.
5. Links each details record to its `Drink`.
6. Persists one `PhaseCSchemaState` completion record.

Running it again does not duplicate or overwrite existing V4 details.

## User-visible behavior

- My Drinks separates favorites from other active drinks.
- Favorites can be reordered with the native edit interaction.
- Home and Quick Add use the same persisted order.
- Swipe actions favorite, unfavorite, archive, restore, or permanently delete.
- Archive is the default removal behavior and preserves historical exposure.
- The editor supports brand, serving size/unit, and personal notes.

## Test gates

- Original unversioned/V1 store opens in the latest schema without data loss.
- V1 → V2 accepts nicotine entries.
- V2 → V3 retains drinks and accepts profile/check-in models.
- V3 → V4 copies legacy metadata and creates relationships.
- Favorite order survives persistence and reorder operations.
- Archive/restore preserves usage metadata.
- Deleting details leaves its related drink intact; permanent deletion removes
  both records explicitly.
- New brand, serving, and notes attributes persist.
