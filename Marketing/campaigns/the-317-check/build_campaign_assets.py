from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[3]
CAMPAIGN = Path(__file__).resolve().parent
OUT = CAMPAIGN / "exports"
SOURCE = CAMPAIGN / "sources" / "late-afternoon-decision-master.png"
ICON = ROOT / "Website/public/cafeinex-icon.png"
HOME = ROOT / "Website/public/cafeinex-home.png"
HISTORY = ROOT / "Website/public/cafeinex-history.png"
PROFILE = ROOT / "Website/public/cafeinex-profile.png"
FONT = "/System/Library/Fonts/SFNS.ttf"

WHITE = (247, 247, 244, 255)
MUTED = (181, 182, 188, 255)
INK = (5, 7, 11, 255)
PANEL = (27, 29, 34, 238)
ORANGE = (242, 148, 56, 255)
GREEN = (87, 219, 138, 255)
VIOLET = (148, 116, 255, 255)


def ft(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size=size)


def canvas(size: tuple[int, int], top=(12, 14, 19), bottom=(3, 5, 8)) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, INK)
    draw = ImageDraw.Draw(image)
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        draw.line((0, y, w, y), fill=color)
    return image


def add_glow(image: Image.Image, box, color, alpha=120, blur=120):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=(*color[:3], alpha))
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def cover(path: Path, size: tuple[int, int], focus=(0.5, 0.5)) -> Image.Image:
    return ImageOps.fit(Image.open(path).convert("RGBA"), size, Image.Resampling.LANCZOS, centering=focus)


def rounded_paste(base: Image.Image, item: Image.Image, box, radius: int, shadow=22, outline=True):
    x0, y0, x1, y1 = box
    size = (x1 - x0, y1 - y0)
    item = ImageOps.fit(item.convert("RGBA"), size, Image.Resampling.LANCZOS)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *size), radius=radius, fill=255)
    if shadow:
        shade = Image.new("RGBA", base.size, (0, 0, 0, 0))
        ImageDraw.Draw(shade).rounded_rectangle((x0, y0 + 14, x1, y1 + 14), radius=radius, fill=(0, 0, 0, 210))
        base.alpha_composite(shade.filter(ImageFilter.GaussianBlur(shadow)))
    if outline:
        ImageDraw.Draw(base).rounded_rectangle((x0 - 2, y0 - 2, x1 + 2, y1 + 2), radius=radius + 2, fill=(90, 92, 99, 255))
    base.paste(item, (x0, y0), mask)


def brand(base: Image.Image, x: int, y: int, scale=1.0, tagline=False):
    size = round(58 * scale)
    rounded_paste(base, Image.open(ICON), (x, y, x + size, y + size), round(15 * scale), shadow=10, outline=False)
    draw = ImageDraw.Draw(base)
    draw.text((x + size + round(18 * scale), y + round(3 * scale)), "CafeineX", font=ft(round(39 * scale)), fill=WHITE)
    if tagline:
        draw.text((x + size + round(20 * scale), y + round(42 * scale)), "CAFFEINE, IN CONTEXT", font=ft(round(13 * scale)), fill=MUTED)


def wrap(draw: ImageDraw.ImageDraw, text: str, xy, width: int, font, fill=WHITE, spacing=9):
    words, lines, line = text.split(), [], ""
    for word in words:
        test = word if not line else f"{line} {word}"
        if draw.textbbox((0, 0), test, font=font)[2] <= width:
            line = test
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    y = xy[1]
    for line in lines:
        draw.text((xy[0], y), line, font=font, fill=fill)
        y = draw.textbbox((xy[0], y), line, font=font)[3] + spacing
    return y


def gradient_text(base: Image.Image, text: str, xy, font, start=ORANGE, end=GREEN):
    mask = Image.new("L", base.size, 0)
    md = ImageDraw.Draw(mask)
    md.text(xy, text, font=font, fill=255)
    box = md.textbbox(xy, text, font=font)
    grad = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for x in range(box[0], box[2] + 1):
        t = (x - box[0]) / max(1, box[2] - box[0])
        c = tuple(round(start[i] * (1 - t) + end[i] * t) for i in range(3)) + (255,)
        gd.line((x, box[1] - 4, x, box[3] + 4), fill=c)
    base.paste(grad, (0, 0), mask)


def pill(base: Image.Image, text: str, x: int, y: int, accent=ORANGE, size=18):
    draw = ImageDraw.Draw(base)
    font = ft(size)
    width = draw.textbbox((0, 0), text, font=font)[2]
    draw.rounded_rectangle((x, y, x + width + 46, y + 48), radius=24, fill=(16, 18, 22, 226), outline=accent, width=2)
    draw.text((x + 23, y + 13), text, font=font, fill=accent)


def footer(base: Image.Image, url="cafeinex.com", disclaimer=True):
    draw = ImageDraw.Draw(base)
    w, h = base.size
    draw.text((64, h - 74), url, font=ft(23 if w < 1400 else 28), fill=WHITE)
    if disclaimer:
        draw.text((w - 64, h - 69), "Personal awareness tool. Not medical advice.", font=ft(14 if w < 1400 else 17), fill=(126, 128, 135, 255), anchor="ra")


def phone(base: Image.Image, screenshot: Path, box, crop=(0, 0)):
    src = Image.open(screenshot).convert("RGBA")
    if crop != (0, 0):
        src = src.crop((0, crop[0], src.width, src.height - crop[1]))
    rounded_paste(base, src, box, radius=52, shadow=30)


def stat_card(base: Image.Image, box, title, body, accent):
    draw = ImageDraw.Draw(base)
    draw.rounded_rectangle(box, radius=25, fill=PANEL, outline=(*accent[:3], 90), width=2)
    x0, y0, x1, _ = box
    draw.ellipse((x0 + 25, y0 + 27, x0 + 41, y0 + 43), fill=accent)
    draw.text((x0 + 58, y0 + 21), title, font=ft(24), fill=WHITE)
    wrap(draw, body, (x0 + 26, y0 + 64), x1 - x0 - 52, ft(20), MUTED, 5)


def ig_lifestyle_hook():
    size = (1080, 1350)
    base = cover(SOURCE, size, focus=(0.53, 0.47))
    shade = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.rectangle((0, 0, 1080, 650), fill=(3, 5, 8, 174))
    base.alpha_composite(shade.filter(ImageFilter.GaussianBlur(20)))
    brand(base, 64, 62, 1.0, True)
    pill(base, "THE 3:17 CHECK", 64, 166, VIOLET)
    draw = ImageDraw.Draw(base)
    draw.text((64, 252), "Before the next cup,", font=ft(67), fill=WHITE)
    gradient_text(base, "check what’s still active.", (64, 330), ft(64))
    wrap(draw, "Timing context for the choice you’re about to make.", (64, 430), 710, ft(27), MUTED)
    draw.rounded_rectangle((64, 1125, 1016, 1212), radius=44, fill=ORANGE)
    draw.text((102, 1151), "Join the private iPhone pilot", font=ft(29), fill=(9, 8, 7, 255))
    draw.text((966, 1142), "→", font=ft(42), fill=(9, 8, 7, 255), anchor="ra")
    footer(base)
    return base


def ig_product_proof():
    base = canvas((1080, 1350))
    add_glow(base, (-260, -140, 560, 700), ORANGE, 125, 150)
    add_glow(base, (650, 700, 1280, 1390), GREEN, 90, 150)
    brand(base, 64, 62, 1.0, True)
    pill(base, "ONE CALM VIEW", 64, 166, GREEN)
    draw = ImageDraw.Draw(base)
    draw.text((64, 250), "Your next coffee", font=ft(66), fill=WHITE)
    gradient_text(base, "deserves context.", (64, 326), ft(69), ORANGE, VIOLET)
    phone(base, HOME, (86, 470, 548, 1185), crop=(105, 620))
    stat_card(base, (590, 520, 1015, 682), "Active estimate", "A central estimate with uncertainty visible.", ORANGE)
    stat_card(base, (590, 713, 1015, 875), "Personal cutoff", "Put timing beside the sleep schedule you chose.", VIOLET)
    stat_card(base, (590, 906, 1015, 1068), "Optional context", "Apple Health access stays granular and optional.", GREEN)
    footer(base)
    return base


def ig_privacy():
    base = canvas((1080, 1350), (6, 10, 11), (2, 5, 7))
    add_glow(base, (210, 230, 890, 910), GREEN, 115, 145)
    brand(base, 64, 62, 1.0, True)
    pill(base, "PRIVACY BY DESIGN", 64, 166, GREEN)
    draw = ImageDraw.Draw(base)
    draw.text((64, 252), "Useful context.", font=ft(70), fill=WHITE)
    gradient_text(base, "Still yours.", (64, 334), ft(78), ORANGE, GREEN)
    rounded_paste(base, Image.open(ICON), (365, 515, 715, 865), radius=82, shadow=44, outline=False)
    checks = [("On-device first", ORANGE), ("HealthKit optional", GREEN), ("0 ad trackers", VIOLET)]
    y = 925
    for label, accent in checks:
        draw.rounded_rectangle((130, y, 950, y + 78), radius=39, fill=PANEL, outline=(*accent[:3], 92), width=2)
        draw.ellipse((165, y + 25, 193, y + 53), fill=accent)
        draw.text((220, y + 23), label, font=ft(27), fill=WHITE)
        y += 92
    footer(base)
    return base


def ig_pilot_mission():
    base = canvas((1080, 1350))
    add_glow(base, (630, -220, 1320, 500), ORANGE, 135, 150)
    add_glow(base, (-260, 760, 500, 1510), VIOLET, 90, 160)
    brand(base, 64, 62, 1.0, True)
    pill(base, "7-DAY PILOT MISSION", 64, 166, VIOLET)
    draw = ImageDraw.Draw(base)
    draw.text((64, 250), "Don’t just test it.", font=ft(66), fill=WHITE)
    gradient_text(base, "Pressure-test the idea.", (64, 330), ft(64), ORANGE, GREEN)
    steps = [
        ("01", "Log caffeine and cigarette moments."),
        ("02", "Review active range, gaps, pairings, and context."),
        ("03", "Send one pattern that felt useful—or wrong."),
    ]
    y = 500
    for number, copy in steps:
        draw.rounded_rectangle((64, y, 1016, y + 180), radius=30, fill=PANEL, outline=(255, 255, 255, 40), width=2)
        draw.text((98, y + 38), number, font=ft(30), fill=VIOLET)
        wrap(draw, copy, (190, y + 37), 755, ft(33), WHITE, 7)
        y += 207
    draw.rounded_rectangle((64, 1142, 1016, 1229), radius=44, fill=ORANGE)
    draw.text((102, 1168), "Request TestFlight access", font=ft(29), fill=(9, 8, 7, 255))
    draw.text((966, 1158), "→", font=ft(42), fill=(9, 8, 7, 255), anchor="ra")
    footer(base)
    return base


def ig_two_habits():
    base = canvas((1080, 1350))
    add_glow(base, (-240, -120, 560, 690), ORANGE, 115, 150)
    add_glow(base, (610, 650, 1300, 1400), VIOLET, 100, 155)
    brand(base, 64, 62, 1.0, True)
    pill(base, "ONE PRIVATE TIMELINE", 64, 166, VIOLET)
    draw = ImageDraw.Draw(base)
    draw.text((64, 252), "Caffeine and cigarettes.", font=ft(58), fill=WHITE)
    gradient_text(base, "See the timing together.", (64, 324), ft(63), ORANGE, VIOLET)
    phone(base, HISTORY, (84, 458, 548, 1190), crop=(70, 430))
    stat_card(base, (590, 505, 1015, 667), "Search both", "Filter caffeine, nicotine, or cigarettes.", GREEN)
    stat_card(base, (590, 698, 1015, 860), "Notice pairings", "See when coffee and cigarettes happen close together.", ORANGE)
    stat_card(base, (590, 891, 1015, 1053), "Keep it local", "Cigarette profiles, context, goals, and patterns stay on device.", VIOLET)
    footer(base)
    return base


def ig_cigarette_context():
    base = canvas((1080, 1350), (11, 9, 18), (3, 5, 8))
    add_glow(base, (530, -170, 1260, 620), VIOLET, 115, 150)
    add_glow(base, (-280, 760, 470, 1480), ORANGE, 80, 160)
    brand(base, 64, 62, 1.0, True)
    pill(base, "CIGARETTE INTELLIGENCE", 64, 166, VIOLET)
    draw = ImageDraw.Draw(base)
    draw.text((64, 252), "Count the moments.", font=ft(67), fill=WHITE)
    gradient_text(base, "Notice the context.", (64, 332), ft(67), VIOLET, GREEN)
    wrap(draw, "Descriptive patterns without judgment, absorbed-nicotine estimates, or causal claims.", (64, 430), 880, ft(27), MUTED)
    cards = [
        ("Since last", "Make the gap visible.", VIOLET),
        ("With caffeine", "See close-together timing as a pairing—not a cause.", ORANGE),
        ("Sleep window", "Review events near the bedtime you planned.", GREEN),
        ("Context", "With coffee, after a meal, social, stress, routine, or other.", WHITE),
    ]
    y = 610
    for title, body, accent in cards:
        stat_card(base, (64, y, 1016, y + 145), title, body, accent)
        y += 160
    footer(base)
    return base


def carousel_card(index: int):
    makers = [ig_lifestyle_hook, ig_product_proof, ig_privacy, ig_pilot_mission]
    return makers[index - 1]()


def story_decision():
    base = cover(SOURCE, (1080, 1920), focus=(0.52, 0.46))
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rectangle((0, 0, 1080, 960), fill=(3, 5, 8, 170))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(24)))
    brand(base, 70, 156, 1.1, True)
    pill(base, "IT’S 3:17 PM", 70, 282, VIOLET, 21)
    draw = ImageDraw.Draw(base)
    draw.text((70, 390), "Another coffee?", font=ft(82), fill=WHITE)
    gradient_text(base, "Check first.", (70, 488), ft(96))
    wrap(draw, "See what may still be active before the next choice.", (70, 615), 820, ft(34), MUTED, 9)
    draw.rounded_rectangle((70, 1560, 1010, 1660), radius=50, fill=ORANGE)
    draw.text((112, 1589), "JOIN THE PRIVATE PILOT", font=ft(30), fill=(9, 8, 7, 255))
    draw.text((960, 1577), "→", font=ft(46), fill=(9, 8, 7, 255), anchor="ra")
    footer(base)
    return base


def story_poll():
    base = canvas((1080, 1920))
    add_glow(base, (-250, 180, 610, 1030), ORANGE, 120, 170)
    add_glow(base, (620, 790, 1320, 1620), VIOLET, 90, 170)
    brand(base, 70, 156, 1.1, True)
    pill(base, "PILOT RESEARCH", 70, 282, GREEN, 21)
    draw = ImageDraw.Draw(base)
    draw.text((70, 400), "What decides your", font=ft(78), fill=WHITE)
    gradient_text(base, "afternoon coffee?", (70, 494), ft(78), ORANGE, GREEN)
    choices = ["Energy now", "Sleep later", "Habit / taste", "I just guess"]
    y = 720
    for i, label in enumerate(choices):
        accent = [ORANGE, VIOLET, GREEN, WHITE][i]
        draw.rounded_rectangle((70, y, 1010, y + 140), radius=32, fill=PANEL, outline=(*accent[:3], 100), width=2)
        draw.ellipse((108, y + 49, 150, y + 91), outline=accent, width=4)
        draw.text((190, y + 47), label, font=ft(36), fill=WHITE)
        y += 170
    wrap(draw, "Reply with the one thing you wish an app could show before that choice.", (70, 1475), 900, ft(31), MUTED)
    footer(base)
    return base


def x_card(kind: str):
    size = (1600, 900)
    if kind == "hook":
        base = cover(SOURCE, size, focus=(0.53, 0.48))
        veil = Image.new("RGBA", size, (0, 0, 0, 0))
        vd = ImageDraw.Draw(veil)
        vd.rectangle((0, 0, 930, 900), fill=(3, 5, 8, 192))
        base.alpha_composite(veil.filter(ImageFilter.GaussianBlur(20)))
        brand(base, 74, 64, 1.1, True)
        pill(base, "THE 3:17 CHECK", 74, 190, VIOLET, 20)
        draw = ImageDraw.Draw(base)
        draw.text((74, 300), "Before the next cup,", font=ft(78), fill=WHITE)
        gradient_text(base, "check what’s still active.", (74, 392), ft(76))
        wrap(draw, "A private iPhone pilot for timing, exposure, and sleep context.", (74, 518), 825, ft(31), MUTED)
    elif kind == "proof":
        base = canvas(size)
        add_glow(base, (-200, -260, 650, 680), ORANGE, 120, 160)
        add_glow(base, (1100, 360, 1800, 1050), GREEN, 100, 160)
        brand(base, 74, 64, 1.1, True)
        pill(base, "PRODUCT PROOF", 74, 190, GREEN, 20)
        draw = ImageDraw.Draw(base)
        draw.text((74, 300), "Not a magic score.", font=ft(75), fill=WHITE)
        gradient_text(base, "A clearer decision window.", (74, 390), ft(70), ORANGE, VIOLET)
        phone(base, HOME, (1065, 70, 1498, 830), crop=(90, 500))
        stat_card(base, (74, 545, 500, 710), "Active range", "Uncertainty stays visible.", ORANGE)
        stat_card(base, (530, 545, 956, 710), "Personal cutoff", "Timing beside your sleep plan.", VIOLET)
    elif kind == "pilot":
        base = canvas(size, (6, 10, 11), (2, 5, 7))
        add_glow(base, (840, 70, 1600, 850), GREEN, 110, 155)
        brand(base, 74, 64, 1.1, True)
        pill(base, "PRIVATE PILOT", 74, 190, GREEN, 20)
        draw = ImageDraw.Draw(base)
        draw.text((74, 300), "Help test the moment", font=ft(76), fill=WHITE)
        gradient_text(base, "before the next coffee.", (74, 392), ft(76), ORANGE, GREEN)
        wrap(draw, "7 days. Log caffeine and cigarette moments. Send one honest insight.", (74, 520), 850, ft(34), MUTED)
        rounded_paste(base, Image.open(ICON), (1160, 250, 1465, 555), 72, shadow=42, outline=False)
        draw.rounded_rectangle((74, 675, 920, 765), radius=45, fill=ORANGE)
        draw.text((118, 702), "Request TestFlight access →", font=ft(29), fill=(9, 8, 7, 255))
    else:
        base = canvas(size, (11, 9, 18), (3, 5, 8))
        add_glow(base, (1050, 260, 1780, 1040), VIOLET, 100, 165)
        brand(base, 74, 64, 1.1, True)
        pill(base, "ONE PRIVATE TIMELINE", 74, 190, VIOLET, 20)
        draw = ImageDraw.Draw(base)
        draw.text((74, 300), "Caffeine and cigarettes.", font=ft(68), fill=WHITE)
        gradient_text(base, "See the timing together.", (74, 383), ft(69), ORANGE, VIOLET)
        wrap(draw, "Counts, gaps, pairings, context, and sleep-window proximity—descriptive patterns, not causal conclusions.", (74, 505), 880, ft(31), MUTED)
        phone(base, HISTORY, (1110, 75, 1492, 830), crop=(55, 410))
        stat_card(base, (74, 680, 490, 825), "Caffeine", "Active estimate and range.", ORANGE)
        stat_card(base, (520, 680, 936, 825), "Cigarettes", "Timing, context, and gaps.", VIOLET)
    footer(base)
    return base


ASSETS = [
    ("ig-feed-01-decision-hook.png", ig_lifestyle_hook, "Instagram 4:5", "1080x1350"),
    ("ig-feed-02-product-proof.png", ig_product_proof, "Instagram 4:5", "1080x1350"),
    ("ig-feed-03-privacy.png", ig_privacy, "Instagram 4:5", "1080x1350"),
    ("ig-feed-04-pilot-mission.png", ig_pilot_mission, "Instagram 4:5", "1080x1350"),
    ("ig-feed-05-two-habits-one-timeline.png", ig_two_habits, "Instagram 4:5", "1080x1350"),
    ("ig-feed-06-cigarette-context.png", ig_cigarette_context, "Instagram 4:5", "1080x1350"),
    ("ig-story-01-317-check.png", story_decision, "Instagram Story", "1080x1920"),
    ("ig-story-02-research-poll.png", story_poll, "Instagram Story", "1080x1920"),
    ("x-card-01-decision-hook.png", lambda: x_card("hook"), "X card", "1600x900"),
    ("x-card-02-product-proof.png", lambda: x_card("proof"), "X card", "1600x900"),
    ("x-card-03-pilot-mission.png", lambda: x_card("pilot"), "X card", "1600x900"),
    ("x-card-04-two-habits-one-timeline.png", lambda: x_card("combined"), "X card", "1600x900"),
]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    exports = []
    for filename, maker, platform, dimensions in ASSETS:
        output = OUT / filename
        maker().convert("RGB").save(output, quality=95)
        exports.append({
            "file": filename,
            "platform": platform,
            "dimensions": dimensions,
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        })
    manifest = {
        "campaign": "The 3:17 Check",
        "destination": "https://cafeinex.com/",
        "status": "pilot-link-required-before-publishing-conversion-posts",
        "exports": exports,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
