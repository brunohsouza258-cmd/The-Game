#!/usr/bin/env python3
"""Valida os JSONs de diálogo: nós 'start', referências 'next' e assets.

Uso: python tools/validate_data.py   (a partir de qualquer pasta)
Sai com código 1 se encontrar problemas.
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def res_exists(path):
    if "/gutari/" in path or "/kyuririn/" in path:
        return True  # opcional: o pacote do Gutari não está no repositório (há plano B no jogo)
    return os.path.exists(os.path.join(ROOT, path.replace("res://", "")))


def main():
    errors = []
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "dialogue", "*.json"))):
        name = os.path.relpath(f, ROOT)
        try:
            with open(f, encoding="utf-8") as fh:
                d = json.load(fh)
        except ValueError as e:
            errors.append(f"{name}: JSON inválido ({e})")
            continue
        nodes = d.get("nodes", {})
        if "start" not in nodes:
            errors.append(f"{name}: sem nó 'start'")
        for key in ("background", "sprite"):
            if d.get(key) and not res_exists(d[key]):
                errors.append(f"{name}: {key} inexistente: {d[key]}")
        for nid, node in nodes.items():
            for key in ("sprite", "partner", "background", "image"):
                if node.get(key) and not res_exists(node[key]):
                    errors.append(f"{name}: nó '{nid}' com {key} inexistente: {node[key]}")
            targets = [node.get("next")] + [c.get("next") for c in node.get("choices", [])]
            for t in targets:
                if t and t not in nodes:
                    errors.append(f"{name}: nó '{nid}' aponta para '{t}' inexistente")
            if not node.get("end") and not node.get("next") and not node.get("choices"):
                errors.append(f"{name}: nó '{nid}' é um beco sem saída")
    ending_file = os.path.join(ROOT, "data", "endings", "endings.json")
    with open(ending_file, encoding="utf-8") as fh:
        for eid, e in json.load(fh).get("endings", {}).items():
            if e.get("background") and not res_exists(e["background"]):
                errors.append(f"endings.json: '{eid}' com background inexistente")
    for e in errors:
        print("ERRO:", e)
    print("OK" if not errors else f"{len(errors)} problema(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
