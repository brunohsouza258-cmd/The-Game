#!/usr/bin/env python3
"""Confere a tradução em inglês: todo nó com texto (e toda opção) dos diálogos tem versão em
data/i18n/en/, e os marcadores como {player_name} continuam iguais.

Uso: python tools/check_translation.py   (sai com código 1 se faltar algo)
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN = os.path.join(ROOT, "data", "i18n", "en")
TAG = re.compile(r"\{[a-z_]+\}")


def main():
    overlay = {}
    for f in glob.glob(os.path.join(EN, "dialogue_*.json")):
        with open(f, encoding="utf-8") as fh:
            overlay.update(json.load(fh))
    problems = []
    total = 0
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "dialogue", "*.json"))):
        with open(f, encoding="utf-8") as fh:
            d = json.load(fh)
        did = d["id"]
        tr = overlay.get(did)
        if tr is None:
            problems.append(f"{did}: sem tradução")
            continue
        for nid, node in d["nodes"].items():
            if not node.get("text"):
                continue
            total += 1
            t = tr.get(nid)
            if t is None or not t.get("text"):
                problems.append(f"{did}/{nid}: texto sem tradução")
                continue
            if sorted(TAG.findall(node["text"])) != sorted(TAG.findall(t["text"])):
                problems.append(f"{did}/{nid}: marcadores diferentes")
            n_choices = len(node.get("choices", []))
            if n_choices and len(t.get("choices", [])) != n_choices:
                problems.append(f"{did}/{nid}: {n_choices} opções, {len(t.get('choices', []))} traduzidas")
    for p in problems:
        print("FALTA:", p)
    print(f"{total} falas conferidas, {len(problems)} problema(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
