from pathlib import Path
from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "assets" / "branding"
STORE = ROOT / "store_assets"
BRAND.mkdir(parents=True, exist_ok=True)
STORE.mkdir(parents=True, exist_ok=True)

def create_icon():
    size = 1024
    source_path = BRAND / "shikshapul_logo_full.png"
    with Image.open(source_path) as source_file:
        source = source_file.convert("RGB")

    # The supplied artwork is landscape and includes a wordmark. Launcher icons
    # use only its emblem so the details remain readable at 48 px.
    sw, sh = source.size
    emblem = source.crop(
        (
            int(sw * .285),
            int(sh * .055),
            int(sw * .755),
            int(sh * .715),
        )
    )
    emblem = ImageOps.contain(emblem, (900, 790), Image.Resampling.LANCZOS)

    img = Image.new("RGB", (size, size), "#F7FCFF")
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        color = tuple(
            int(a * (1 - t) + b * t)
            for a, b in zip((247, 252, 255), (228, 244, 250))
        )
        draw.line((0, y, size, y), fill=color)
    x = (size - emblem.width) // 2
    y = (size - emblem.height) // 2 - 8
    img.paste(emblem, (x, y))
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
    with Image.open(BRAND / "shikshapul_logo_full.png") as source_file:
        source = source_file.convert("RGB")
    graphic = ImageOps.fit(
        source,
        (1024, 500),
        method=Image.Resampling.LANCZOS,
        centering=(.5, .5),
    )
    graphic.save(STORE / "feature_graphic_1024x500.png", optimize=True)


if __name__ == "__main__":
    create_icon()
    create_feature_graphic()
    print(BRAND / "shikshapul_logo.png")
    print(STORE / "app_icon_512.png")
    print(STORE / "feature_graphic_1024x500.png")
