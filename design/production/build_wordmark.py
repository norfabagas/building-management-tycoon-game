"""Outline the bundled OFL Roboto font for a deterministic title export."""
import json
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[2]
font = TTFont(ROOT / "assets/fonts/Roboto.ttf")
glyphs = font.getGlyphSet(location={"wght": 600})
cmap = font.getBestCmap()
units = font["head"].unitsPerEm
lines = []
for text, size, baseline in [("Building Management", 42, 59), ("Tycoon", 48, 117)]:
    paths, advance = [], 0
    for character in text:
        name = cmap[ord(character)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        paths.append({"x": advance, "d": pen.getCommands()})
        advance += glyphs[name].width
    lines.append({"text": text, "x": 160, "y": baseline,
                  "scale": size / units, "paths": paths})
target = ROOT / "design/production/sources/wordmark-paths.json"
target.parent.mkdir(parents=True, exist_ok=True)
alphabet = {}
for code in range(32, 127):
    character = chr(code)
    name = cmap[code]
    pen = SVGPathPen(glyphs)
    glyphs[name].draw(pen)
    alphabet[character] = {"d": pen.getCommands(), "width": glyphs[name].width}
target.write_text(json.dumps({"font": "assets/fonts/Roboto.ttf", "units": units,
                              "lines": lines, "glyphs": alphabet}), encoding="utf-8")
print("Outlined bundled Roboto title; BM mark remains unchanged.")
