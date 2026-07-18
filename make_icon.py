#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BG = (139, 30, 30)       # deep lacquer red
PIECE = (245, 232, 199)  # pale wood
INK = (30, 20, 15)       # near-black ink

img = Image.new("RGB", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)

# Shogi-piece silhouette: pentagon (flat base, pointed top), scaled to fill most of the canvas
cx, cy = SIZE / 2, SIZE / 2
w, h = SIZE * 0.62, SIZE * 0.74
top = cy - h / 2
bottom = cy + h / 2
left = cx - w / 2
right = cx + w / 2
point_y = top
shoulder_y = top + h * 0.22

pentagon = [
    (cx, point_y),
    (right, shoulder_y),
    (right * 0.94 + cx * 0.06, bottom),
    (left * 0.94 + cx * 0.06, bottom),
    (left, shoulder_y),
]
draw.polygon(pentagon, fill=PIECE)

font = ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", int(SIZE * 0.34))
text = "将"
bbox = draw.textbbox((0, 0), text, font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
draw.text((cx - tw / 2 - bbox[0], cy - th / 2 - bbox[1] + SIZE * 0.03), text, font=font, fill=INK)

img.save("ShogiDo/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("wrote AppIcon.png")
