"""Builds the logo textures from the master, assets/logo.png.

    python tools/assets.py

Writes:
- Media/Logo.tga: 256 x 256, uncompressed 32-bit BGRA with alpha and a top-left origin,
  the format Hourstone's tools/assets.py writes for WoW;
- docs/curseforge/logo-400.png: 400 x 400 for the CurseForge project page;
- docs/design/assets/Logo.png: 256 x 256 for the mockup.

The master's transparent margin is trimmed to 3 % so the logo fills the small minimap icon.
Requires Pillow.
"""
from pathlib import Path
import struct

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "logo.png"
MARGIN = 0.03


def squared(im):
    im = im.convert("RGBA")
    box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    im = im.crop(box)
    side = round(max(im.size) * (1 + 2 * MARGIN))
    out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    out.alpha_composite(im, ((side - im.width) // 2, (side - im.height) // 2))
    return out


def resized(im, size):
    # Premultiplied, so no dark fringe bleeds in from fully transparent pixels.
    return im.convert("RGBa").resize((size, size), Image.Resampling.LANCZOS).convert("RGBA")


def write_tga(im, path):
    width, height = im.size
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 40)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + im.tobytes("raw", "BGRA"))


def write_png(im, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)


def main():
    logo = squared(Image.open(MASTER))
    write_tga(resized(logo, 256), ROOT / "Media" / "Logo.tga")
    write_png(resized(logo, 400), ROOT / "docs" / "curseforge" / "logo-400.png")
    write_png(resized(logo, 256), ROOT / "docs" / "design" / "assets" / "Logo.png")
    for path in ("Media/Logo.tga", "docs/curseforge/logo-400.png", "docs/design/assets/Logo.png"):
        print(path)


if __name__ == "__main__":
    main()
