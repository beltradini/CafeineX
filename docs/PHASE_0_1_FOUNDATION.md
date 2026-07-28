# CafeineX Phase 0–1 Foundation

## Delivered scope

- The app launches into `TodayView` instead of the SwiftData template.
- `CaffeineEntry` and `Drink` formed the V1 SwiftData baseline.
- Manual and custom caffeine entries persist locally.
- CafeineX writes authorized entries to Apple Health with an app entry identifier.
- A 30-day Apple Health import links CafeineX-owned samples and imports external samples once.
- Caffeine calculations operate on the persistence-independent `CaffeineDose` value.
- Active caffeine is shown as a central estimate and a 3–7 hour half-life range.
- Bedtime guidance uses the slower-metabolism bound and is described as guidance, not diagnosis.
- Bedtime and the caffeine cutoff interval are user-configurable and persist across launches.
- Personal response sensitivity adjusts guidance thresholds without changing exposure estimates or the 400 mg reference.

## Phase 2 boundary — completed

The original boundary kept nicotine out until the caffeine foundation was
stable. Phase 2 is now implemented in `docs/PHASE_2_NICOTINE.md` with the same
constraints:

1. `NicotineEntry` remains a separate persisted event model.
2. Caffeine and nicotine quantities stay on separate axes.
3. `DailyExposureContext` combines timing windows, not amounts.
4. Nicotine UI uses neutral, observational language.
5. Nicotine events are not written to HealthKit without a semantically correct data type.

## Deliberately deferred

- watchOS target, complications, widgets, and App Intents.
- Heart rate, HRV, sleep, and contextual correlation.
- Deleting CafeineX-owned HealthKit samples from the local timeline.
- Background HealthKit delivery.
