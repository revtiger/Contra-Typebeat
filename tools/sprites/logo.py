"""Letras de logo cinceladas en relieve, al estilo del título de Metal Slug 2:
cursiva, cara con degradado, bisel (luz arriba-izquierda, sombra abajo-derecha), profundidad 3D
extruida hacia abajo-derecha y contorno negro.

Estilos (una fila por estilo en assets/sprites/logo_font.png):
  big_stone  - grande, piedra/bronce (las letras que van cayendo en la intro)
  big_gold   - grande, oro (el fogonazo final a color y el menú)
  small_steel - pequeña, acero (títulos de pantallas: ELIGE TU SOLDADO...)
  small_gold  - pequeña, oro

Uso:  python tools/sprites/logo.py  ->  assets/sprites/logo_font.png + logo_font_meta.json
"""
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from font import G  # noqa: E402  (mismos glifos de 5x7 que la fuente del HUD)
from px import canvas, outline, preview  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "preview")

CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZÑ0123456789!-.&| "
PALETTES = {
    "stone": {"face": [(218, 206, 178), (190, 174, 142), (160, 144, 112), (126, 112, 86)],
              "hi": (244, 238, 218), "sh": (86, 72, 52), "ext": [(104, 88, 64), (62, 52, 38)], "noise": True},
    "gold": {"face": [(255, 250, 176), (255, 216, 64), (250, 162, 32), (222, 92, 22)],
             "hi": (255, 255, 232), "sh": (150, 50, 12), "ext": [(128, 44, 12), (70, 22, 8)], "noise": False},
    "steel": {"face": [(236, 240, 246), (196, 202, 212), (154, 160, 172), (112, 118, 130)],
              "hi": (255, 255, 255), "sh": (58, 62, 74), "ext": [(72, 76, 90), (38, 40, 50)], "noise": False},
}
STYLES = {
    "big_stone": {"scale": 6, "depth": 5, "pal": "stone"},
    "big_gold": {"scale": 6, "depth": 5, "pal": "gold"},
    "small_steel": {"scale": 3, "depth": 3, "pal": "steel"},
    "small_gold": {"scale": 3, "depth": 3, "pal": "gold"},
}
SHEAR = 0.22


def face_mask(ch, s):
    """Máscara de la cara de la letra, escalada y en cursiva."""
    rows = G[ch]
    h = 7 * s
    mask = set()
    for cy in range(7):
        for cx in range(5):
            if rows[cy][cx] != "X":
                continue
            for py in range(s):
                y = cy * s + py
                off = int((h - y) * SHEAR)
                for px in range(s):
                    mask.add((cx * s + px + off, y))
    return mask


def glyph(ch, style):
    st = STYLES[style]
    s, depth = st["scale"], st["depth"]
    pal = PALETTES[st["pal"]]
    h = 7 * s
    w = 5 * s + int(h * SHEAR) + depth + 3
    img = canvas(w, h + depth + 3)
    if ch == " ":
        return img
    mask = face_mask(ch, s)
    ox, oy = 1, 1
    # profundidad 3D: copias desplazadas cada vez más oscuras
    for k in range(depth, 0, -1):
        t = (k - 1) / max(depth - 1, 1)
        c = tuple(int(pal["ext"][0][i] * (1 - t) + pal["ext"][1][i] * t) for i in range(3))
        for (x, y) in mask:
            img.putpixel((x + ox + k, y + oy + k), c + (255,))
    # cara con degradado vertical
    rnd = random.Random(ord(ch))
    faces = pal["face"]
    for (x, y) in mask:
        col = faces[min(len(faces) - 1, y * len(faces) // h)]
        if pal["noise"] and rnd.random() < 0.12:
            col = tuple(max(0, v - 22) for v in col)
        img.putpixel((x + ox, y + oy), col + (255,))
    # bisel: bordes superiores/izquierdos claros, inferiores/derechos oscuros (2 px en letras grandes)
    bev = 2 if s >= 5 else 1
    for (x, y) in mask:
        for d in range(1, bev + 1):
            if (x, y - d) not in mask or (x - d, y) not in mask:
                img.putpixel((x + ox, y + oy), pal["hi"] + (255,))
                break
            if (x, y + d) not in mask or (x + d, y) not in mask:
                img.putpixel((x + ox, y + oy), pal["sh"] + (255,))
                break
    return outline(img)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    meta = {"chars": CHARS, "styles": {}}
    y = 0
    cells = {}
    for style, st in STYLES.items():
        g = glyph("A", style)
        cells[style] = (g.width, g.height)
        s = st["scale"]
        meta["styles"][style] = {"y": y, "w": g.width, "h": g.height, "advance": 5 * s + s // 2 + 1,
                                 "space": 3 * s, "face_h": 7 * s}
        y += g.height
    width = max(c[0] for c in cells.values()) * len(CHARS)
    img = canvas(width, y)
    for style in STYLES:
        cw, _ = cells[style]
        yy = meta["styles"][style]["y"]
        for i, ch in enumerate(CHARS):
            g = glyph(ch, style)
            img.paste(g, (i * cw, yy), g)
    img.save(os.path.join(OUT, "logo_font.png"))
    with open(os.path.join(OUT, "logo_font_meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)

    # vista previa: la palabra CONTRA en cada estilo
    demo = canvas(420, y + 20)
    yy = 0
    for style in STYLES:
        st = meta["styles"][style]
        x = 4
        for ch in "CONTRA":
            i = CHARS.index(ch)
            g = img.crop((i * st["w"], st["y"], (i + 1) * st["w"], st["y"] + st["h"]))
            demo.paste(g, (x, yy), g)
            x += st["advance"]
        yy += st["h"] + 4
    preview(demo, 2, os.path.join(PREV, "logo.png"), bg=(40, 60, 120))
    print("ok logo", img.size)
