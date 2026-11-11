"""Prepare the chronicle and Tidegate maps, stage layers and sprite atlases."""
from copy import deepcopy
import json

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

from art_pass import ACTOR_CELL, ASSETS, ROOT, actor_body, alpha_box, asset_colors, cells, pose

SOURCE = ROOT / "art-source" / "chronicle"
TIDAL = ROOT / "art-source" / "tidal"
FIELD = ASSETS / "field"
ARENAS = ASSETS / "arenas"


def write_map(name, data):
    (FIELD / f"{name}.json").write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def render_maps(source_root):
    layouts = json.loads((source_root / "layout.json").read_text(encoding="utf-8"))
    for name, data in layouts.items():
        canopy = data.pop("canopy", None)
        battle_top = data.pop("battle_top")
        with Image.open(source_root / f"{name}.png") as source:
            pixels = ImageOps.fit(source.convert("RGB"), (320, 180), Image.Resampling.LANCZOS)
        pixels = ImageEnhance.Sharpness(pixels).enhance(1.12)
        pixels = pixels.quantize(colors=164, dither=Image.Dither.NONE)
        pixels.save(FIELD / f"{name}.png", optimize=True)
        pixels.crop((0, battle_top, 320, battle_top + 104)).save(ARENAS / f"{name}.png", optimize=True)
        if canopy:
            mask = Image.new("L", pixels.size)
            ImageDraw.Draw(mask).polygon([tuple(point) for point in canopy], fill=255)
            overlay = pixels.convert("RGBA")
            overlay.putalpha(mask)
            overlay.save(FIELD / f"{name}_canopy.png", optimize=True)
        write_map(name, data)


def create_fields():
    render_maps(SOURCE)
    hall = json.loads((FIELD / "hall.json").read_text(encoding="utf-8"))
    hall.pop("fights")
    hall["spawn"] = [78, 121]
    write_map("returnhall", hall)

    village = json.loads((FIELD / "village.json").read_text(encoding="utf-8"))
    dawn = deepcopy(village)
    dawn.pop("fights")
    dawn["spawn"] = village["west_spawn"]
    dawn["weather"] = "motes"
    dawn["lights"] = []
    write_map("dawn", dawn)
    if (SOURCE / "dawn.png").exists():
        with Image.open(SOURCE / "dawn.png") as source:
            pixels = ImageOps.fit(source.convert("RGB"), (320, 180), Image.Resampling.LANCZOS)
    else:
        with Image.open(FIELD / "village.png") as source:
            pixels = ImageOps.colorize(source.convert("L"), "#1a2937", "#ffddab", "#8b9f93")
    pixels.quantize(colors=164,dither=Image.Dither.NONE).save(FIELD / "dawn.png", optimize=True)


def strip(image, count):
    for index in range(count):
        yield image.crop((index * image.width // count, 0, (index + 1) * image.width // count, image.height))


def create_atlases():
    styles = ["wind", "cloud", "frost", "heal", "blade", "dark", "combo", "guard"]
    with Image.open(SOURCE / "moves.png") as sheet:
        for key, tile in zip(styles, cells(sheet.convert("RGBA"), 4), strict=True):
            box = alpha_box(tile, 62)
            cropped = tile.crop(box)
            cropped.thumbnail((96, 80), Image.Resampling.LANCZOS)
            asset_colors(cropped, 34, 62).save(ASSETS / "vfx" / f"chronicle_{key}.png", optimize=True)

    if (SOURCE / "fire.png").exists():
        with Image.open(SOURCE / "fire.png") as sheet:
            cropped = sheet.convert("RGBA")
            cropped = cropped.crop(alpha_box(cropped, 70))
            cropped.thumbnail((48, 44), Image.Resampling.LANCZOS)
            asset_colors(cropped, 28, 70).save(FIELD / "props" / "fire.png", optimize=True)

    if (SOURCE / "cast.png").exists():
        with Image.open(SOURCE / "cast.png") as sheet:
            for key, tile in zip(["chuchu", "dugu", "yan", "zhu"], strip(sheet.convert("RGBA"), 4), strict=True):
                actor_body(tile, key).save(ASSETS / "actors" / f"{key}.png", optimize=True)

    if (SOURCE / "portraits.png").exists():
        directory = ASSETS / "portraits"
        directory.mkdir(exist_ok=True)
        with Image.open(SOURCE / "portraits.png") as sheet:
            for key, tile in zip(["wind", "cloud", "dream", "boss"], strip(sheet.convert("RGBA"), 4), strict=True):
                tile = tile.crop(alpha_box(tile, 80))
                tile.thumbnail((88, 92), Image.Resampling.LANCZOS)
                canvas = Image.new("RGBA", (92, 94))
                canvas.alpha_composite(tile, ((92 - tile.width)//2, 94 - tile.height))
                asset_colors(canvas, 43, 70).save(directory / f"{key}.png", optimize=True)


def create_tidal_assets():
    render_maps(TIDAL)
    with Image.open(TIDAL / "cast.png") as sheet:
        for key, tile in zip(("tidal_chief", "tidal_drum"), strip(sheet.convert("RGBA"), 2), strict=True):
            body = actor_body(tile, key)
            frames = Image.new("RGBA", (ACTOR_CELL * 8, ACTOR_CELL))
            for frame in range(8):
                frames.alpha_composite(pose(body, frame), (frame * ACTOR_CELL, 0))
            frames.save(ASSETS / "actors" / f"{key}.png", optimize=True)


if __name__ == "__main__":
    create_fields()
    create_atlases()
    create_tidal_assets()
