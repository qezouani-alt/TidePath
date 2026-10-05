"""Generate TidePath launcher icons from a simple code-native wave and hook mark."""
from __future__ import annotations

import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
S = 2048
canvas = Image.new('RGB', (S, S))
draw = ImageDraw.Draw(canvas)
for y in range(S):
    t = y / (S - 1)
    color = (
        round(5 + 1 * t),
        round(61 + 45 * t),
        round(91 + 55 * t),
    )
    draw.line((0, y, S, y), fill=color)

layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)
# Quiet concentric current lines in the background.
for inset, alpha in [(135, 31), (260, 21), (390, 13)]:
    d.arc((inset, inset, S + 300, S + 300), 180, 270, fill=(139, 237, 232, alpha), width=19)
# A small sunrise above the wave.
d.ellipse((1340, 472, 1515, 647), fill=(128, 232, 220, 255))
# Fishing hook: a clean vertical stem with a broad curved return.
points = [(1080, 370), (1080, 1090)]
for i in range(81):
    t = i / 80
    x = (1 - t) ** 2 * 1080 + 2 * (1 - t) * t * 1000 + t * t * 595
    y = (1 - t) ** 2 * 1090 + 2 * (1 - t) * t * 1570 + t * t * 1240
    points.append((x, y))
d.line((1080, 370, 1080, 1090), fill=(255, 255, 255, 255), width=112)
for x, y in points[2:]:
    d.ellipse((x - 56, y - 56, x + 56, y + 56), fill=(255, 255, 255, 255))
d.ellipse((1024, 314, 1136, 426), fill=(255, 255, 255, 255))
d.ellipse((539, 1184, 651, 1296), fill=(255, 255, 255, 255))
# The TidePath wave crosses in front of the hook.
wave = []
for x in range(310, 1739, 6):
    u = (x - 310) / 1428
    wave.append((x, 1070 + 106 * math.sin(2 * math.pi * (u + .08))))
d.line(wave, fill=(124, 236, 224, 255), width=90)
for x, y in wave:
    d.ellipse((x - 45, y - 45, x + 45, y + 45), fill=(124, 236, 224, 255))
# Short lower current adds depth without clutter.
lower = []
for x in range(790, 1640, 6):
    u = (x - 790) / 850
    lower.append((x, 1400 + 58 * math.sin(2 * math.pi * u)))
d.line(lower, fill=(124, 236, 224, 125), width=43)
for x, y in lower:
    d.ellipse((x - 21.5, y - 21.5, x + 21.5, y + 21.5), fill=(124, 236, 224, 125))
canvas = Image.alpha_composite(canvas.convert('RGBA'), layer).convert('RGB')
master = canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
branding = ROOT / 'assets/branding'
branding.mkdir(parents=True, exist_ok=True)
master.save(branding / 'tideline_icon.png')


def write(path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.Resampling.LANCZOS).save(path)


ios_dir = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios_dir / 'Contents.json').read_text())['images']:
    if 'filename' in entry:
        points = float(entry['size'].split('x')[0])
        scale = int(entry['scale'][0])
        write(ios_dir / entry['filename'], round(points * scale))

for size in (16, 32, 64, 128, 256, 512, 1024):
    write(ROOT / f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png', size)

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    write(ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)

for size in (192, 512):
    write(ROOT / f'web/icons/Icon-{size}.png', size)
    write(ROOT / f'web/icons/Icon-maskable-{size}.png', size)
write(ROOT / 'web/favicon.png', 32)
