# CafeineX App Icon — Neural Cup

Final flattened app-icon masters for the CafeineX asset catalog.

## Source direction

- Selected concept: `Branding/AppIconConcepts/cafeinex-neural-cup.png`
- Core marks: circular coffee cup, rising steam, and a green caffeine pulse
- Refinement: simplified surface texture, broader shapes, reduced bloom, and stronger small-size legibility
- Generation route: OpenAI ImageGen, followed by deterministic appearance grading where needed to preserve identical geometry

## Deliverables

| Appearance | File | SHA-256 |
| --- | --- | --- |
| Default | `CafeineX-AppIcon-Default.png` | `574a517caae43b63467f2df5737092452187431bc8df6cfd279b253094d95c23` |
| Dark | `CafeineX-AppIcon-Dark.png` | `c96828409d854b9ef651d9186275aa3f89d67ffb4dc05b362a387ba4b8197446` |
| Tinted | `CafeineX-AppIcon-Tinted.png` | `1258e011ecb31a5c365c10e0f56d9fb215d8043564cffd9431ebdab71dfd24ed` |

All three files are:

- PNG
- 1024 × 1024 pixels
- Without an alpha channel
- Free of text and baked-in rounded-corner masks

The Tinted appearance is true grayscale so iOS can apply the user's selected tint.

## Installed asset-catalog paths

- `CafeineX/Assets.xcassets/AppIcon.appiconset/CafeineX-AppIcon-Default.png`
- `CafeineX/Assets.xcassets/AppIcon.appiconset/CafeineX-AppIcon-Dark.png`
- `CafeineX/Assets.xcassets/AppIcon.appiconset/CafeineX-AppIcon-Tinted.png`
- Appearance mapping: `CafeineX/Assets.xcassets/AppIcon.appiconset/Contents.json`

## Validation

- Automated dimensions, alpha-channel, and catalog checks: `Scripts/validate-app-icons`
- Visual downsampling checks: 16, 29, 40, 60, and 64 points
- Xcode asset compilation: passed
- CafeineX build: `BUILD SUCCEEDED`

## Liquid Glass scope

This delivery uses the flattened Xcode asset-catalog workflow with Default, Dark,
and Tinted appearances. iOS supplies the system mask and appearance treatment.
A future layered Icon Composer source can add independent material, refraction,
shadow, and specular control for the background, cup, pulse, and steam layers.
