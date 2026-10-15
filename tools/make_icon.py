#!/usr/bin/env python3
"""Gera o ícone do jogo (lanterna de papel) em assets/icon.png e assets/icon.ico.

Uso: python tools/make_icon.py   (requer Pillow)
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1024  # desenha grande e reduz, para ficar suave


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(size):
            px[x, y] = c
    return img


def glow(size, center, radius, color, strength):
    layer = Image.new("RGB", (size, size), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
              fill=tuple(int(c * strength) for c in color))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.55))


def lantern(size):
    cx, cy = size // 2, int(size * 0.46)
    w, h = int(size * 0.31), int(size * 0.33)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # corda e argola
    d.line((cx, int(size * 0.08), cx, cy - h - int(size * 0.045)), fill=(30, 12, 22, 255), width=int(size * 0.014))
    d.ellipse((cx - size * 0.018, cy - h - size * 0.07, cx + size * 0.018, cy - h - size * 0.035),
              outline=(60, 25, 40, 255), width=int(size * 0.012))
    # tampa de cima
    d.rounded_rectangle((cx - w * 0.5, cy - h - size * 0.03, cx + w * 0.5, cy - h + size * 0.035),
                        radius=int(size * 0.02), fill=(40, 18, 30, 255))
    # corpo
    body = (cx - w, cy - h + size * 0.02, cx + w, cy + h - size * 0.02)
    d.ellipse(body, fill=(236, 84, 60, 255))
    # degradê de luz por dentro: mais claro no centro
    inner = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    di = ImageDraw.Draw(inner)
    for i in range(18):
        t = i / 17
        r_w = w * (1 - t * 0.78)
        r_h = h * (1 - t * 0.78)
        col = (255, int(130 + 120 * t), int(80 + 130 * t), int(55 + 20 * t))
        di.ellipse((cx - r_w, cy - r_h, cx + r_w, cy + r_h), fill=col)
    layer = Image.alpha_composite(layer, inner.filter(ImageFilter.GaussianBlur(size * 0.012)))
    d = ImageDraw.Draw(layer)
    # nervuras horizontais
    for k in range(-3, 4):
        yy = cy + k * (h / 3.9)
        half = w * math.sqrt(max(0.0, 1 - ((yy - cy) / h) ** 2))
        d.line((cx - half, yy, cx + half, yy), fill=(120, 30, 30, 230), width=int(size * 0.011))
    # contorno
    d.ellipse(body, outline=(110, 24, 28, 255), width=int(size * 0.014))
    # tampa de baixo
    d.rounded_rectangle((cx - w * 0.5, cy + h - size * 0.035, cx + w * 0.5, cy + h + size * 0.03),
                        radius=int(size * 0.02), fill=(40, 18, 30, 255))
    # borla
    d.line((cx, cy + h + size * 0.03, cx, cy + h + size * 0.1), fill=(230, 190, 90, 255), width=int(size * 0.012))
    for off in (-0.018, 0.0, 0.018):
        d.line((cx, cy + h + size * 0.09, cx + size * off * 1.6, cy + h + size * 0.15), fill=(230, 190, 90, 255), width=int(size * 0.009))
    return layer


def build():
    bg = vertical_gradient(S, (16, 10, 40), (74, 24, 70))
    # estrelinhas
    d = ImageDraw.Draw(bg)
    for (x, y, r) in [(0.14, 0.16, 5), (0.82, 0.12, 4), (0.9, 0.34, 3), (0.1, 0.62, 3), (0.78, 0.82, 4), (0.2, 0.88, 3)]:
        d.ellipse((x * S - r, y * S - r, x * S + r, y * S + r), fill=(255, 235, 210))
    bg = ImageChops.add(bg, glow(S, (S // 2, int(S * 0.5)), int(S * 0.5), (255, 150, 70), 0.55))
    img = bg.convert("RGBA")
    img = Image.alpha_composite(img, lantern(S))
    # glitch discreto: duas faixas deslocadas, em referência ao terror
    for (y0, y1, dx) in [(0.62, 0.655, 26), (0.30, 0.322, -20)]:
        strip = img.crop((0, int(S * y0), S, int(S * y1)))
        img.paste(strip, (dx, int(S * y0)))
    # cantos arredondados
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.2), fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


if __name__ == "__main__":
    big = build()
    png = big.resize((512, 512), Image.LANCZOS)
    png.save(os.path.join(ROOT, "assets", "icon.png"))
    big.save(os.path.join(ROOT, "assets", "icon.ico"),
             sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("ok: assets/icon.png e assets/icon.ico")
