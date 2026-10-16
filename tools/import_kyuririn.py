#!/usr/bin/env python3
"""Importa cenários do pacote "Visual Novel Backgrounds" (Kyuririn).

Uso: python tools/import_kyuririn.py "C:/caminho/da/pasta/Backgrounds"   (ou o Backgrounds.zip)

Baixe em https://kyuririn.itch.io/visual-novel-backgrounds (uso pessoal e comercial; crédito
apreciado). Como no pacote do Gutari, as imagens NÃO vão para o repositório: ficam em
assets/backgrounds/kyuririn/ (ignorado pelo git) e o jogo usa cenários alternativos sem elas.
"""
import io
import os
import sys
import zipfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "backgrounds", "kyuririn")
W, H = 1376, 768

MAP = {
    "bedroom_morning": "BedroomMorning.png",
    "bedroom_afternoon": "BedroomAfternoon.png",
    "bedroom_night": "BedroomNight.png",
    "kitchen_morning": "03Kitchen_Morning.png",
    "kitchen_dawn": "02Kitchen_Early_Morning.png",
    "kitchen_night": "06Kitchen_Night.png",
}


def sources(path):
    if os.path.isdir(path):
        for root, _, files in os.walk(path):
            for f in files:
                yield f, lambda r=root, f=f: open(os.path.join(r, f), "rb").read()
    else:
        z = zipfile.ZipFile(path)
        for n in z.namelist():
            yield os.path.basename(n), lambda n=n: z.read(n)


def main():
    if len(sys.argv) < 2 or not os.path.exists(sys.argv[1]):
        sys.exit("Uso: python tools/import_kyuririn.py pasta_ou_zip_do_pacote")
    os.makedirs(OUT, exist_ok=True)
    found = {name: reader for name, reader in sources(sys.argv[1]) if name}
    for game_name, src in MAP.items():
        if src not in found:
            print("faltando:", src)
            continue
        img = Image.open(io.BytesIO(found[src]())).convert("RGB").resize((W, H), Image.LANCZOS)
        img.save(os.path.join(OUT, game_name + ".png"))
        print("ok:", game_name)


if __name__ == "__main__":
    main()
