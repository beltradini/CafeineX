# CafeineX Phase 0–1 Foundation

## Delivered scope

- The app launches into `TodayView` instead of the SwiftData template.
- `CaffeineEntry` and `Drink` are the active SwiftData schema.
- Manual and custom caffeine entries persist locally.
- CafeineX writes authorized entries to Apple Health with an app entry identifier.
- A 30-day Apple Health import links CafeineX-owned samples and imports external samples once.
- Caffeine calculations operate on the persistence-independent `CaffeineDose` value.
- Active caffeine is shown as a central estimate and a 3–7 hour half-life range.
- Bedtime guidance uses the slower-metabolism bound and is described as guidance, not diagnosis.
- Bedtime and the caffeine cutoff interval are user-configurable and persist across launches.
- Personal response sensitivity adjusts guidance thresholds without changing exposure estimates or the 400 mg reference.

## Phase 2 boundary

Nicotine and tobacco concepts are intentionally absent from the current persistence schema and UI. Phase 2 can add an exposure domain without changing `CaffeineEngine`:

1. Add a separate `ExposureEvent` domain model with substance, route, amount, timestamp, source, and confidence.
2. Keep caffeine and nicotine quantities on separate axes; do not combine their milligrams into one score.
3. Build interaction windows over `CaffeineDose` and nicotine events in a new engine.
4. Add any nicotine UI as a separate feature and keep language neutral or reduction-oriented.
5. Do not write nicotine events to HealthKit unless Apple introduces a semantically correct data type.

## Deliberately deferred

- watchOS target, complications, widgets, and App Intents.
- Heart rate, HRV, sleep, and contextual correlation.
- Deleting CafeineX-owned HealthKit samples from the local timeline.
- Background HealthKit delivery.
