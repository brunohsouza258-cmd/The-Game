#!/usr/bin/env python3
"""Gera cenários e objetos ilustrados que as descrições do roteiro pedem e o jogo não tinha.

Uso: python tools/make_scenes.py   (requer Pillow)

Cenários (1376x768) em assets/backgrounds/: bedroom_morning, bedroom_night, bus_rain,
cafeteria, infirmary, gym.
Objetos (cartões com sombra) em assets/inserts/: bilhete, notebook, desk_km, clock_2147,
photo_class, photo_kids, yearbook, roster, stopwatch, lunchboxes, white_lantern, wall_nao_suba.

São ilustrações simples feitas por código; quando houver arte de IA/artista, basta substituir
os PNGs mantendo os nomes.
"""
import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "backgrounds")
INS = os.path.join(ROOT, "assets", "inserts")
os.makedirs(INS, exist_ok=True)
W, H = 1376, 768
rng = random.Random(2026)
FONT_DIR = "C:/Windows/Fonts/"


def font(name, size):
    for n in (name, "Inkfree.ttf", "comic.ttf", "arial.ttf"):
        try:
            return ImageFont.truetype(FONT_DIR + n, size)
        except OSError:
            continue
    return ImageFont.load_default()


def hand(size):
    return font("Inkfree.ttf", size)


# ----------------------------------------------------------------- utilidades
def gradient(size, top, bottom, horizontal=False):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    n = w if horizontal else h
    for i in range(n):
        t = i / max(1, n - 1)
        c = tuple(int(top[k] + (bottom[k] - top[k]) * t) for k in range(3))
        if horizontal:
            d.line((i, 0, i, h), fill=c)
        else:
            d.line((0, i, w, i), fill=c)
    return img


def glow_layer(size, center, radius, color, strength=1.0):
    layer = Image.new("RGB", size, (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
              fill=tuple(int(c * strength) for c in color))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.6))


def noise(img, amount=10):
    n = Image.effect_noise(img.size, amount).convert("RGB")
    return ImageChops.add(img, n, scale=1.0, offset=-128)


def vignette(img, strength=0.55):
    w, h = img.size
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.2, -h * 0.25, w * 1.2, h * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(110))
    return Image.composite(img, Image.blend(img, Image.new("RGB", img.size, (0, 0, 0)), strength), mask)


def painterly(img, blur=1.0):
    """Suaviza e dá um grão leve, para os cenários não parecerem vetor chapado."""
    img = img.filter(ImageFilter.GaussianBlur(blur))
    img = img.filter(ImageFilter.UnsharpMask(radius=3, percent=60, threshold=2))
    return noise(img, 6)


def quad(d, pts, fill, outline=None):
    d.polygon(pts, fill=fill, outline=outline)


def save_bg(img, name):
    img.convert("RGB").save(os.path.join(BG, name + ".png"))
    print("cenário:", name)


def save_insert(img, name):
    img.save(os.path.join(INS, name + ".png"))
    print("objeto:", name)


# ----------------------------------------------------------------- cenários
def bedroom(night):
    wall_top, wall_bot = ((24, 28, 58), (18, 20, 42)) if night else ((246, 228, 204), (232, 206, 178))
    img = gradient((W, H), wall_top, wall_bot)
    d = ImageDraw.Draw(img)
    floor_y = int(H * 0.68)
    floor = gradient((W, H - floor_y), (92, 60, 40), (60, 38, 26)) if not night else gradient((W, H - floor_y), (34, 26, 30), (20, 16, 22))
    img.paste(floor, (0, floor_y))
    for x in range(-300, W + 300, 120):
        d.line((x, floor_y, x + (x - W / 2) * 0.8, H), fill=(0, 0, 0), width=2)
    d.rectangle((0, floor_y - 14, W, floor_y), fill=(70, 46, 38) if not night else (22, 18, 28))
    # janela com cortinas
    wx0, wy0, wx1, wy1 = 880, 120, 1230, 450
    sky_top, sky_bot = ((8, 12, 36), (30, 36, 80)) if night else ((255, 214, 170), (255, 244, 220))
    img.paste(gradient((wx1 - wx0, wy1 - wy0), sky_top, sky_bot), (wx0, wy0))
    if night:
        for _ in range(26):
            x, y = rng.randint(wx0 + 8, wx1 - 8), rng.randint(wy0 + 8, wy1 - 150)
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(240, 240, 255))
        d.ellipse((wx0 + 210, wy0 + 40, wx0 + 290, wy0 + 120), fill=(235, 238, 255))
    d.rectangle((wx0, wy0, wx1, wy1), outline=(60, 44, 36), width=10)
    d.line((wx0 + (wx1 - wx0) / 2, wy0, wx0 + (wx1 - wx0) / 2, wy1), fill=(60, 44, 36), width=8)
    d.line((wx0, wy0 + (wy1 - wy0) / 2, wx1, wy0 + (wy1 - wy0) / 2), fill=(60, 44, 36), width=8)
    curtain = (120, 60, 90) if night else (214, 140, 150)
    quad(d, [(wx0 - 70, wy0 - 30), (wx0 + 40, wy0 - 30), (wx0 + 10, wy1 + 40), (wx0 - 90, wy1 + 40)], curtain)
    quad(d, [(wx1 + 70, wy0 - 30), (wx1 - 40, wy0 - 30), (wx1 - 10, wy1 + 40), (wx1 + 90, wy1 + 40)], curtain)
    # cama
    d.rounded_rectangle((90, 330, 620, 520), radius=16, fill=(86, 58, 44))
    d.rounded_rectangle((110, 300, 600, 470), radius=22, fill=(120, 140, 200) if not night else (56, 66, 120))
    d.rounded_rectangle((130, 290, 300, 360), radius=22, fill=(245, 240, 236) if not night else (150, 150, 176))
    d.rounded_rectangle((110, 380, 600, 470), radius=18, fill=(150, 168, 224) if not night else (70, 84, 140))
    d.rectangle((90, 520, 112, 580), fill=(60, 40, 30))
    d.rectangle((598, 520, 620, 580), fill=(60, 40, 30))
    # escrivaninha e luminária
    d.rectangle((700, 430, 1010, 450), fill=(120, 84, 60))
    d.rectangle((712, 450, 730, 560), fill=(100, 70, 50))
    d.rectangle((980, 450, 998, 560), fill=(100, 70, 50))
    d.rectangle((760, 400, 850, 430), fill=(210, 80, 90))   # livros
    d.rectangle((775, 380, 860, 400), fill=(80, 140, 190))
    d.line((930, 430, 930, 360), fill=(40, 40, 50), width=6)
    d.line((930, 360, 975, 340), fill=(40, 40, 50), width=6)
    d.polygon([(960, 335), (1000, 345), (984, 372)], fill=(240, 200, 90))
    # prateleira e relógio
    d.rectangle((650, 210, 840, 224), fill=(110, 78, 56))
    for i, c in enumerate([(200, 80, 90), (90, 150, 200), (220, 190, 90), (110, 170, 120)]):
        d.rectangle((665 + i * 40, 160, 695 + i * 40, 210), fill=c)
    d.ellipse((1000, 70, 1070, 140), fill=(250, 248, 244), outline=(50, 40, 40), width=4)
    d.line((1035, 105, 1035, 80), fill=(40, 30, 30), width=3)
    d.line((1035, 105, 1054, 112), fill=(40, 30, 30), width=3)
    img = painterly(img, 1.2)
    beam = Image.new("RGB", (W, H), (0, 0, 0))
    bd = ImageDraw.Draw(beam)
    quad(bd, [(wx0, wy1), (wx1, wy1), (wx1 - 480, H), (wx0 - 520, H)], (95, 110, 190) if night else (255, 224, 150))
    beam = beam.filter(ImageFilter.GaussianBlur(36))
    img = ImageChops.add(img, ImageEnhance.Brightness(beam).enhance(0.55 if night else 0.45))
    if night:
        img = ImageChops.add(img, glow_layer((W, H), (975, 360), 240, (255, 190, 90), 0.5))
    img = vignette(img, 0.55 if night else 0.3)
    save_bg(img, "bedroom_night" if night else "bedroom_morning")


def bus_rain():
    img = gradient((W, H), (10, 14, 34), (28, 30, 62))
    layer = Image.new("RGB", (W, H), (0, 0, 0))
    ld = ImageDraw.Draw(layer)
    palette = [(255, 190, 90), (255, 110, 90), (120, 190, 255), (255, 240, 200), (150, 255, 180)]
    for _ in range(70):
        x, y, r = rng.randint(0, W), rng.randint(60, 520), rng.randint(10, 46)
        c = rng.choice(palette)
        ld.ellipse((x - r, y - r, x + r, y + r), fill=tuple(int(v * rng.uniform(0.35, 0.8)) for v in c))
    layer = layer.filter(ImageFilter.GaussianBlur(14))
    img = ImageChops.add(img, layer)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(260):
        x, y = rng.randint(0, W), rng.randint(0, 560)
        ln = rng.randint(30, 120)
        d.line((x, y, x - 6, y + ln), fill=(210, 225, 255, rng.randint(30, 90)), width=rng.choice([1, 2]))
    for _ in range(90):
        x, y = rng.randint(0, W), rng.randint(0, 560)
        d.ellipse((x - 3, y - 4, x + 3, y + 5), fill=(220, 235, 255, rng.randint(60, 130)))
    # moldura de janela e interior
    d.rectangle((0, 0, W, 38), fill=(22, 24, 34, 255))
    d.rectangle((0, 560, W, H), fill=(26, 28, 40, 255))
    for x in (330, 700, 1040):
        d.rectangle((x - 14, 38, x + 14, 560), fill=(28, 30, 42, 255))
    # encostos dos bancos, poste e alças
    for i, x in enumerate(range(-40, W, 360)):
        d.rounded_rectangle((x, 600, x + 330, H + 40), radius=30, fill=(60, 66, 120, 255))
        d.rounded_rectangle((x + 20, 580, x + 310, 640), radius=24, fill=(78, 86, 150, 255))
    d.rectangle((870, 38, 884, H), fill=(190, 196, 210, 255))
    for x in range(120, W, 260):
        d.line((x, 38, x, 120), fill=(190, 196, 210, 255), width=4)
        d.ellipse((x - 26, 112, x + 26, 164), outline=(220, 226, 238, 255), width=6)
    img = painterly(img.convert("RGB"), 0.8)
    save_bg(vignette(img, 0.5), "bus_rain")


def perspective_floor(d, horizon, vp_x, color_a, color_b, step=150):
    d.rectangle((0, horizon, W, H), fill=color_a)
    for i in range(-14, 15):
        x = vp_x + i * step
        d.line((vp_x + (x - vp_x) * 0.08, horizon, x * 1.0 + (x - vp_x) * 1.4, H), fill=color_b, width=2)
    y = horizon
    gap = 14.0
    while y < H:
        d.line((0, y, W, y), fill=color_b, width=2)
        y += gap
        gap *= 1.28


def cafeteria():
    img = gradient((W, H), (244, 232, 210), (226, 210, 184))
    d = ImageDraw.Draw(img)
    horizon, vp = 330, W // 2
    perspective_floor(d, horizon, vp, (196, 178, 150), (170, 150, 124), 160)
    # janelas à esquerda com pôr do sol
    for k in range(4):
        x0 = 30 + k * 170
        img.paste(gradient((130, 170), (255, 170, 110), (255, 226, 160)), (x0, 70))
        d.rectangle((x0, 70, x0 + 130, 240), outline=(100, 84, 70), width=6)
    # balcão ao fundo
    d.rectangle((470, 210, 1100, 330), fill=(150, 150, 160))
    d.rectangle((470, 210, 1100, 236), fill=(190, 192, 204))
    for i in range(8):
        d.rectangle((490 + i * 76, 256, 540 + i * 76, 316), fill=(210, 214, 224))
    d.rectangle((560, 130, 1010, 200), fill=(110, 110, 120))
    for i, c in enumerate([(220, 120, 90), (110, 170, 120), (230, 190, 90), (120, 160, 220)]):
        d.rectangle((590 + i * 105, 148, 660 + i * 105, 184), fill=c)
    # mesas compridas em perspectiva
    for row, (yy, sc) in enumerate([(380, 0.55), (470, 0.8), (600, 1.15)]):
        for col in (-1, 0, 1):
            cx = vp + col * 400 * sc
            hw, th = 230 * sc, 26 * sc
            quad(d, [(cx - hw, yy), (cx + hw, yy), (cx + hw * 1.05, yy + th), (cx - hw * 1.05, yy + th)], (210, 176, 128))
            quad(d, [(cx - hw * 1.05, yy + th), (cx + hw * 1.05, yy + th), (cx + hw * 1.05, yy + th + 18 * sc), (cx - hw * 1.05, yy + th + 18 * sc)], (140, 108, 80))
            bench = yy + th + 30 * sc
            d.rectangle((cx - hw * 0.95, bench, cx + hw * 0.95, bench + 14 * sc), fill=(120, 96, 80))
            d.rectangle((cx - hw * 0.8, yy + th + 18 * sc, cx - hw * 0.8 + 10 * sc, bench + 60 * sc), fill=(96, 76, 64))
            d.rectangle((cx + hw * 0.8, yy + th + 18 * sc, cx + hw * 0.8 + 10 * sc, bench + 60 * sc), fill=(96, 76, 64))
            # bandejas quentes e esquecidas
            for t in range(3):
                tx = cx - hw * 0.6 + t * hw * 0.6
                d.rectangle((tx, yy - 6 * sc, tx + 56 * sc, yy + 12 * sc), fill=(90, 110, 160))
                d.ellipse((tx + 8 * sc, yy - 4 * sc, tx + 28 * sc, yy + 6 * sc), fill=(245, 245, 235))
    img = painterly(img, 1.1)
    light = glow_layer((W, H), (200, 160), 300, (255, 170, 110), 0.5)
    img = ImageChops.add(img, light)
    save_bg(vignette(img, 0.45), "cafeteria")


def infirmary():
    img = gradient((W, H), (238, 242, 238), (214, 222, 216))
    d = ImageDraw.Draw(img)
    floor_y = int(H * 0.66)
    d.rectangle((0, floor_y, W, H), fill=(200, 208, 190))
    for x in range(0, W, 90):
        d.line((x, floor_y, x - 40 + (x - W / 2) * 0.1, H), fill=(180, 190, 172), width=2)
    d.rectangle((0, floor_y - 12, W, floor_y), fill=(160, 176, 160))
    # janela
    img.paste(gradient((300, 250), (190, 220, 250), (240, 248, 255)), (950, 110))
    d.rectangle((950, 110, 1250, 360), outline=(150, 160, 160), width=10)
    d.line((1100, 110, 1100, 360), fill=(150, 160, 160), width=6)
    # camas com cortina
    for bx in (120, 520):
        d.rounded_rectangle((bx, 370, bx + 330, 520), radius=10, fill=(236, 240, 244))
        d.rectangle((bx, 520, bx + 14, 590), fill=(150, 156, 160))
        d.rectangle((bx + 316, 520, bx + 330, 590), fill=(150, 156, 160))
        d.rounded_rectangle((bx + 14, 350, bx + 110, 400), radius=14, fill=(250, 250, 252))
        d.rounded_rectangle((bx + 10, 410, bx + 320, 500), radius=8, fill=(206, 226, 236))
    d.rectangle((420, 150, 440, 500), fill=(190, 200, 205))
    quad(d, [(300, 150), (470, 150), (470, 340), (300, 340)], (180, 214, 206))
    # armário com cruz
    d.rectangle((1010, 400, 1230, 600), fill=(242, 244, 246), outline=(160, 168, 172), width=4)
    d.line((1120, 400, 1120, 600), fill=(160, 168, 172), width=3)
    d.rectangle((1105, 430, 1135, 480), fill=(200, 50, 60))
    d.rectangle((1090, 445, 1150, 465), fill=(200, 50, 60))
    d.rectangle((1040, 330, 1200, 350), fill=(150, 160, 160))
    d.rectangle((1060, 290, 1090, 330), fill=(220, 120, 90))
    d.rectangle((1100, 280, 1128, 330), fill=(90, 160, 200))
    img = painterly(img, 1.1)
    img = ImageChops.add(img, glow_layer((W, H), (1100, 230), 260, (220, 235, 255), 0.45))
    save_bg(vignette(img, 0.4), "infirmary")


def gym():
    img = gradient((W, H), (210, 196, 170), (176, 160, 132))
    d = ImageDraw.Draw(img)
    horizon, vp = 360, W // 2
    # piso de madeira com linhas da quadra
    d.rectangle((0, horizon, W, H), fill=(196, 148, 92))
    for i in range(-16, 17):
        x = vp + i * 110
        d.line((vp + (x - vp) * 0.18, horizon, x + (x - vp) * 1.2, H), fill=(170, 124, 76), width=2)
    y, gap = horizon, 8.0
    while y < H:
        d.line((0, y, W, y), fill=(176, 130, 80), width=1)
        y += gap
        gap *= 1.12
    d.line((300, 470, 1076, 470), fill=(250, 248, 240), width=5)
    d.line((180, 640, 1196, 640), fill=(250, 248, 240), width=6)
    d.arc((480, 420, 900, 640), 180, 360, fill=(250, 248, 240), width=5)
    # parede de fundo, janelas altas e tabela de basquete
    d.rectangle((0, 0, W, horizon), fill=(220, 206, 180))
    for k in range(6):
        x0 = 60 + k * 220
        img.paste(gradient((150, 70), (255, 214, 150), (255, 240, 200)), (x0, 40))
        d.rectangle((x0, 40, x0 + 150, 110), outline=(120, 104, 90), width=5)
    d.rectangle((600, 150, 780, 250), fill=(245, 245, 240), outline=(90, 90, 100), width=6)
    d.rectangle((662, 196, 718, 238), outline=(220, 70, 50), width=5)
    d.ellipse((650, 236, 730, 262), outline=(230, 110, 50), width=6)
    # arquibancada dobrada à esquerda
    for r in range(4):
        d.rectangle((0, 250 + r * 26, 330 - r * 20, 276 + r * 26), fill=(150 - r * 8, 120 - r * 6, 90 - r * 4))
    # bolas e cones
    d.ellipse((980, 560, 1030, 610), fill=(230, 120, 50), outline=(90, 40, 20), width=3)
    d.ellipse((1060, 590, 1100, 630), fill=(230, 120, 50), outline=(90, 40, 20), width=3)
    quad(d, [(240, 560), (262, 560), (280, 620), (222, 620)], (240, 140, 40))
    img = painterly(img, 1.2)
    img = ImageChops.add(img, glow_layer((W, H), (690, 80), 360, (255, 210, 140), 0.45))
    save_bg(vignette(img, 0.5), "gym")


# ----------------------------------------------------------------- objetos (cartões)
CARD = (900, 620)


def card_base(size=CARD):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def with_shadow(img, offset=(10, 14), blur=16, alpha=150):
    w, h = img.size
    out = Image.new("RGBA", (w + 60, h + 60), (0, 0, 0, 0))
    shadow = Image.new("RGBA", out.size, (0, 0, 0, 0))
    alpha_mask = img.split()[3].point(lambda a: int(a * alpha / 255))
    shadow.paste((0, 0, 0, 255), (30 + offset[0], 30 + offset[1]), alpha_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    out = Image.alpha_composite(out, shadow)
    out.alpha_composite(img, (30, 30))
    return out


def paper(size, color, edge=(120, 100, 80), wobble=3):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for x in range(0, w + 1, 40):
        pts.append((x, rng.randint(0, wobble)))
    for y in range(0, h + 1, 40):
        pts.append((w - rng.randint(0, wobble), y))
    for x in range(w, -1, -40):
        pts.append((x, h - rng.randint(0, wobble)))
    for y in range(h, -1, -40):
        pts.append((rng.randint(0, wobble), y))
    d.polygon(pts, fill=color + (255,))
    # fibra do papel
    tex = Image.effect_noise(size, 12).convert("L").point(lambda v: 255 if v > 250 else 0)
    img.paste((255, 255, 255, 16), (0, 0), tex)
    return img


def text_on(img, xy, text, f, fill, blur=0.0):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(xy, text, font=f, fill=fill)
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(layer)


def polaroid(inner_size, tint=(250, 246, 236)):
    iw, ih = inner_size
    w, h = iw + 70, ih + 120
    card = Image.new("RGBA", (w, h), tint + (255,))
    ImageDraw.Draw(card).rectangle((0, 0, w - 1, h - 1), outline=(200, 194, 180, 255), width=2)
    return card, (35, 35)


def figure(d, cx, base_y, h, body, hair, skin=(244, 214, 190)):
    head = h * 0.22
    d.rounded_rectangle((cx - h * 0.2, base_y - h * 0.62, cx + h * 0.2, base_y), radius=int(h * 0.08), fill=body)
    d.ellipse((cx - head, base_y - h * 0.62 - head * 1.7, cx + head, base_y - h * 0.62 + head * 0.3), fill=skin)
    d.pieslice((cx - head * 1.1, base_y - h * 0.62 - head * 1.85, cx + head * 1.1, base_y - h * 0.62 + head * 0.1), 180, 360, fill=hair)


def make_bilhete():
    img = paper((640, 420), (238, 226, 196), wobble=5)
    d = ImageDraw.Draw(img)
    for x in (213, 426):   # dobras discretas
        d.line((x, 6, x, 414), fill=(206, 190, 160, 90), width=2)
    d.line((8, 210, 632, 210), fill=(206, 190, 160, 70), width=2)
    f = hand(46)
    text_on(img, (46, 70), "Volta.", f, (36, 40, 70, 255), 0.6)
    text_on(img, (46, 140), "A escola é chata", f, (36, 40, 70, 255), 1.4)
    text_on(img, (46, 210), "sem você.", f, (36, 40, 70, 255), 2.4)
    stain = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(stain).ellipse((330, 250, 560, 380), fill=(60, 50, 90, 70))
    img.alpha_composite(stain.filter(ImageFilter.GaussianBlur(22)))
    save_insert(with_shadow(img), "bilhete")


def make_notebook():
    w, h = 860, 560
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, w, h), radius=14, fill=(26, 24, 30, 255))
    left = paper((400, 520), (240, 234, 214), wobble=2)
    right = paper((400, 520), (236, 230, 210), wobble=6)
    f = hand(30)
    ink = (30, 40, 90, 255)
    lines = ["Dia 5", "Dia 6: acordei com as", "mãos machucadas de novo.", "Dia 7", "Dia 8: a porta do telhado", "estava aberta.",
             "Dia 11: não confia no", "dia bonito.", "Dia 12: não deixa ele", "subir sozinho."]
    for i, t in enumerate(lines):
        text_on(left, (30, 22 + i * 46), t, f, ink)
    for i in range(11):
        ImageDraw.Draw(left).line((20, 66 + i * 46, 380, 66 + i * 46), fill=(170, 190, 220, 90), width=1)
    # página direita rasgada e nome apagando
    rd = ImageDraw.Draw(right)
    for k in range(10):
        rd.polygon([(0, 20 + k * 52), (22, 36 + k * 52), (4, 52 + k * 52)], fill=(0, 0, 0, 0))
    name_f = hand(40)
    for i in range(7):
        a = int(255 * (1 - i / 7.0) ** 1.6)
        text_on(right, (40, 70 + i * 56), "Kaito Mori", name_f, (30, 40, 90, a), 0.5 + i * 0.5)
    img.alpha_composite(left, (20, 20))
    img.alpha_composite(right, (440, 20))
    d.rectangle((424, 10, 436, h - 10), fill=(10, 10, 14, 255))
    save_insert(with_shadow(img), "notebook")


def make_desk_km():
    w, h = 820, 470
    wood = gradient((w, h), (176, 126, 78), (150, 104, 62))
    d = ImageDraw.Draw(wood)
    for _ in range(150):
        y = rng.randint(0, h)
        d.line((0, y, w, y + rng.randint(-6, 6)), fill=(130 + rng.randint(-20, 20), 88, 52), width=rng.choice([1, 1, 2]))
    wood = noise(wood, 8)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=24, fill=255)
    img.paste(wood, (0, 0), mask)
    f = font("arialbd.ttf", 210)
    carve = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(carve).text((150, 100), "K.M.", font=f, fill=(70, 40, 22, 255))
    hi = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(hi).text((153, 103), "K.M.", font=f, fill=(255, 220, 170, 110))
    img.alpha_composite(hi)
    img.alpha_composite(carve)
    sd = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = rng.randint(40, w - 40), rng.randint(40, h - 40)
        sd.line((x, y, x + rng.randint(-60, 60), y + rng.randint(-14, 14)), fill=(96, 64, 38, 150), width=1)
    save_insert(with_shadow(img), "desk_km")


def make_clock():
    s = 520
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((4, 4, s - 4, s - 4), fill=(48, 44, 52, 255))
    d.ellipse((24, 24, s - 24, s - 24), fill=(246, 242, 232, 255))
    c = s / 2
    for i in range(60):
        a = math.radians(i * 6)
        r1 = s / 2 - 36
        r2 = r1 - (24 if i % 5 == 0 else 10)
        d.line((c + r1 * math.sin(a), c - r1 * math.cos(a), c + r2 * math.sin(a), c - r2 * math.cos(a)),
               fill=(40, 36, 44, 255), width=5 if i % 5 == 0 else 2)
    nf = font("arialbd.ttf", 40)
    for n in range(1, 13):
        a = math.radians(n * 30)
        r = s / 2 - 84
        d.text((c + r * math.sin(a), c - r * math.cos(a)), str(n), font=nf, fill=(40, 36, 44, 255), anchor="mm")
    # 9h47: ponteiro das horas em 9 + 47/60
    ha = math.radians((9 + 47 / 60) * 30)
    ma = math.radians(47 * 6)
    d.line((c, c, c + 120 * math.sin(ha), c - 120 * math.cos(ha)), fill=(30, 28, 36, 255), width=14)
    d.line((c, c, c + 190 * math.sin(ma), c - 190 * math.cos(ma)), fill=(30, 28, 36, 255), width=8)
    d.ellipse((c - 14, c - 14, c + 14, c + 14), fill=(200, 40, 50, 255))
    # rachadura e brilho
    d.line((s * 0.66, s * 0.12, s * 0.58, s * 0.3, s * 0.64, s * 0.42), fill=(60, 60, 70, 150), width=2)
    save_insert(with_shadow(img), "clock_2147")


def make_photo_class():
    card, off = polaroid((760, 480))
    img = Image.new("RGBA", (760, 480), (0, 0, 0, 0))
    scene = gradient((760, 480), (172, 196, 220), (206, 214, 186)).convert("RGBA")
    img.alpha_composite(scene)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 330, 760, 480), fill=(150, 162, 130, 255))
    d.rectangle((250, 40, 510, 100), fill=(240, 240, 232, 255), outline=(90, 90, 100, 255), width=3)
    d.text((380, 70), "2 - B", font=font("arialbd.ttf", 34), fill=(60, 60, 80, 255), anchor="mm")
    hair = [(40, 30, 30), (90, 60, 40), (30, 30, 50), (150, 90, 50), (200, 140, 70), (50, 40, 60)]
    body = (60, 70, 110)
    for row, (y, h, n) in enumerate([(205, 120, 10), (285, 150, 8), (375, 190, 6)]):
        for i in range(n):
            cx = 60 + (i + 0.5) * (640 / n) + rng.randint(-10, 10)
            figure(d, cx, y + h * 0.35, h, body if (i + row) % 2 else (210, 214, 224), rng.choice(hair))
    # o protagonista (fileira de trás) e o rosto sobreposto ao lado
    px = 470
    figure(d, px, 205 + 120 * 0.35, 120, (80, 110, 170), (40, 40, 60))
    ghost = Image.new("RGBA", (760, 480), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ghost)
    for k in range(7):
        figure(gd, 530 + k * 3, 205 + 120 * 0.35, 120, (120, 120, 130), (60, 50, 50), skin=(220, 205, 205))
    ghost = ghost.filter(ImageFilter.GaussianBlur(5)).point(lambda v: int(v * 0.5) if False else v)
    ghost.putalpha(ghost.split()[3].point(lambda a: int(a * 0.28)))
    img.alpha_composite(ghost)
    card.alpha_composite(img, off)
    text_on(card, (40, 560), "turma 2-B", hand(34), (70, 60, 60, 255))
    save_insert(with_shadow(card.rotate(-2, expand=True, resample=Image.BICUBIC)), "photo_class")


def make_photo_kids():
    card, off = polaroid((700, 440), (244, 236, 218))
    img = Image.new("RGBA", (700, 440), (0, 0, 0, 0))
    img.alpha_composite(gradient((700, 440), (60, 40, 90), (150, 90, 80)).convert("RGBA"))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 340, 700, 440), fill=(60, 52, 60, 255))
    for k, (cx, hair, body) in enumerate([(170, (60, 40, 40), (230, 120, 130)), (350, (230, 130, 40), (240, 200, 90)), (530, (50, 50, 70), (90, 150, 210))]):
        figure(d, cx, 420, 250, body, hair)
        lx, ly = cx + (50 if k != 1 else 0), 250
        d.line((cx + 20, 330, lx, ly + 40), fill=(40, 30, 30, 255), width=3)
        d.ellipse((lx - 46, ly - 52, lx + 46, ly + 52), fill=(255, 180, 90, 255), outline=(150, 50, 40, 255), width=4)
        d.ellipse((lx - 30, ly - 38, lx + 30, ly + 38), fill=(255, 224, 150, 255))
    # rosto da direita riscado com força, até rasgar
    sd = ImageDraw.Draw(img)
    for _ in range(40):
        x, y = 530 + rng.randint(-46, 40), 120 + rng.randint(-10, 80)
        sd.line((x, y, x + rng.randint(-50, 50), y + rng.randint(-40, 40)), fill=(10, 10, 12, 255), width=rng.choice([4, 5, 6]))
    sd.polygon([(500, 130), (530, 150), (512, 170), (540, 190), (520, 208), (498, 180)], fill=(30, 22, 28, 255))
    card.alpha_composite(img, off)
    text_on(card, (40, 540), "festival, 8 anos", hand(32), (70, 60, 60, 255))
    save_insert(with_shadow(card.rotate(2, expand=True, resample=Image.BICUBIC)), "photo_kids")


def make_yearbook():
    w, h = 760, 560
    img = paper((w, h), (246, 240, 224), wobble=2)
    d = ImageDraw.Draw(img)
    d.text((w / 2, 40), "Anuário — turma 2-B", font=font("arialbd.ttf", 34), fill=(70, 60, 90, 255), anchor="mm")
    cols, rows = 6, 3
    k = 0
    for r in range(rows):
        for c in range(cols):
            x0, y0 = 40 + c * 118, 90 + r * 150
            k += 1
            if (r, c) == (1, 2):
                # recorte limpo, feito com régua
                d.rectangle((x0, y0, x0 + 100, y0 + 120), fill=(210, 206, 196, 255))
                d.line((x0, y0, x0, y0 + 120), fill=(120, 110, 100, 255), width=2)
                continue
            skin = (240, 210, 186)
            d.rectangle((x0, y0, x0 + 100, y0 + 120), fill=(188, 200, 224, 255))
            d.ellipse((x0 + 28, y0 + 24, x0 + 72, y0 + 76), fill=skin + (255,))
            d.pieslice((x0 + 24, y0 + 16, x0 + 76, y0 + 66), 180, 360, fill=rng.choice([(50, 40, 40), (110, 70, 40), (30, 30, 50)]) + (255,))
            d.rounded_rectangle((x0 + 14, y0 + 82, x0 + 86, y0 + 130), radius=12, fill=(70, 80, 120, 255))
            d.text((x0 + 50, y0 + 138), "nome %02d" % k, font=font("arial.ttf", 13), fill=(80, 80, 90, 255), anchor="mm")
    d.line((20, 280, w - 20, 280), fill=(90, 90, 100, 90), width=2)
    save_insert(with_shadow(img), "yearbook")


def make_roster():
    w, h = 880, 560
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    names = ["Abe", "Arai", "Baba", "Endo", "Fuji", "Goto", "Hara", "Ito", "Kato", "Kimura", "Mori", "Noda", "Ono", "Sato", "Tada", "Ueda", "Wada", "Yano"]
    f = hand(26)
    for side, label in enumerate(("há um mês (cópia)", "lista oficial de hoje")):
        sheet = paper((410, 520), (244, 240, 226), wobble=3)
        sd = ImageDraw.Draw(sheet)
        sd.text((205, 26), label, font=font("arialbd.ttf", 22), fill=(60, 60, 90, 255), anchor="mm")
        y = 64
        num = 1
        for i in range(15):
            if side == 1 and num == 14:
                num += 1  # a numeração pula do 13 para o 15
            if side == 0 and num == 14:
                text_on(sheet, (30, y), "14  Kaito Mori", f, (30, 40, 110, 255))
            else:
                text_on(sheet, (30, y), "%d  %s" % (num, names[(num - 1) % len(names)]), f, (60, 60, 70, 255))
            y += 30
            num += 1
        img.alpha_composite(sheet, (20 + side * 430, 20))
    save_insert(with_shadow(img), "roster")


def make_stopwatch():
    w, h = 640, 520
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((60, 40, 580, 480), radius=70, fill=(46, 52, 64, 255), outline=(140, 150, 170, 255), width=6)
    d.rectangle((290, 0, 350, 46), fill=(120, 126, 140, 255))
    d.rounded_rectangle((110, 110, 530, 360), radius=22, fill=(150, 176, 140, 255))
    seg = font("consolab.ttf", 86)
    d.text((510, 170), "13.02", font=seg, fill=(32, 48, 32, 255), anchor="ra")
    d.text((510, 270), "12.08", font=seg, fill=(32, 48, 32, 200), anchor="ra")
    d.text((124, 124), "SPLIT", font=font("arialbd.ttf", 20), fill=(32, 48, 32, 255))
    d.ellipse((110, 390, 190, 460), fill=(200, 60, 60, 255))
    d.ellipse((450, 390, 530, 460), fill=(80, 150, 90, 255))
    save_insert(with_shadow(img), "stopwatch")


def make_lunchboxes():
    w, h = 880, 480
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k, x0 in enumerate((20, 460)):
        d.rounded_rectangle((x0, 60, x0 + 400, 420), radius=34, fill=(224, 96, 120, 255) if k == 0 else (90, 140, 210, 255))
        d.rounded_rectangle((x0 + 24, 84, x0 + 376, 396), radius=22, fill=(250, 246, 236, 255))
        d.line((x0 + 200, 84, x0 + 200, 396), fill=(210, 204, 190, 255), width=4)
        # arroz em formato de coelho (esquerda) ou arroz simples (direita)
        d.ellipse((x0 + 50, 190, x0 + 180, 320), fill=(255, 255, 255, 255), outline=(200, 196, 186, 255), width=3)
        if k == 0:
            d.ellipse((x0 + 66, 100, x0 + 100, 200), fill=(255, 255, 255, 255), outline=(200, 196, 186, 255), width=3)
            d.ellipse((x0 + 120, 100, x0 + 154, 200), fill=(255, 255, 255, 255), outline=(200, 196, 186, 255), width=3)
            d.ellipse((x0 + 86, 238, x0 + 100, 252), fill=(40, 30, 30, 255))
            d.ellipse((x0 + 130, 238, x0 + 144, 252), fill=(40, 30, 30, 255))
            d.ellipse((x0 + 106, 268, x0 + 124, 280), fill=(240, 130, 150, 255))
        d.ellipse((x0 + 220, 110, x0 + 270, 160), fill=(240, 130, 50, 255))
        d.ellipse((x0 + 290, 120, x0 + 350, 170), fill=(100, 170, 80, 255))
        d.rounded_rectangle((x0 + 224, 210, x0 + 360, 260), radius=14, fill=(210, 120, 90, 255))
        d.rounded_rectangle((x0 + 224, 290, x0 + 330, 360), radius=20, fill=(120, 150, 90, 255))
        if k == 0:
            d.rounded_rectangle((x0 + 330, 290, x0 + 370, 360), radius=14, fill=(250, 220, 90, 255))  # ovo
    save_insert(with_shadow(img), "lunchboxes")


def make_white_lantern():
    s = 560
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy, w, h = s // 2, s // 2 + 10, 150, 190
    d.line((cx, 20, cx, cy - h - 20), fill=(80, 70, 70, 255), width=5)
    d.rounded_rectangle((cx - 60, cy - h - 30, cx + 60, cy - h + 14), radius=10, fill=(70, 60, 62, 255))
    d.ellipse((cx - w, cy - h + 6, cx + w, cy + h - 6), fill=(246, 244, 238, 255), outline=(190, 186, 176, 255), width=5)
    inner = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(inner).ellipse((cx - w * 0.6, cy - h * 0.6, cx + w * 0.6, cy + h * 0.6), fill=(255, 255, 255, 90))
    img.alpha_composite(inner.filter(ImageFilter.GaussianBlur(14)))
    d = ImageDraw.Draw(img)
    for k in range(-3, 4):
        yy = cy + k * (h / 3.6)
        half = w * math.sqrt(max(0.0, 1 - ((yy - cy) / h) ** 2))
        d.line((cx - half, yy, cx + half, yy), fill=(196, 192, 182, 255), width=3)
    d.rounded_rectangle((cx - 60, cy + h - 14, cx + 60, cy + h + 30), radius=10, fill=(70, 60, 62, 255))
    d.line((cx, cy + h + 30, cx, cy + h + 100), fill=(226, 190, 100, 255), width=5)
    for off in (-18, 0, 18):
        d.line((cx, cy + h + 90, cx + off, cy + h + 150), fill=(226, 190, 100, 255), width=4)
    save_insert(with_shadow(img), "white_lantern")


def make_wall_nao_suba():
    w, h = 880, 520
    wall = gradient((w, h), (150, 146, 140), (118, 114, 108))
    wall = noise(wall, 18)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=12, fill=255)
    img.paste(wall, (0, 0), mask)
    d = ImageDraw.Draw(img)
    for _ in range(40):   # fissuras e manchas
        x, y = rng.randint(0, w), rng.randint(0, h)
        d.line((x, y, x + rng.randint(-80, 80), y + rng.randint(20, 120)), fill=(80, 76, 72, 120), width=2)
    f = font("arialbd.ttf", 150)
    gouge = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gouge)
    gd.text((w / 2, h / 2 - 20), "NÃO SUBA", font=f, fill=(48, 44, 42, 255), anchor="mm")
    # raspado: tira textura de riscos horizontais por dentro das letras
    for _ in range(420):
        y = rng.randint(80, h - 60)
        x = rng.randint(20, w - 120)
        gd.line((x, y, x + rng.randint(30, 120), y + rng.randint(-3, 3)), fill=(150, 144, 138, 120), width=1)
    img.alpha_composite(gouge)
    dust = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(dust).rectangle((0, h - 70, w, h), fill=(200, 196, 188, 90))
    img.alpha_composite(dust.filter(ImageFilter.GaussianBlur(20)))
    save_insert(with_shadow(img), "wall_nao_suba")


if __name__ == "__main__":
    bedroom(False)
    bedroom(True)
    bus_rain()
    cafeteria()
    infirmary()
    gym()
    make_bilhete()
    make_notebook()
    make_desk_km()
    make_clock()
    make_photo_class()
    make_photo_kids()
    make_yearbook()
    make_roster()
    make_stopwatch()
    make_lunchboxes()
    make_white_lantern()
    make_wall_nao_suba()
    print("pronto")
