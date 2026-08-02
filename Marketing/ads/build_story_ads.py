from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


W, H = 1080, 1920
ROOT = Path("/Users/alexbeltran/Desktop/CafeineX")
OUT = ROOT / "Marketing/ads/exports"
ICON = Path("/Users/alexbeltran/Desktop/CafeineX-iOS-Default-1024x1024@1x.png")
HOME = Path("/Users/alexbeltran/Desktop/Screenshot iPhone Air 07-31-2026 at 12.54.24 PM.png")
HISTORY = Path("/Users/alexbeltran/Desktop/Screenshot iPhone Air 07-31-2026 at 11.05.29 AM.png")
LANDING = Path("/Users/alexbeltran/Desktop/CafineXLanding.png")
TIMING_BG = ROOT / "Marketing/ads/backgrounds/cx-ad-02-timing-bg.png"
PILOT_BG = ROOT / "Marketing/ads/backgrounds/cx-ad-04-pilot-bg.png"
FONT = "/System/Library/Fonts/SFNS.ttf"

WHITE = (247, 247, 249, 255)
MUTED = (176, 177, 184, 255)
ORANGE = (255, 148, 35, 255)
GREEN = (82, 218, 137, 255)
VIOLET = (151, 112, 255, 255)
INK = (5, 7, 11, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size=size)


def cover(path: Path, size=(W, H), focus=(0.5, 0.5)) -> Image.Image:
    im = Image.open(path).convert("RGB")
    return ImageOps.fit(im, size, method=Image.Resampling.LANCZOS, centering=focus).convert("RGBA")


def vertical_base(top=(4, 6, 10), bottom=(0, 2, 5)) -> Image.Image:
    im = Image.new("RGBA", (W, H), INK)
    px = im.load()
    for y in range(H):
        t = y / (H - 1)
        c = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(W):
            px[x, y] = c
    return im


def glow(base: Image.Image, box, color, blur=120, alpha=180):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse(box, fill=(*color[:3], alpha))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def paste_rounded(base, im, xy, size, radius, shadow=28, border=0, border_color=(77, 79, 85, 255)):
    content = ImageOps.fit(im.convert("RGBA"), size, method=Image.Resampling.LANCZOS)
    mask = rounded_mask(size, radius)
    if shadow:
        sh = Image.new("RGBA", base.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        x, y = xy
        sd.rounded_rectangle((x, y + 12, x + size[0], y + size[1] + 12), radius=radius, fill=(0, 0, 0, 190))
        base.alpha_composite(sh.filter(ImageFilter.GaussianBlur(shadow)))
    if border:
        x, y = xy
        d = ImageDraw.Draw(base)
        d.rounded_rectangle((x - border, y - border, x + size[0] + border, y + size[1] + border), radius=radius + border, fill=border_color)
    base.paste(content, xy, mask)


def phone(base, screenshot_path: Path, xy, width, crop_top=0, crop_bottom=0, radius=72):
    src = Image.open(screenshot_path).convert("RGBA")
    if crop_top or crop_bottom:
        src = src.crop((0, crop_top, src.width, src.height - crop_bottom))
    height = round(width * src.height / src.width)
    outer = 18
    x, y = xy
    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    sd.rounded_rectangle((x - outer, y - outer + 18, x + width + outer, y + height + outer + 18), radius=radius + outer, fill=(0, 0, 0, 220))
    base.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(36)))
    ImageDraw.Draw(base).rounded_rectangle((x - outer, y - outer, x + width + outer, y + height + outer), radius=radius + outer, fill=(28, 30, 34, 255), outline=(114, 116, 122, 180), width=3)
    paste_rounded(base, src, (x, y), (width, height), radius=radius, shadow=0)


def brand(base, x=70, y=150, icon_size=84):
    icon = Image.open(ICON).convert("RGBA")
    paste_rounded(base, icon, (x, y), (icon_size, icon_size), radius=22, shadow=18)
    d = ImageDraw.Draw(base)
    d.text((x + icon_size + 24, y + 6), "CafeineX", font=font(56), fill=WHITE)
    d.text((x + icon_size + 26, y + 61), "CAFFEINE, IN CONTEXT", font=font(20), fill=MUTED)


def pill(base, text, x, y, color=VIOLET):
    f = font(22)
    d = ImageDraw.Draw(base)
    box = d.textbbox((0, 0), text, font=f)
    tw = box[2] - box[0]
    d.rounded_rectangle((x, y, x + tw + 54, y + 54), radius=27, fill=(18, 19, 23, 255), outline=color, width=2)
    d.text((x + 27, y + 14), text, font=f, fill=color)


def wrapped(base, text, xy, max_width, fnt, fill=WHITE, spacing=10):
    d = ImageDraw.Draw(base)
    words = text.split()
    lines = []
    line = ""
    for word in words:
        test = word if not line else f"{line} {word}"
        if d.textbbox((0, 0), test, font=fnt)[2] <= max_width:
            line = test
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    y = xy[1]
    for line in lines:
        d.text((xy[0], y), line, font=fnt, fill=fill)
        bbox = d.textbbox((xy[0], y), line, font=fnt)
        y = bbox[3] + spacing
    return y


def gradient_text(base, text, xy, fnt, start=ORANGE, end=GREEN):
    d = ImageDraw.Draw(base)
    bbox = d.textbbox(xy, text, font=fnt)
    mask = Image.new("L", base.size, 0)
    ImageDraw.Draw(mask).text(xy, text, font=fnt, fill=255)
    grad = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gp = grad.load()
    x0, _, x1, _ = bbox
    for x in range(max(0, x0), min(W, x1 + 1)):
        t = (x - x0) / max(1, x1 - x0)
        c = tuple(round(start[i] * (1 - t) + end[i] * t) for i in range(3)) + (255,)
        for y in range(max(0, bbox[1] - 10), min(H, bbox[3] + 10)):
            gp[x, y] = c
    base.paste(grad, (0, 0), mask)


def cta(base, label, y=1510):
    d = ImageDraw.Draw(base)
    x, w, h = 70, 940, 92
    d.rounded_rectangle((x, y, x + w, y + h), radius=46, fill=ORANGE)
    d.text((x + 42, y + 26), label, font=font(30), fill=(9, 8, 7, 255))
    arrow = "→"
    ab = d.textbbox((0, 0), arrow, font=font(38))
    d.text((x + w - 46 - (ab[2] - ab[0]), y + 20), arrow, font=font(38), fill=(9, 8, 7, 255))
    d.text((70, y + 122), "cafeinex.com", font=font(27), fill=WHITE)
    d.text((1010, y + 122), "Personal awareness tool. Not medical advice.", font=font(16), fill=(135, 136, 143, 255), anchor="ra")


def glass_card(base, box, title, body, accent=ORANGE):
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, radius=28, fill=(32, 34, 39, 205), outline=(255, 255, 255, 42), width=2)
    d.ellipse((x0 + 26, y0 + 27, x0 + 42, y0 + 43), fill=accent)
    d.text((x0 + 58, y0 + 22), title, font=font(24), fill=WHITE)
    wrapped(base, body, (x0 + 28, y0 + 66), x1 - x0 - 56, font(21), MUTED, 6)


def story_01():
    ref = cover(LANDING)
    ref = ref.filter(ImageFilter.GaussianBlur(34))
    base = Image.blend(ref, vertical_base(), 0.82)
    glow(base, (-260, 110, 500, 840), ORANGE, 150, 155)
    glow(base, (680, 850, 1320, 1660), GREEN, 170, 110)
    brand(base)
    pill(base, "PRIVATE PILOT FOR IPHONE", 70, 286)
    d = ImageDraw.Draw(base)
    d.text((70, 376), "See what’s active.", font=font(80), fill=WHITE)
    gradient_text(base, "Protect what comes next.", (70, 468), font(69))
    wrapped(base, "Timing, exposure, and sleep context—at a glance.", (70, 575), 720, font(31), MUTED, 8)
    phone(base, HOME, (490, 700), 520, crop_bottom=180, radius=64)
    glass_card(base, (70, 790, 430, 966), "Right now", "See your active estimate and personal cutoff.", GREEN)
    glass_card(base, (70, 995, 430, 1171), "Later tonight", "Keep your planned sleep window in view.", VIOLET)
    cta(base, "Join the private pilot")
    return base


def story_02():
    base = cover(TIMING_BG, focus=(0.52, 0.5))
    veil = Image.new("RGBA", base.size, (0, 0, 0, 72))
    base.alpha_composite(veil)
    brand(base)
    pill(base, "A MORE HONEST STIMULANT TRACKER", 70, 286, ORANGE)
    d = ImageDraw.Draw(base)
    d.text((70, 380), "Not just how much.", font=font(78), fill=WHITE)
    gradient_text(base, "When matters, too.", (70, 470), font(80), ORANGE, VIOLET)
    wrapped(base, "See active-caffeine estimates, likely ranges, and your personal cutoff.", (70, 584), 850, font(30), MUTED, 8)
    phone(base, HOME, (70, 745), 455, crop_top=100, crop_bottom=420, radius=58)
    glass_card(base, (570, 795, 1008, 978), "Active range", "A central estimate with uncertainty kept visible.", ORANGE)
    glass_card(base, (570, 1005, 1008, 1188), "Personal cutoff", "Put the next choice beside the sleep schedule you chose.", VIOLET)
    glass_card(base, (570, 1215, 1008, 1398), "One calm view", "Context for the decision window—without false certainty.", GREEN)
    cta(base, "Explore CafeineX")
    return base


def story_03():
    base = vertical_base((7, 8, 13), (2, 5, 8))
    glow(base, (640, -180, 1320, 560), ORANGE, 150, 120)
    glow(base, (-240, 1060, 500, 1850), GREEN, 170, 110)
    brand(base)
    pill(base, "SEARCHABLE HISTORY", 70, 286, GREEN)
    d = ImageDraw.Draw(base)
    d.text((70, 380), "Turn small moments", font=font(76), fill=WHITE)
    gradient_text(base, "into a clearer pattern.", (70, 470), font(72), GREEN, VIOLET)
    wrapped(base, "Search your history. Filter by date, source, and exposure type.", (70, 580), 820, font(30), MUTED, 8)
    phone(base, HISTORY, (445, 710), 565, crop_bottom=120, radius=66)
    glass_card(base, (70, 760, 390, 918), "Search", "Find every logged moment.", GREEN)
    glass_card(base, (70, 950, 390, 1108), "Filter", "Date, source, and type.", ORANGE)
    glass_card(base, (70, 1140, 390, 1298), "Reflect", "Notice patterns without pressure.", VIOLET)
    cta(base, "See the whole pattern")
    return base


def story_04():
    base = cover(PILOT_BG, focus=(0.54, 0.45))
    base.alpha_composite(Image.new("RGBA", base.size, (0, 0, 0, 52)))
    brand(base)
    pill(base, "PRIVACY BY DESIGN", 70, 286, GREEN)
    d = ImageDraw.Draw(base)
    d.text((70, 380), "Your health context", font=font(76), fill=WHITE)
    gradient_text(base, "stays yours.", (70, 470), font(86), ORANGE, GREEN)
    wrapped(base, "Permission, restraint, and clarity—built into the experience.", (70, 584), 820, font(30), MUTED, 8)
    icon = Image.open(ICON).convert("RGBA")
    glow(base, (290, 650, 790, 1150), GREEN, 110, 105)
    paste_rounded(base, icon, (370, 700), (340, 340), radius=82, shadow=42)
    checks = [
        ("On-device first", ORANGE),
        ("HealthKit optional", GREEN),
        ("0 ad trackers", VIOLET),
    ]
    y = 1115
    for text, accent in checks:
        d.rounded_rectangle((140, y, 940, y + 82), radius=41, fill=(24, 27, 31, 218), outline=(*accent[:3], 92), width=2)
        d.ellipse((170, y + 25, 202, y + 57), fill=accent)
        d.text((225, y + 24), text, font=font(29), fill=WHITE)
        y += 102
    cta(base, "Help shape the launch")
    return base


STORIES = [
    ("cafeinex-story-01-active-context.png", story_01, "Active context / hero"),
    ("cafeinex-story-02-timing-matters.png", story_02, "Timing and uncertainty"),
    ("cafeinex-story-03-clearer-patterns.png", story_03, "Searchable history"),
    ("cafeinex-story-04-privacy-by-design.png", story_04, "Privacy-first pilot"),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    entries = []
    for filename, builder, route in STORIES:
        image = builder().convert("RGB")
        path = OUT / filename
        image.save(path, format="PNG", optimize=True)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        entries.append({
            "file": filename,
            "route": route,
            "width": W,
            "height": H,
            "safe_zone": {"top": 150, "bottom": 220, "left": 70, "right": 70},
            "sha256": digest,
        })
    manifest = {
        "campaign": "CafeineX Private Pilot — Instagram Stories",
        "language": "English",
        "platform": "Instagram Stories",
        "dimensions": "1080x1920",
        "destination": "https://cafeinex.com/",
        "source_assets": [str(ICON), str(HOME), str(HISTORY), str(LANDING), str(TIMING_BG), str(PILOT_BG)],
        "exports": entries,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
