"""Normalize generated terrain panoramas to the game's 768 × 180 pixel grid."""

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance


PIXEL_WIDTH = 768
PIXEL_HEIGHT = 180
FIELD = Path(__file__).resolve().parents[1] / "game" / "assets" / "field"


def normalize(source, output, endpoints):
    with Image.open(source) as panorama:
        panorama = panorama.convert("RGB")
        if panorama.width < panorama.height * 2:
            raise ValueError(f"{source} must be a continuous panorama")
        if len(endpoints) != 4:
            raise ValueError("Specify top, walk surface start, walk surface end and bottom")
        rows = [int(row * panorama.height) for row in endpoints]
        target_rows = [0, 86, 145, PIXEL_HEIGHT]
        field = Image.new("RGB", (PIXEL_WIDTH, PIXEL_HEIGHT))
        for top, bottom, output_top, output_bottom in zip(rows[:-1], rows[1:], target_rows[:-1], target_rows[1:]):
            band = panorama.crop((0, top, panorama.width, bottom))
            field.paste(band.resize((PIXEL_WIDTH, output_bottom - output_top), Image.Resampling.LANCZOS), (0, output_top))
        field = ImageEnhance.Sharpness(field).enhance(1.16)
        field.quantize(colors=176, dither=Image.Dither.NONE).save(output, optimize=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("field")
    parser.add_argument("crop", type=float, nargs=4)
    args = parser.parse_args()
    if args.crop != sorted(set(args.crop)) or not 0 <= args.crop[0] < args.crop[-1] <= 1:
        parser.error("crop limits must increase from 0 to 1")
    normalize(args.source, FIELD / f"{args.field}.png", args.crop)


if __name__ == "__main__":
    main()
