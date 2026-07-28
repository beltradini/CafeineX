# CafeineX Brand Direction

## Selected icon: Neural Cup

`AppIconConcepts/cafeinex-neural-cup.png` is the selected direction.

It combines three ideas in one compact silhouette:

- a cup for immediate caffeine recognition;
- a central pulse for active-caffeine intelligence;
- rising steam for energy and focus;
- an amber-to-green contrast from intake to personal-response guidance.

The final master simplifies the concept into broad, clean shapes and thickens the
steam and pulse so the mark remains recognizable at small sizes. Default, Dark,
and Tinted masters are stored in `AppIconFinal`.

## Concept ranking

1. **Neural Cup** — selected for its immediate caffeine and intelligence signal.
2. **Energy Bean** — distinctive alternate direction retained for reference.
3. **Liquid Orbit** — dynamic, although it can read as science or an atom.
4. **CX Pulse** — direct monogram, but less ownable without the product name.

## Core palette

| Token | Hex | Role |
| --- | --- | --- |
| Caffeine Amber | `#F29438` | Energy, intake, warmth |
| Health Emerald | `#57DB8A` | Guidance, balance, positive state |
| Alert Coral | `#FF5E47` | Elevated load and sleep warnings |
| Midnight Top | `#0D0F14` | Premium dark foundation |
| Midnight Bottom | `#030508` | Depth and high contrast |

These values mirror `CXTheme` so the icon and product UI remain visually related.

## Brand principles

- Intelligent energy, not café nostalgia.
- Guidance and personal response, not diagnosis.
- High contrast and bold geometry that survive small sizes.
- Warm amber balanced by health green; coral is reserved for warnings.
- No typography inside the app icon.
- No baked rounded corners; Apple applies the platform mask.

## Production gate

Before placing a final master in `Assets.xcassets/AppIcon.appiconset`:

1. Produce a simplified final master at 1024 × 1024.
2. Inspect it at 16, 29, 40, 60, and 64 px.
3. Check the iOS icon mask and dark/tinted appearances in Xcode.
4. Confirm that no critical detail falls outside the central safe area.
