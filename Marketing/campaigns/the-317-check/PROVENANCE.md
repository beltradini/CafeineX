# Asset provenance and export notes

## Campaign

- Name: The 3:17 Check
- Destination: https://cafeinex.com/
- Language: English
- Created: August 2, 2026

## Verified product sources

- Current CafeineX website source in `Website/app/page.tsx`.
- Current privacy copy in `Website/app/privacy/page.tsx`.
- Current UI screenshots in `Website/public/cafeinex-home.png`, `cafeinex-history.png`, and `cafeinex-profile.png`.
- Current app icon in `Website/public/cafeinex-icon.png`.
- Brand palette and positioning in `Branding/BRAND_DIRECTION.md`.

## Generated visual source

`sources/late-afternoon-decision-master.png` was created with the built-in Codex ImageGen tool as a text-free lifestyle background. It contains no product UI, logo, generated claim, or readable copy. The final prompt requested a believable late-afternoon coffee decision moment, with near-black, amber, and subtle emerald treatment; no medical imagery, nicotine products, futuristic overlays, or watermark.

### Final ImageGen prompt

```text
Use case: ads-marketing
Asset type: master lifestyle background for CafeineX pilot social campaign, adaptable to Instagram 4:5 and X 16:9
Primary request: Create a premium, believable late-afternoon decision moment just before someone reaches for another coffee.
Scene/backdrop: contemporary home-office desk at 3:17 PM, dark stone desk, a warm ceramic coffee cup placed near the hand of an adult user, an unbranded modern smartphone lying face-up with its screen dark and unreadable, subtle notebook and soft window light. The moment should feel thoughtful, not anxious.
Subject: only the person's natural hand and forearm entering the frame; no face; coffee and phone are the visual anchors.
Style/medium: photorealistic editorial product-lifestyle photography, sophisticated Apple-adjacent restraint without copying any specific advertisement.
Composition/framing: 4:5 portrait-friendly master with safe central crop and extra negative space in the upper-left for deterministic headline overlay; coffee in lower-left third, phone in lower-right third; clean depth and strong hierarchy.
Lighting/mood: late afternoon blue-shadow ambient light with controlled amber rim light and a faint emerald reflection, calm, intelligent, intimate.
Color palette: near-black, charcoal, caffeine amber #F29438, very subtle health emerald #57DB8A.
Materials/textures: matte ceramic, dark stone, natural skin texture, soft glass reflection.
Constraints: no readable UI, no generated text, no logos, no app icon, no medical imagery, no cigarettes or nicotine products, no exaggerated neon, no futuristic holograms, no watermark.
Avoid: generic coffee-shop cliché, clutter, stock-photo smiles, hospital or biohacking aesthetic, alarmist tone.
```

## Deterministic composition

All CafeineX names, headlines, CTA labels, UI screenshots, feature claims, URLs, disclaimer text, crops, and output dimensions are composed by `build_campaign_assets.py`. Image generation was not used for readable copy or product UI.

## Output dimensions

- Instagram feed: 1080 × 1350 px.
- Instagram Stories: 1080 × 1920 px; key copy kept out of the top and bottom UI zones.
- X cards: 1600 × 900 px.

## Claim boundary

The assets use current, supportable product language: active-caffeine estimates, likely ranges, personal cutoff, optional Apple Health context, cigarette counts, time since last, caffeine pairings, selected context, sleep-window proximity, on-device-first design, no ad trackers, and a private iPhone pilot. Cigarette content is explicitly descriptive: no absorbed-nicotine estimate, safe-use amount, diagnosis, causal conclusion, or cessation promise. Every claim-led asset includes `Personal awareness tool. Not medical advice.`

Conversion assets must not be published until the site exposes a working TestFlight or reviewed opt-in path.
