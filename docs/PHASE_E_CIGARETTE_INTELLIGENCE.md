# Phase E — Cigarette Intelligence

## Product contract

CafeineX treats cigarette events as a specialized part of the nicotine timeline. It records what the person entered, when it happened, and an optional context. It does not estimate absorbed nicotine, define a safe amount, diagnose dependence, or claim that a cigarette caused a sleep outcome.

## Delivered surface

- SwiftData V5 adds reusable cigarette profiles, per-event context, and responsible preferences without changing historical V1–V4 model shapes.
- Home shows today’s cigarette count, time since the latest event, caffeine pairings, sleep-window proximity, and one-tap logging with Undo.
- Quick Add supports saved cigarette profiles and optional context while retaining other nicotine products.
- My Cigarettes supports add, edit, favorite, archive, restore, label information, and a responsible focus.
- History and Search can isolate cigarette events; details and editing preserve profile/context metadata.
- Cigarette data stays local. Apple Health remains limited to dietary caffeine and read-only sleep analysis.

## Insight rules

- A caffeine pairing means both events occurred within the configured time window. It is a timing relationship only.
- Sleep-window proximity compares an event with the person’s planned bedtime, including bedtime after midnight.
- Weekly differences describe recorded totals and are not framed as success or failure.
- Missing context remains missing; CafeineX does not infer it.

## Extension boundary

Widgets, Live Activities, App Intents, Siri, and Apple Watch must consume the same V5 models and `CigaretteEngine`. They must not create a second persistence or calculation path. Any future shortcut must accept explicit confirmation before writing and return the created local event identifier for deduplication.
