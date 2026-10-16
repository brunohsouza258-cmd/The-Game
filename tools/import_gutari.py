#!/usr/bin/env python3
"""Importa cenários do pacote "Japanese High School Backgrounds" (Gutari Nyanko).

Uso: python tools/import_gutari.py "C:/caminho/GutariSchool.zip"

O pacote NÃO está neste repositório (os termos de redistribuição do autor não são claros);
cada pessoa baixa o zip em https://neeka.itch.io/japanese-high-school-backgrounds e roda este
script. Ele recorta (4:3 -> 16:9), amplia para 1376x768 e grava em assets/backgrounds/gutari/
(pasta ignorada pelo git). Sem esses arquivos o jogo usa cenários alternativos (VNScene.gd).

Crédito obrigatório: "Gutari Nyanko" (já está nos créditos do jogo).
"""
import os
import random
import sys
import zipfile

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "backgrounds", "gutari")
W, H = 1376, 768

# nome no jogo -> arquivo no zip
MAP = {
    "cafeteria": "gakusyoku00-studio.jpg",
    "infirmary": "hokensitu00-studio.jpg",
    "gym": "taiikukan00-studio.jpg",
    "rooftop_dusk": "okujyou002ev-studio.jpg",
    "rooftop_rain": "okujyou002night-studio.jpg",   # + chuva
    "rooftop_door": "okujyou_door000-studio.jpg",
    "corridor_night": "rouka000night0-studio.jpg",
    "toilet": "toilet000-studio.jpg",
    "school_gate": "koumon00-studio.jpg",
    "staff_room": "syokuin_room_exit000-studio.jpg",
    "music_room": "ongakusitu000-studio.jpg",
    "festival_stalls": "yomise02-studio.jpg",
    "track": "undoujyou00-studio.jpg",
    "classroom_night": "kyousitu_night_0-studio.jpg",
}


def fit(img):
    """Recorta para 16:9 mantendo o centro e amplia com nitidez e um grão leve."""
    w, h = img.size
    target_h = int(w * 9 / 16)
    top = max(0, (h - target_h) // 2)
    img = img.crop((0, top, w, top + target_h)).resize((W, H), Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2))
    grain = Image.effect_noise(img.size, 7).convert("RGB")
    return ImageChops.add(img, grain, scale=1.0, offset=-128)


def add_rain(img, seed=11):
    rng = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(950):
        x, y = rng.randint(0, W), rng.randint(0, H)
        d.line((x, y, x - 6, y + rng.randint(18, 30)), fill=(210, 222, 255, rng.randint(40, 120)), width=1)
    out = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")
    return ImageEnhance.Brightness(out).enhance(0.85)


def main():
    if len(sys.argv) < 2 or not os.path.exists(sys.argv[1]):
        sys.exit("Uso: python tools/import_gutari.py caminho/GutariSchool.zip")
    os.makedirs(OUT, exist_ok=True)
    with zipfile.ZipFile(sys.argv[1]) as z:
        names = {os.path.basename(n): n for n in z.namelist() if n.lower().endswith(".jpg")}
        for game_name, src in MAP.items():
            if src not in names:
                print("faltando no zip:", src)
                continue
            with z.open(names[src]) as f:
                img = Image.open(f).convert("RGB")
            img = fit(img)
            if game_name == "rooftop_rain":
                img = add_rain(img)
            img.save(os.path.join(OUT, game_name + ".png"))
            print("ok:", game_name)


if __name__ == "__main__":
    main()
