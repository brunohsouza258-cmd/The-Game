#!/usr/bin/env python3
"""Gera cenários derivados dos 4 originais (mesmo estilo de pintura).

Uso: python tools/make_backgrounds.py   (requer Pillow)
Cria em assets/backgrounds/: festival_night, school_night, school_decayed,
rooftop_dusk, rooftop_rain. O Godot importa os PNGs automaticamente.
"""
import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "backgrounds")
W, H = 1376, 768
rng = random.Random(1347)


def load(name):
    return Image.open(os.path.join(BG, name + ".png")).convert("RGB")


def save(img, name):
    img.convert("RGB").save(os.path.join(BG, name + ".png"))
    print("ok", name)


def tint(img, color, amount):
    layer = Image.new("RGB", img.size, color)
    return Image.blend(img, ImageChops.multiply(img, layer), amount)


def grade(img, color, amount, brightness=1.0, saturation=1.0, contrast=1.0):
    img = ImageEnhance.Color(img).enhance(saturation)
    img = ImageEnhance.Contrast(img).enhance(contrast)
    img = ImageEnhance.Brightness(img).enhance(brightness)
    return tint(img, color, amount)


def vignette(img, strength=0.65):
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((-W * 0.25, -H * 0.3, W * 1.25, H * 1.3), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGB", img.size, (0, 0, 0))
    return Image.composite(img, Image.blend(img, dark, strength), mask)


def glow(img, x, y, radius, color, intensity=0.9):
    layer = Image.new("RGB", img.size, (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((x - radius, y - radius, x + radius, y + radius), fill=tuple(int(c * intensity) for c in color))
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.6))
    return ImageChops.add(img, layer)


def lantern(img, x, y, size, color=(255, 170, 90)):
    img = glow(img, x, y, size * 2.2, color, 0.4)
    d = ImageDraw.Draw(img)
    body = (x - size * 0.55, y - size * 0.7, x + size * 0.55, y + size * 0.7)
    d.ellipse(body, fill=(255, 205, 140), outline=(120, 40, 20), width=max(1, size // 10))
    d.line((x - size * 0.5, y - size * 0.25, x + size * 0.5, y - size * 0.25), fill=(170, 70, 40), width=max(1, size // 12))
    d.line((x - size * 0.5, y + size * 0.25, x + size * 0.5, y + size * 0.25), fill=(170, 70, 40), width=max(1, size // 12))
    d.rectangle((x - size * 0.2, y - size * 0.85, x + size * 0.2, y - size * 0.7), fill=(60, 30, 20))
    return img


def noise(img, amount=18):
    n = Image.effect_noise(img.size, amount).convert("RGB")
    return ImageChops.add(img, n, scale=1.0, offset=-128 + 0)


def festival_night():
    img = grade(load("courtyard"), (110, 120, 200), 0.85, 0.5, 0.75)
    for (x0, y0, x1, y1) in [(-40, 70, 700, 120), (480, 30, 1440, 170)]:
        n = 12
        pts = [(x0 + (x1 - x0) * i / (n - 1), y0 + (y1 - y0) * i / (n - 1) + math.sin(i / (n - 1) * math.pi) * 44) for i in range(n)]
        d = ImageDraw.Draw(img)
        d.line(pts, fill=(60, 40, 40), width=2)
        for i, (x, y) in enumerate(pts):
            img = lantern(img, int(x), int(y) + 22, 24 + (i % 3) * 4, (255, 150 + (i % 3) * 25, 80))
    for _ in range(9):
        img = lantern(img, rng.randint(40, W - 40), rng.randint(300, 560), rng.randint(14, 20))
    return vignette(img, 0.55)


def school_night():
    img = grade(load("hallway_dusk"), (80, 95, 170), 0.9, 0.42, 0.55, 1.1)
    img = glow(img, 330, 320, 170, (120, 150, 255), 0.55)
    img = glow(img, W - 280, 380, 150, (100, 130, 235), 0.45)
    img = glow(img, W // 2, 90, 60, (200, 230, 255), 0.6)
    return vignette(img, 0.6)


def school_decayed():
    img = grade(load("classroom"), (190, 120, 120), 0.7, 0.62, 0.35, 1.25)
    img = noise(img, 22)
    d = ImageDraw.Draw(img, "RGBA")
    # Riscos de contagem, como na parede do telhado.
    for g in range(7):
        gx = 140 + g * 36 + rng.randint(-4, 4)
        for i in range(4):
            x = gx + i * 6
            d.line((x, 120, x + rng.randint(-2, 2), 190), fill=(30, 10, 10, 210), width=2)
        d.line((gx - 3, 185, gx + 22, 128), fill=(30, 10, 10, 210), width=2)
    # Rachaduras.
    for _ in range(5):
        x, y = rng.randint(0, W), rng.randint(0, 200)
        pts = [(x, y)]
        for _ in range(14):
            x += rng.randint(-26, 26)
            y += rng.randint(14, 44)
            pts.append((x, y))
        d.line(pts, fill=(15, 8, 8, 200), width=2)
    # Mancha avermelhada vinda de cima.
    stain = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(stain).ellipse((W * 0.55, -200, W * 1.1, 320), fill=(120, 20, 30, 70))
    img = Image.alpha_composite(img.convert("RGBA"), stain.filter(ImageFilter.GaussianBlur(70))).convert("RGB")
    return vignette(img, 0.75)


def rooftop_base(sky_color, floor_color, fence_color):
    sky = load("courtyard").crop((0, 0, W, 330)).resize((W, 470), Image.LANCZOS)
    img = Image.new("RGB", (W, H), floor_color)
    img.paste(sky, (0, 0))
    d = ImageDraw.Draw(img)
    # Piso de concreto com gradiente e juntas em perspectiva.
    for y in range(470, H):
        t = (y - 470) / (H - 470)
        c = tuple(int(f * (0.75 + 0.45 * t)) for f in floor_color)
        d.line((0, y, W, y), fill=c)
    for i in range(-8, 18):
        d.line((W / 2 + (i - 5) * 30, 470, (i - 5) * 210 + W / 2, H), fill=(0, 0, 0), width=1)
    for k in range(5):
        y = 470 + int((k / 5) ** 1.8 * (H - 470)) + 12
        d.line((0, y, W, y), fill=(40, 40, 50), width=1)
    # Parapeito e alambrado.
    d.rectangle((0, 455, W, 478), fill=tuple(max(0, c - 30) for c in floor_color))
    top = 140
    for x in range(-40, W + 60, 34):
        d.line((x, top, x + 120, 470), fill=fence_color, width=1)
        d.line((x + 120, top, x, 470), fill=fence_color, width=1)
    for x in range(0, W + 1, 230):
        d.rectangle((x - 5, top - 10, x + 5, 478), fill=tuple(max(0, c - 20) for c in fence_color))
    d.rectangle((0, top - 12, W, top), fill=tuple(max(0, c - 20) for c in fence_color))
    img = ImageEnhance.Brightness(img).enhance(1.0)
    return img


def rooftop_dusk():
    img = rooftop_base((255, 170, 120), (150, 150, 160), (110, 115, 130))
    img = grade(img, (255, 170, 130), 0.75, 0.9, 0.9)
    img = glow(img, 1000, 330, 260, (255, 150, 70), 0.7)
    return vignette(img, 0.5)


def rooftop_rain():
    img = rooftop_base((60, 70, 120), (110, 110, 125), (90, 95, 110))
    img = grade(img, (80, 100, 190), 0.9, 0.5, 0.55, 1.1)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(900):
        x, y = rng.randint(0, W), rng.randint(0, H)
        d.line((x, y, x - 6, y + 22), fill=(200, 215, 255, rng.randint(40, 120)), width=1)
    img = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")
    img = glow(img, 1030, 120, 90, (200, 220, 255), 0.35)
    return vignette(img, 0.65)


if __name__ == "__main__":
    save(festival_night(), "festival_night")
    save(school_night(), "school_night")
    save(school_decayed(), "school_decayed")
    save(rooftop_dusk(), "rooftop_dusk")
    save(rooftop_rain(), "rooftop_rain")
