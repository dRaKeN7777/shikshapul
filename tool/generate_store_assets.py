from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "assets" / "branding"
STORE = ROOT / "store_assets"
BRAND.mkdir(parents=True, exist_ok=True)
STORE.mkdir(parents=True, exist_ok=True)

NAVY = "#0B1020"
NAVY_2 = "#14213D"
BLUE = "#38BDF8"
BLUE_2 = "#0EA5E9"
AMBER = "#F59E0B"
WHITE = "#F8FAFC"
MUTED = "#CBD5E1"


def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            pass
    return ImageFont.load_default()


def rounded_gradient(size):
    img = Image.new("RGB", (size, size), NAVY)
    px = img.load()
    for y in range(size):
        for x in range(size):
            radial = max(0.0, 1.0 - (((x - size * 0.55) ** 2 + (y - size * 0.38) ** 2) ** 0.5) / (size * 0.9))
            t = 0.12 * radial
            a = (11, 16, 32)
            b = (20, 33, 61)
            px[x, y] = tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))
    return img


def draw_mark(draw, box, stroke_scale=1.0):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    cx = (x0 + x1) / 2
    sw = max(8, int(w * 0.055 * stroke_scale))

    # Open book: two confident blue pages, creating a clear education signal.
    left_page = [(cx, y0 + h * .56), (x0 + w * .10, y0 + h * .42), (x0 + w * .10, y0 + h * .77), (cx, y0 + h * .90)]
    right_page = [(cx, y0 + h * .56), (x1 - w * .10, y0 + h * .42), (x1 - w * .10, y0 + h * .77), (cx, y0 + h * .90)]
    draw.polygon(left_page, fill=BLUE)
    draw.polygon(right_page, fill=BLUE_2)
    draw.line([(cx, y0 + h * .56), (cx, y0 + h * .89)], fill=WHITE, width=max(3, sw // 3))

    # Bridge: amber arch, deck, and three piers. It carries the "Pul" meaning.
    arch_box = [x0 + w * .12, y0 + h * .08, x1 - w * .12, y0 + h * .67]
    draw.arc(arch_box, start=198, end=342, fill=AMBER, width=sw)
    deck_y = y0 + h * .48
    draw.line([(x0 + w * .12, deck_y), (x1 - w * .12, deck_y)], fill=AMBER, width=sw)
    for px in (x0 + w * .24, cx, x1 - w * .24):
        draw.line([(px, deck_y - sw * .25), (px, y0 + h * .62)], fill=AMBER, width=max(7, int(sw * .72)))
    draw.ellipse([cx - sw * .45, y0 + h * .02, cx + sw * .45, y0 + h * .02 + sw * .9], fill=AMBER)


def create_icon():
    size = 1024
    img = rounded_gradient(size)
    draw = ImageDraw.Draw(img)
    draw_mark(draw, (190, 150, 834, 840))
    img.save(BRAND / "shikshapul_logo.png", optimize=True)
    img.resize((512, 512), Image.Resampling.LANCZOS).save(STORE / "app_icon_512.png", optimize=True)

    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, pixels in densities.items():
        path = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png"
        img.resize((pixels, pixels), Image.Resampling.LANCZOS).save(path, optimize=True)

    ios = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for path in ios.glob("*.png"):
        with Image.open(path) as existing:
            pixels = existing.size[0]
        img.resize((pixels, pixels), Image.Resampling.LANCZOS).save(path, optimize=True)

    web = ROOT / "web"
    web_icons = web / "icons"
    web_icons.mkdir(parents=True, exist_ok=True)
    img.resize((32, 32), Image.Resampling.LANCZOS).save(web / "favicon.png", optimize=True)
    for filename, pixels in {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }.items():
        img.resize((pixels, pixels), Image.Resampling.LANCZOS).save(
            web_icons / filename, optimize=True
        )


def create_feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), NAVY)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        color = tuple(int(a * (1 - t) + b * t) for a, b in zip((11, 16, 32), (20, 58, 95)))
        draw.line((0, y, w, y), fill=color)
    for x, y, r, color in [(900, 60, 210, "#132B4A"), (760, 460, 260, "#102944"), (80, 420, 180, "#111D35")]:
        draw.ellipse((x-r, y-r, x+r, y+r), fill=color)
    draw_mark(draw, (66, 80, 390, 410), stroke_scale=.9)
    draw.text((440, 105), "ShikshaPul", font=font(70, True), fill=WHITE)
    draw.text((444, 190), "Nepal Entrance Preparation", font=font(34, True), fill=BLUE)
    draw.text((444, 250), "Practice offline. Learn from mistakes.\nBuild exam confidence.", font=font(28), fill=MUTED, spacing=12)
    pill = (442, 365, 870, 425)
    draw.rounded_rectangle(pill, radius=30, fill=AMBER)
    draw.text((474, 377), "IOE  •  KU  •  PU  •  MECEE-BL", font=font(22, True), fill=NAVY)
    img.save(STORE / "feature_graphic_1024x500.png", optimize=True)


if __name__ == "__main__":
    create_icon()
    create_feature_graphic()
    print(BRAND / "shikshapul_logo.png")
    print(STORE / "app_icon_512.png")
    print(STORE / "feature_graphic_1024x500.png")
