import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[1]
TOOL = Path("D:/AI/dev_toolchain/image_gen_tool_list")
STYLE = (
    "Wide 16:9 landscape for an original Chinese wuxia 2D role-playing game. "
    "High quality modern 16-bit pixel art, deliberate crisply clustered pixels, hand-pixelled "
    "SFC-era JRPG environment, limited dark indigo shadows, restrained luminous accents, "
    "strong foreground and atmospheric layers, no text, no logos, no panels, no interface. "
)
SCENES = {
    "title": "A small black silhouette of two wandering swordsmen seen from behind on a jagged ridge in the lower right corner. Huge golden full moon in the upper right half above misty jagged Chinese karst mountains and a temple silhouette on a cliff. LEFT HALF is quiet dark midnight blue mountain haze, intentionally much darker and blank to leave space for title.",
    "hall": "Empty grand ancient Chinese mountain sect courtyard at dusk, tiered roofs across top with red lanterns, towering crimson pillars at edges, dramatic warm amber lit stairway centered in distance, broad dark blue stone tiled floor completely empty in lower half, no people.",
    "village": "Quiet mountain village of ancient China at rainy twilight, elegant dark curved tiled roofs and bamboo with golden lanterns along a wooden bridge, distant pale jade blue fog, the entire lower half is an empty mossy flat stone courtyard, no figures.",
    "forge": "Immense underground Chinese sword forge in mountain cavern, amber molten channels and ancient bronze braziers along distant walls, rows of swords embedded near the side walls, huge deep orange light from above, open charcoal rocky platform in foreground, no figures.",
    "pool": "Dark haunted Chinese mountain cave shrine with layered purple rock pillars, a still wine-red reflecting pool behind an empty platform, candles and one torii-like Chinese stone portal in the distance, plum and magenta dusk light, empty dark stone foreground in lower half, no figures.",
    "palace": "Ancient Chinese palace seized by a warlord, stormy moonlit cobalt sky above ornate blue-roof gates, torn crimson pennants, thin moonlight on the empty cold blue-gray stone plaza in the foreground, a few amber flames near walls, no figures.",
    "peak": "Chinese wuxia final duel atop mountain terrace above a sea of storm clouds, giant stylized Chinese stone dragon relief in distance beneath an eclipsed amber sun, tattered flags on the two edges, desaturated violet rock and dark slate empty stone floor in lower half, no figures.",
}

def main(keys):
    source_dir = ROOT / "art-source"
    output_dir = ROOT / "game/assets/paintings"
    source_dir.mkdir(exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)
    for key in keys:
        seed = 221108 + list(SCENES).index(key)
        source = source_dir / (key + ".png")
        prompt = STYLE + SCENES[key]
        if not source.exists():
            print("Generating", key, flush=True)
            cmd = [str(TOOL / ".venv/Scripts/python.exe"), str(TOOL / "generate.py"),
                   prompt, "--mode", "turbo", "--width", "896", "--height", "512", "--seed", str(seed)]
            result = subprocess.run(cmd, encoding="utf-8", capture_output=True)
            if result.returncode:
                print(result.stderr, result.stdout, flush=True)
                continue
            details = json.loads(result.stdout.strip().splitlines()[-1])
            with Image.open(details["images"][0]) as image:
                image.convert("RGB").save(source)
            source.with_suffix(".json").write_text(json.dumps(
                {"tool": "local Qwen Turbo via ComfyUI", "mode": "turbo", "seed": seed,
                 "prompt": prompt, "job": details.get("prompt_id"),
                 "output": f"game/assets/paintings/{key}.png",
                 "processing": "crop and downsample to 320x180, quantize 72 colors"},
                ensure_ascii=False, indent=2), encoding="utf-8")
        with Image.open(source) as image:
            cropped = ImageOps.fit(image.convert("RGB"), (320, 180), Image.Resampling.LANCZOS)
            cropped = ImageEnhance.Color(cropped).enhance(.86)
            cropped.quantize(colors=72, dither=Image.Dither.NONE).save(output_dir / (key + ".png"))
        print("Processed", key, flush=True)

if __name__ == "__main__":
    main(sys.argv[1:] or SCENES)

