# Phase D — Health Insights

## Product boundary

Health Insights provides context for reflection. It does not diagnose, rate
sleep quality, estimate nicotine absorption, or claim that a stimulant event
caused a sleep outcome.

## Data that provides direct value

CafeineX requests only:

- Dietary caffeine: optional read and write for timeline synchronization.
- Sleep analysis: optional read-only access for the latest completed sleep
  snapshot.

CafeineX does not request heart rate, heart-rate variability, respiratory rate,
wrist temperature, oxygen saturation, workouts, medications, or clinical
records. None are required to explain the timing relationship between the data
the user logs and their latest recorded sleep period.

## Granular authorization

Caffeine Sync and Sleep Context have separate user actions and separate
HealthKit authorization requests. A person can use all local tracking features
without enabling either one.

HealthKit intentionally does not reveal whether read access was denied. When a
sleep query returns nothing, CafeineX says “no readable recent sleep data” and
lists the honest possibilities:

- no completed sleep sample in the 14-day query window
- a limited history window
- read access not granted

The app never labels this state “denied”.

## Snapshot calculation

The latest completed sleep session is derived in memory:

1. Invalid, future, and unfinished intervals are discarded.
2. Samples separated by no more than three hours form a session.
3. The latest session containing an asleep stage is selected.
4. Overlapping asleep intervals are unioned so duplicate sources do not inflate
   total asleep time.
5. In-bed, awake, and detailed-stage coverage remain optional.
6. Missing optional values are displayed as incomplete and never inferred.

Raw sleep samples and the resulting snapshot are not persisted in SwiftData.

## Insight language

Insights may say:

- how much asleep time Apple Health recorded
- how many logged caffeine events fall inside the selected pre-sleep window
- how many logged nicotine events fall inside that same window
- that optional stage or in-bed details are unavailable
- that the latest readable snapshot is stale

Every result carries a limitation stating that timing overlap does not
establish cause. Caffeine and nicotine amounts remain separate because their
units and products are not directly comparable.

## Privacy

- Processing occurs on device.
- Sleep samples are not copied into the CafeineX database.
- Nicotine records are not written to HealthKit.
- No HealthKit data is requested for advertising, marketing, or data mining.
- Permission management remains in Apple Health and system Settings.

## Test gates

- Overlapping and duplicate sleep samples do not double-count duration.
- Awake-only and future samples cannot create a snapshot.
- The newest completed sleep session wins.
- Missing optional sleep fields create an explicit incomplete insight.
- Caffeine and nicotine timing remain separate.
- Insight copy explicitly rejects causal interpretation.
