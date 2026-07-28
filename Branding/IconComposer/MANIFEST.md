# Neural Cup — Icon Composer foreground

Transparent CafeineX foreground artwork prepared for Apple Icon Composer.

## Recommended import

- File: `NeuralCup-Foreground-1024.png`
- Canvas: 1024 × 1024 pixels
- Format: 8-bit RGBA PNG
- Alpha channel: yes
- SHA-256: `276b01ccf5dc64bff69a9251fb8eb795771b52d11d78afe608d58842e2b6b3a2`

## Archival master

- File: `NeuralCup-Foreground.png`
- Canvas: 1254 × 1254 pixels
- Format: 8-bit RGBA PNG
- Alpha channel: yes
- SHA-256: `647135989e1d2ac3a46759fa06f4e20805667a7d8c1555e688c5aabc15366c09`

## Source and treatment

- Original: `/Users/alexbeltran/Downloads/Generated image 1.png`
- The outer black background and inner black cup fill were removed.
- The neutral brown inner shading was removed so Icon Composer can supply the
  material, depth, shadow, and highlight treatment.
- The orange-red cup, yellow-orange steam, and green pulse retain their original
  geometry, placement, gradients, and 1:1 canvas proportions.
- No app-icon corner mask or replacement background is baked into the export.

## Production route

1. A source-preserving ImageGen chroma extraction was produced for comparison.
2. Visual QA found color contamination at the chroma boundary.
3. The final files therefore use deterministic brand-color isolation from the
   original source, avoiding generated geometry changes and chroma halos.
4. The 1024 export was downsampled from the transparent archival master.

## Icon Composer recommendation

Import `NeuralCup-Foreground-1024.png` as the foreground layer. Add the
background as a separate Icon Composer layer, then apply Liquid Glass material,
specular highlights, shadow, and depth in the composer rather than baking those
effects into this PNG.
