# CafeineX Phase 2 — Nicotine and Daily Exposure

## Delivered scope

- `CafeineXSchemaV2` adds `NicotineEntry` through a lightweight SwiftData
  migration from V1.
- V1 caffeine and drink records are preserved by a disk-backed migration test.
- Nicotine products include cigarettes, cigars, vapes, pouches, gum, lozenges,
  patches, and a neutral custom category.
- Quantities are recorded as milligrams, uses, or puffs. These units remain
  separate in the dashboard and history.
- `NicotineEngine` evaluates event timing through configurable observation
  windows and a four-hour bedtime guidance window.
- `DailyExposureContext` combines caffeine and nicotine timing without adding
  their amounts or presenting a medical interaction score.
- The dashboard supports manual nicotine logging and shows timing overlap,
  active observation windows, and sleep-oriented guidance.
- History provides one chronological timeline with substance/source filters
  and separate caffeine and nicotine totals.

## Domain boundaries

- Nicotine is not written to HealthKit because CafeineX has no semantically
  correct HealthKit quantity type for these product events.
- Product labels are user-entered exposure records, not measurements of
  absorbed nicotine.
- Observation windows provide consistent timing context; they are not
  pharmacokinetic blood-level predictions.
- The four-hour sleep window is guidance based on event timing and the user's
  configured bedtime. It is not a diagnosis or cessation prescription.
- Milligrams, uses, and puffs are never converted into one combined total.

## Verification

- V1 → V2 migration preserves existing caffeine records and permits inserting
  and fetching `NicotineEntry`.
- Engine tests cover unit separation, future events, longer patch windows,
  bedtime guidance, and cross-midnight patch behavior.
- Daily context tests cover overlapping and separated windows, prior-day
  exclusion, and sleep-priority guidance.
