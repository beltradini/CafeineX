from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


W, H = 1080, 1920
CAMPAIGN = Path(__file__).resolve().parent
BACKGROUNDS = CAMPAIGN / "backgrounds"
STORIES = CAMPAIGN / "stories"
FONT = "/System/Library/Fonts/SFNS.ttf"

INK = (3, 5, 9, 255)
WHITE = (247, 247, 244, 255)
MUTED = (174, 176, 184, 255)
ORANGE = (242, 148, 56, 255)
GREEN = (87, 219, 138, 255)
VIOLET = (148, 116, 255, 255)


def ft(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size=size)


def base_gradient(top=(8, 10, 16), bottom=(2, 4, 7)) -> Image.Image:
    image = Image.new("RGBA", (W, H), INK)
    draw = ImageDraw.Draw(image)
    for y in range(H):
        t = y / (H - 1)
        eased = t * t * (3 - 2 * t)
        color = tuple(round(top[i] * (1 - eased) + bottom[i] * eased) for i in range(3)) + (255,)
        draw.line((0, y, W, y), fill=color)
    return image


def field(image: Image.Image, box, color, alpha=150, blur=170):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=(*color[:3], alpha))
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def soft_grain(image: Image.Image, opacity=8):
    noise = Image.effect_noise((W, H), 18).convert("L")
    texture = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    texture.putalpha(noise.point(lambda p: round(p * opacity / 255)))
    image.alpha_composite(texture)


def decision_window() -> Image.Image:
    image = base_gradient((11, 9, 8), (2, 5, 7))
    field(image, (-370, 120, 670, 1130), ORANGE, 165, 210)
    field(image, (500, 780, 1470, 1900), GREEN, 118, 225)
    soft_grain(image)
    return image


def dual_timeline() -> Image.Image:
    image = base_gradient((7, 7, 13), (3, 4, 8))
    field(image, (-420, 1030, 630, 2140), ORANGE, 130, 235)
    field(image, (470, -250, 1440, 930), VIOLET, 145, 215)
    soft_grain(image)
    return image


def honest_range() -> Image.Image:
    image = base_gradient((7, 8, 14), (2, 4, 7))
    field(image, (-460, 470, 550, 1470), ORANGE, 135, 210)
    field(image, (505, 420, 1530, 1510), VIOLET, 125, 220)
    field(image, (180, 1250, 920, 2070), GREEN, 64, 205)
    soft_grain(image)
    return image


def cigarette_context() -> Image.Image:
    image = base_gradient((8, 7, 14), (3, 4, 8))
    field(image, (300, -330, 1370, 860), VIOLET, 150, 230)
    field(image, (-420, 1080, 610, 2130), ORANGE, 110, 230)
    field(image, (530, 1160, 1450, 2180), GREEN, 70, 240)
    soft_grain(image)
    return image


def private_signal() -> Image.Image:
    image = base_gradient((5, 11, 11), (2, 5, 8))
    field(image, (140, 350, 1050, 1370), GREEN, 125, 250)
    field(image, (-480, 1270, 490, 2190), VIOLET, 54, 230)
    soft_grain(image)
    return image


def pilot_signal() -> Image.Image:
    image = base_gradient((10, 8, 12), (2, 4, 7))
    field(image, (-420, -280, 630, 820), ORANGE, 135, 225)
    field(image, (560, 430, 1510, 1480), GREEN, 100, 230)
    field(image, (-310, 1150, 720, 2190), VIOLET, 115, 240)
    soft_grain(image)
    return image


BACKGROUND_BUILDERS = [
    ("cx-gradient-01-decision-window.png", decision_window, "Amber to emerald decision window"),
    ("cx-gradient-02-dual-timeline.png", dual_timeline, "Violet and amber dual timeline"),
    ("cx-gradient-03-honest-range.png", honest_range, "Amber to violet range with emerald resolution"),
    ("cx-gradient-04-cigarette-context.png", cigarette_context, "Violet context field with restrained amber and green"),
    ("cx-gradient-05-private-signal.png", private_signal, "Emerald privacy signal"),
    ("cx-gradient-06-pilot-signal.png", pilot_signal, "Three-signal pilot gradient"),
]


def gradient_text(image: Image.Image, text: str, xy, font, start, end):
    mask = Image.new("L", image.size, 0)
    md = ImageDraw.Draw(mask)
    md.text(xy, text, font=font, fill=255)
    box = md.textbbox(xy, text, font=font)
    gradient = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(gradient)
    for x in range(box[0], box[2] + 1):
        t = (x - box[0]) / max(1, box[2] - box[0])
        color = tuple(round(start[i] * (1 - t) + end[i] * t) for i in range(3)) + (255,)
        gd.line((x, box[1] - 4, x, box[3] + 4), fill=color)
    image.paste(gradient, (0, 0), mask)


def brand(draw: ImageDraw.ImageDraw, route: str):
    draw.text((72, 166), "CafeineX", font=ft(44), fill=WHITE)
    draw.text((72, 222), route.upper(), font=ft(17), fill=MUTED)


def footer(draw: ImageDraw.ImageDraw, cta="CAFEINEX.COM"):
    draw.text((72, 1625), cta, font=ft(23), fill=WHITE)
    draw.text((72, 1678), "PERSONAL AWARENESS TOOL · NOT MEDICAL ADVICE", font=ft(15), fill=(126, 128, 136, 255))


def story_01(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "The 3:17 Check")
    draw.text((72, 500), "Before", font=ft(112), fill=WHITE)
    draw.text((72, 625), "the next cup,", font=ft(112), fill=WHITE)
    draw.text((72, 810), "check what’s", font=ft(102), fill=WHITE)
    gradient_text(image, "still active.", (72, 925), ft(108), ORANGE, GREEN)
    draw.text((72, 1160), "TIMING CONTEXT FOR THE CHOICE", font=ft(20), fill=MUTED)
    draw.text((72, 1192), "YOU’RE ABOUT TO MAKE.", font=ft(20), fill=MUTED)
    footer(draw, "PRIVATE IPHONE PILOT  ↗")
    return image


def story_02(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "One private timeline")
    draw.text((72, 530), "Caffeine", font=ft(116), fill=WHITE)
    draw.text((72, 660), "+ cigarettes.", font=ft(102), fill=WHITE)
    gradient_text(image, "See the timing", (72, 855), ft(101), ORANGE, VIOLET)
    draw.text((72, 970), "together.", font=ft(108), fill=WHITE)
    draw.text((72, 1210), "COUNTS · GAPS · PAIRINGS · CONTEXT", font=ft(19), fill=MUTED)
    draw.text((72, 1243), "DESCRIPTIVE PATTERNS. NO FALSE CERTAINTY.", font=ft(19), fill=MUTED)
    footer(draw, "JOIN THE PRIVATE PILOT  ↗")
    return image


def story_03(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "Honest uncertainty")
    draw.text((72, 585), "A range.", font=ft(130), fill=WHITE)
    draw.text((72, 790), "Not a", font=ft(116), fill=WHITE)
    gradient_text(image, "magic score.", (72, 920), ft(112), ORANGE, VIOLET)
    draw.text((72, 1190), "THE ESTIMATE CAN BE USEFUL", font=ft(20), fill=MUTED)
    draw.text((72, 1223), "WITHOUT PRETENDING TO BE EXACT.", font=ft(20), fill=MUTED)
    footer(draw)
    return image


def story_04(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "Cigarette Intelligence")
    draw.text((72, 520), "Count the", font=ft(112), fill=WHITE)
    draw.text((72, 645), "moments.", font=ft(122), fill=WHITE)
    gradient_text(image, "Notice the", (72, 840), ft(106), VIOLET, GREEN)
    draw.text((72, 958), "context.", font=ft(118), fill=WHITE)
    draw.text((72, 1220), "SINCE LAST · WITH CAFFEINE · SLEEP WINDOW", font=ft(18), fill=MUTED)
    draw.text((72, 1253), "NO ABSORBED-NICOTINE ESTIMATE. NO JUDGMENT.", font=ft(18), fill=MUTED)
    footer(draw)
    return image


def story_05(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "Private by design")
    draw.text((72, 600), "Useful", font=ft(126), fill=WHITE)
    draw.text((72, 740), "context.", font=ft(126), fill=WHITE)
    gradient_text(image, "Still yours.", (72, 955), ft(122), ORANGE, GREEN)
    draw.text((72, 1240), "ON-DEVICE FIRST", font=ft(21), fill=WHITE)
    draw.text((72, 1283), "HEALTHKIT OPTIONAL", font=ft(21), fill=WHITE)
    draw.text((72, 1326), "0 AD TRACKERS", font=ft(21), fill=WHITE)
    footer(draw, "READ THE PRIVACY APPROACH  ↗")
    return image


def story_06(background: Image.Image) -> Image.Image:
    image = background.copy()
    draw = ImageDraw.Draw(image)
    brand(draw, "7-day pilot mission")
    draw.text((72, 525), "7 days.", font=ft(136), fill=WHITE)
    gradient_text(image, "One honest", (72, 740), ft(112), ORANGE, GREEN)
    draw.text((72, 865), "insight.", font=ft(130), fill=WHITE)
    draw.text((72, 1160), "01  LOG THE MOMENTS", font=ft(20), fill=MUTED)
    draw.text((72, 1210), "02  REVIEW THE PATTERN", font=ft(20), fill=MUTED)
    draw.text((72, 1260), "03  TELL US WHAT FELT USEFUL—OR WRONG", font=ft(20), fill=MUTED)
    footer(draw, "REQUEST TESTFLIGHT ACCESS  ↗")
    return image


STORY_BUILDERS = [story_01, story_02, story_03, story_04, story_05, story_06]


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    BACKGROUNDS.mkdir(parents=True, exist_ok=True)
    STORIES.mkdir(parents=True, exist_ok=True)
    exports = []
    generated_backgrounds = []

    for index, (filename, builder, description) in enumerate(BACKGROUND_BUILDERS, start=1):
        background = builder().convert("RGB")
        background_path = BACKGROUNDS / filename
        background.save(background_path, quality=96)
        generated_backgrounds.append(background.convert("RGBA"))
        exports.append({
            "file": f"backgrounds/{filename}",
            "kind": "blank-gradient-background",
            "description": description,
            "width": W,
            "height": H,
            "sha256": sha(background_path),
        })

        story_path = STORIES / f"cafeinex-minimal-story-{index:02d}.png"
        STORY_BUILDERS[index - 1](generated_backgrounds[index - 1]).convert("RGB").save(story_path, quality=96)
        exports.append({
            "file": f"stories/{story_path.name}",
            "kind": "finished-minimal-story",
            "width": W,
            "height": H,
            "safe_area": {"top": 150, "bottom": 220, "left": 70, "right": 70},
            "sha256": sha(story_path),
        })

    manifest = {
        "campaign": "The 3:17 Check — Minimal Edition",
        "platform": "Instagram Stories",
        "dimensions": "1080x1920",
        "screenshots": False,
        "generated_photography": False,
        "backgrounds_are_content_free": True,
        "exports": exports,
    }
    (CAMPAIGN / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
