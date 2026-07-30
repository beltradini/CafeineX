# Phase B: Personal Profile and Responsible Progress

Phase B makes Profile a useful reflection surface rather than a settings index.

## Delivered

- One persistent SwiftData profile with stable local and future-sync identifiers.
- Editable preferred name, locally stored normalized photo, and personal goal.
- Goal-aware weekly progress for sleep protection, pattern understanding, late-caffeine reduction, or mindful tracking.
- Current-week caffeine, tracked days, after-cutoff events, nicotine event count, and a transparent previous-week comparison.
- Current and best awareness and sleep-protection streaks.
- Responsible streak rules: today may remain pending, missing days never count as success, and a gap pauses the current streak without erasing the best.

## Trust boundaries

- Progress describes the quality and completeness of the record; it does not prescribe a dose or reward stimulant use.
- A sleep-protection day must be completed, reviewed, and free of caffeine at or after the user's cutoff.
- Weekly summaries are derived from local events and the current sleep schedule. They are not persisted or presented as medical conclusions.
- Name and photo remain local. A future Apple ID flow must store authentication material in Keychain and explicitly reconcile remote revisions.

## Verification

- `UserProfileStoreTests` verifies singleton creation, normalized updates, stable identity, photo data, goal, and sync revision.
- `WeeklySummaryEngineTests` verifies calendar boundaries, future-event exclusion, cutoff behavior, previous-week comparison, and first-day progress.
- `StreakEngineTests` verifies pending today, missing-data behavior, late-caffeine rejection, and preservation of historical best streaks.
