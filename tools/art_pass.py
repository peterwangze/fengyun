"""Prepare the GPT Image art pass with the local Pillow toolchain.

Run with the asset_pipeline_tool_list Python. Originals and map layout remain
under art-source/art-update; this script writes the in-game derivatives.
"""
import json
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art-source/art-update"
CHAPTER_ONE = ROOT / "art-source/chapter-one"
EVOLUTION = ROOT / "art-source/evolution"
ASSETS = ROOT / "game/assets"
ACTOR_CELL = 56
FEET = 53

ACTOR_SHEETS = {
    "heroes": ("wind", "cloud", "frost", "dream", "sage", "guide", "guard", "blade"),
    "foes": ("captain", "shade", "claw", "duan", "juexin", "godless", "boss", "beast"),
}
EFFECTS = ("blade", "wind", "cloud", "frost", "heal", "break", "combo", "dark")


def map_art():
    layouts = json.loads((SOURCE / "layout.json").read_text(encoding="utf-8"))
    new_rooms = json.loads((CHAPTER_ONE / "layout.json").read_text(encoding="utf-8"))
    layouts["hall"].update(new_rooms.pop("hall"))
    layouts.update(new_rooms)
    later = json.loads((EVOLUTION / "layout.json").read_text(encoding="utf-8"))
    for key, details in later.items():
        layouts.setdefault(key, {}).update(details)
    directory = ASSETS / "field"
    directory.mkdir(exist_ok=True)
    battles = ASSETS / "arenas"
    battles.mkdir(exist_ok=True)
    for key, data in layouts.items():
        folder = EVOLUTION if key in ("jail", "lodge") else (CHAPTER_ONE if key in new_rooms else SOURCE)
        with Image.open(folder / (key + ".png")) as source:
            small = ImageOps.fit(source.convert("RGB"), (320, 180), Image.Resampling.LANCZOS)
        small = ImageEnhance.Sharpness(small).enhance(1.13)
        small = ImageEnhance.Color(small).enhance(0.94)
        if key == "forge":
            paint_ledge(small)
        field = small.quantize(colors=152, dither=Image.Dither.NONE)
        field.save(directory / (key + ".png"), optimize=True)
        top = data.pop("battle_top", None)
        if top is not None:
            field.crop((0, top, 320, top + 104)).save(battles / (key + ".png"), optimize=True)
        canopy = data.pop("canopy", None)
        if canopy:
            mask = Image.new("L", field.size)
            ImageDraw.Draw(mask).polygon([tuple(point) for point in canopy], fill=255)
            overlay = field.convert("RGBA")
            overlay.putalpha(mask)
            overlay.save(directory / (key + "_canopy.png"), optimize=True)
        (directory / (key + ".json")).write_text(
            json.dumps(data, separators=(",", ":")), encoding="utf-8")


def paint_ledge(image):
    draw = ImageDraw.Draw(image)
    draw.polygon([(126,56),(135,53),(185,53),(191,56),(188,63),(131,63)],
                 fill="#2a2532", outline="#382d39")
    draw.polygon([(127,56),(136,54),(185,54),(190,56),(187,60),(133,60)],
                 fill="#5e5059", outline="#80706e")
    for x in range(135, 187, 8):
        draw.line((x,56,x-1,61),fill="#443943")
        draw.point((x+3,55),fill="#947868")


def cells(sheet, columns=4):
    for row in range(2):
        for col in range(columns):
            yield sheet.crop((round(col * sheet.width / columns), round(row * sheet.height / 2),
                              round((col + 1) * sheet.width / columns), round((row + 1) * sheet.height / 2)))


def alpha_box(image, threshold):
    alpha = image.getchannel("A")
    return alpha.point(lambda a: 255 if a >= threshold else 0).getbbox()


def asset_colors(image, colors, solid):
    alpha = image.getchannel("A")
    rgb = image.convert("RGB").quantize(colors=colors, dither=Image.Dither.NONE).convert("RGB")
    result = rgb.convert("RGBA")
    if solid:
        result.putalpha(alpha.point(lambda a: 255 if a >= 125 else 0))
    else:
        result.putalpha(alpha.point(lambda a: 0 if a < 24 else min(255, round(a / 17) * 17)))
    return result


def actor_body(tile, key):
    box = alpha_box(tile, 165)
    if box is None:
        raise ValueError(f"No visible pixels for {key}")
    tile = tile.crop(box)
    target_height = 46 if key == "beast" else (51 if key in ("boss", "godless") else 49)
    factor = min(target_height / tile.height, 49 / tile.width)
    small = tile.resize((round(tile.width * factor), round(tile.height * factor)), Image.Resampling.LANCZOS)
    small = asset_colors(small, 44, True)
    alpha = small.getchannel("A")
    shoe_x = [x for y in range(max(0, small.height - 5), small.height)
              for x in range(small.width) if alpha.getpixel((x, y))]
    pivot = round(median(shoe_x)) if shoe_x else small.width // 2
    left = max(3, min(ACTOR_CELL - 3 - small.width, ACTOR_CELL // 2 - pivot))
    body = Image.new("RGBA", (ACTOR_CELL, ACTOR_CELL))
    body.paste(small, (left, FEET + 1 - small.height))
    return body


def pose(body, frame):
    if frame == 0:
        return body
    if frame == 7:
        cropped = body.crop(body.getbbox())
        down = cropped.rotate(59, resample=Image.Resampling.NEAREST, expand=True)
        down.thumbnail((51, 32), Image.Resampling.NEAREST)
        result = Image.new("RGBA", body.size)
        result.paste(down, ((ACTOR_CELL - down.width) // 2, FEET + 1 - down.height))
        return result
    result = Image.new("RGBA", body.size)
    src, dst = body.load(), result.load()
    for y in range(ACTOR_CELL):
        for x in range(ACTOR_CELL):
            sx, sy = x, y
            if frame in (1, 2, 3):
                direction = 1 if frame == 1 else -1
                if y < 38:
                    sx -= direction if y < 24 and frame != 2 else 0
                    sy += 1 if frame == 2 else 0
                elif frame != 2:
                    lead = 1 if x < ACTOR_CELL // 2 else -1
                    step = round(max(0, y - 37) * 2 / 16)
                    sx -= step * direction * lead
                    sy += step if lead * direction < 0 else 0
            elif frame == 4:
                sx -= round(max(0, FEET - y) * 5 / 47)
            elif frame == 5:
                sx += round(max(0, FEET - y) * 2 / 47)
                sy = round(FEET + (y - FEET) * 1.068)
            elif frame == 6:
                sx += round(max(0, FEET - y) * 6 / 47)
            if 0 <= sx < ACTOR_CELL and 0 <= sy < ACTOR_CELL:
                dst[x, y] = src[sx, sy]
    return result


def actors():
    directory = ASSETS / "actors"
    directory.mkdir(exist_ok=True)
    sheets = dict(ACTOR_SHEETS, wedding_cast=("kongci","groom","maid","servant"))
    for sheet_name, names in sheets.items():
        directory_source = CHAPTER_ONE if sheet_name == "wedding_cast" else SOURCE
        with Image.open(directory_source / (sheet_name + ".png")) as image:
            if image.mode != "RGBA" or image.getchannel("A").getextrema() != (0, 255):
                raise ValueError(f"Expected transparency in {sheet_name}")
            for tile, key in zip(cells(image, len(names) // 2), names, strict=True):
                body = actor_body(tile, key)
                atlas = Image.new("RGBA", (ACTOR_CELL * 8, ACTOR_CELL))
                for index in range(8):
                    sprite = pose(body, index)
                    visible = sprite.getbbox()
                    if not visible or visible[3] > FEET + 1 or visible[1] < 1:
                        raise ValueError(f"Unaligned {key} frame {index}: {visible}")
                    atlas.paste(sprite, (index * ACTOR_CELL, 0))
                atlas.save(directory / (key + ".png"), optimize=True)


def evolution_assets():
    actors_dir = ASSETS / "actors"
    direction_names = ("wind","cloud","frost","dream","sage","boatman")
    for direction in ("front","back"):
        with Image.open(EVOLUTION / (direction + ".png")) as sheet:
            if sheet.mode != "RGBA" or sheet.getchannel("A").getextrema()[0] != 0:
                raise ValueError("Directional sprites require transparency")
            for key, tile in zip(direction_names, cells(sheet,3), strict=True):
                body = actor_body(tile,key)
                atlas = Image.new("RGBA",(ACTOR_CELL * 4, ACTOR_CELL))
                for index in range(4):
                    atlas.paste(pose(body,index),(index * ACTOR_CELL,0))
                atlas.save(actors_dir / (key + "_" + direction + ".png"),optimize=True)
    poses = ("kick_ready","kick_hit","palm_ready","palm_hit","wind_combo","cloud_combo","dream_cast","frost_ready")
    with Image.open(EVOLUTION / "skills.png") as sheet:
        for key, tile in zip(poses, cells(sheet), strict=True):
            actor_body(tile,key).save(actors_dir / (key + ".png"),optimize=True)
    props_dir = ASSETS / "field/props"
    with Image.open(EVOLUTION / "props.png") as sheet:
        for key, tile in zip(("boat","signal","winch","prisoner"), cells(sheet,2), strict=True):
            if key == "prisoner":
                body = actor_body(tile,key)
                atlas = Image.new("RGBA",(ACTOR_CELL * 4,ACTOR_CELL))
                for index in range(4):
                    atlas.paste(pose(body,index),(index * ACTOR_CELL,0))
                atlas.save(actors_dir / "prisoner.png",optimize=True)
                continue
            tile = tile.crop(alpha_box(tile,160))
            limit = {"boat":(76,34),"signal":(25,42),"winch":(30,23)}[key]
            tile.thumbnail(limit,Image.Resampling.LANCZOS)
            asset_colors(tile,42,True).save(props_dir / (key + ".png"),optimize=True)


def effects():
    directory = ASSETS / "vfx"
    directory.mkdir(exist_ok=True)
    with Image.open(SOURCE / "effects.png") as sheet:
        if sheet.mode != "RGBA" or sheet.getchannel("A").getextrema() != (0, 255):
            raise ValueError("Expected a transparent effect sheet")
        for tile, key in zip(cells(sheet), EFFECTS, strict=True):
            box = alpha_box(tile, 100)
            if box is None:
                raise ValueError(f"No visible pixels for {key}")
            tile = tile.crop(box)
            cap = 112 if key == "combo" else 72
            tile.thumbnail((cap, cap), Image.Resampling.LANCZOS)
            asset_colors(tile, 64, False).save(directory / (key + ".png"), optimize=True)


def props():
    directory = ASSETS / "field/props"
    directory.mkdir(exist_ok=True)
    for kind in ("shrine", "chest", "empty", "exit", "exit_open"):
        image = Image.new("RGBA", (28, 32))
        draw = ImageDraw.Draw(image)
        draw.ellipse((4, 26, 24, 30), fill=(6, 10, 22, 118))
        if kind == "shrine":
            draw.polygon([(4,13),(10,7),(12,7),(14,3),(16,7),(19,8),(24,13),(22,16),(6,16)], fill="#171b2d")
            draw.line([(6,13),(13,8),(16,8),(22,13)], fill="#9c9bb2")
            draw.rectangle((9,15,19,22), fill="#54435a")
            draw.rectangle((11,15,17,20), fill="#c88d53")
            draw.rectangle((12,16,16,19), fill="#ffe5ab")
            draw.line((14,16,14,20), fill="#f4b666")
            draw.polygon([(11,21),(17,21),(17,27),(21,28),(21,30),(7,30),(7,28),(11,27)], fill="#586780")
            draw.line((8,27,20,27), fill="#8593a0")
        elif kind in ("chest", "empty"):
            draw.polygon([(5,19),(8,16),(20,16),(23,20),(23,27),(20,29),(6,28),(4,26)], fill="#241a2a")
            draw.rectangle((6,22,20,27), fill="#6d4039")
            draw.line((7,25,20,25), fill="#a97259")
            if kind == "chest":
                draw.polygon([(5,20),(9,16),(20,16),(22,20)], fill="#b0784f")
                draw.line((6,20,22,20), fill="#e0b37a", width=2)
                draw.rectangle((12,20,15,24), fill="#e7c584")
                draw.point((14,22), fill="#3c302e")
            else:
                draw.polygon([(5,19),(8,13),(19,13),(21,19)], fill="#704747")
                draw.line((8,14,19,14), fill="#b48a62")
                draw.rectangle((7,19,20,21), fill="#1b1d2b")
        else:
            bright = "#83dacb" if kind == "exit_open" else "#9aa6ba"
            draw.polygon([(5,25),(5,12),(8,8),(8,4),(20,4),(20,8),(23,12),(23,26),
                          (20,28),(8,28)], fill="#1d2a3d")
            draw.line([(7,23),(7,12),(11,8),(18,8),(21,12),(21,24)], fill="#576886", width=2)
            draw.line((9,25,20,25), fill="#8797ab")
            draw.polygon([(14,11),(19,16),(14,21),(9,16)], fill=bright)
            draw.line((12,16,16,16), fill="#273747")
        image.save(directory / (kind + ".png"), optimize=True)


if __name__ == "__main__":
    map_art()
    actors()
    effects()
    props()
    evolution_assets()
    print("Prepared field maps, arenas, character poses, props, and battle effects.")

