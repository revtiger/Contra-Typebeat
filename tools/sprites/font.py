"""Genera la fuente pixelada del HUD al estilo Metal Slug (letras con degradado y contorno negro).

Estilos (una fila por estilo en assets/sprites/font.png):
  small  - dorado (amarillo -> naranja), para valores, puntuación y énfasis
  white  - blanco, para el texto normal (historia, controles, instrucciones)
  label  - blanco -> azul claro, para las etiquetas (ARMS, BOMB, 1UP)
  title  - grande, amarillo -> rojo, para "MISION 1 START!", "MISION COMPLETE!"
  metal  - números grandes cromados, para TIME

Uso:  python tools/sprites/font.py   ->  assets/sprites/font.png + font_meta.json
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from px import canvas, outline, preview  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "preview")

# Glifos de 5x7 (X = píxel encendido)
G = {
    "A": [".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
    "C": [".XXX.", "X...X", "X....", "X....", "X....", "X...X", ".XXX."],
    "D": ["XXXX.", "X...X", "X...X", "X...X", "X...X", "X...X", "XXXX."],
    "E": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX"],
    "F": ["XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "X...."],
    "G": [".XXX.", "X...X", "X....", "X.XXX", "X...X", "X...X", ".XXXX"],
    "H": ["X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X"],
    "I": [".XXX.", "..X..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "J": ["..XXX", "...X.", "...X.", "...X.", "...X.", "X..X.", ".XX.."],
    "K": ["X...X", "X..X.", "X.X..", "XX...", "X.X..", "X..X.", "X...X"],
    "L": ["X....", "X....", "X....", "X....", "X....", "X....", "XXXXX"],
    "M": ["X...X", "XX.XX", "X.X.X", "X.X.X", "X...X", "X...X", "X...X"],
    "N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
    "O": [".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "P": ["XXXX.", "X...X", "X...X", "XXXX.", "X....", "X....", "X...."],
    "Q": [".XXX.", "X...X", "X...X", "X...X", "X.X.X", "X..X.", ".XX.X"],
    "R": ["XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X"],
    "S": [".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX."],
    "T": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.."],
    "U": ["X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX."],
    "V": ["X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.."],
    "W": ["X...X", "X...X", "X...X", "X.X.X", "X.X.X", "XX.XX", "X...X"],
    "X": ["X...X", "X...X", ".X.X.", "..X..", ".X.X.", "X...X", "X...X"],
    "Y": ["X...X", "X...X", ".X.X.", "..X..", "..X..", "..X..", "..X.."],
    "Z": ["XXXXX", "....X", "...X.", "..X..", ".X...", "X....", "XXXXX"],
    "0": [".XXX.", "X...X", "X..XX", "X.X.X", "XX..X", "X...X", ".XXX."],
    "1": ["..X..", ".XX..", "..X..", "..X..", "..X..", "..X..", ".XXX."],
    "2": [".XXX.", "X...X", "....X", "...X.", "..X..", ".X...", "XXXXX"],
    "3": ["XXXX.", "....X", "....X", ".XXX.", "....X", "....X", "XXXX."],
    "4": ["...X.", "..XX.", ".X.X.", "X..X.", "XXXXX", "...X.", "...X."],
    "5": ["XXXXX", "X....", "XXXX.", "....X", "....X", "X...X", ".XXX."],
    "6": [".XXX.", "X....", "X....", "XXXX.", "X...X", "X...X", ".XXX."],
    "7": ["XXXXX", "....X", "...X.", "..X..", ".X...", ".X...", ".X..."],
    "8": [".XXX.", "X...X", "X...X", ".XXX.", "X...X", "X...X", ".XXX."],
    "9": [".XXX.", "X...X", "X...X", ".XXXX", "....X", "....X", ".XXX."],
    "!": ["..X..", "..X..", "..X..", "..X..", "..X..", ".....", "..X.."],
    "Ñ": [".XXX.", ".....", "X...X", "XX..X", "X.X.X", "X..XX", "X...X"],
    "&": [".XX..", "X..X.", "X.X..", ".X...", "X.X.X", "X..X.", ".XX.X"],
    "|": ["..X..", ".....", "..X..", "..X..", "..X..", "..X..", "..X.."],  # ¡
    "^": ["..X..", ".....", "..X..", ".X...", "X....", "X...X", ".XXX."],  # ¿
    "?": [".XXX.", "X...X", "....X", "...X.", "..X..", ".....", "..X.."],
    ".": [".....", ".....", ".....", ".....", ".....", ".....", "..X.."],
    ",": [".....", ".....", ".....", ".....", ".....", "..X..", ".X..."],
    ":": [".....", "..X..", ".....", ".....", ".....", "..X..", "....."],
    "-": [".....", ".....", ".....", "XXXXX", ".....", ".....", "....."],
    "=": [".....", ".....", "XXXXX", ".....", "XXXXX", ".....", "....."],
    "'": ["..X..", "..X..", ".....", ".....", ".....", ".....", "....."],
    "/": ["....X", "....X", "...X.", "..X..", ".X...", "X....", "X...."],
    "+": [".....", "..X..", "..X..", "XXXXX", "..X..", "..X..", "....."],
    "%": ["XX..X", "XX..X", "...X.", "..X..", ".X...", "X..XX", "X..XX"],
    "*": [".....", "X.X.X", ".XXX.", "XXXXX", ".XXX.", "X.X.X", "....."],
    "#": [".X.X.", "XXXXX", ".X.X.", ".X.X.", ".X.X.", "XXXXX", ".X.X."],
    "~": [".....", ".....", "XX.XX", "X.X.X", "XX.XX", ".....", "....."],  # infinito
    "<": [".....", ".X.X.", "XXXXX", "XXXXX", ".XXX.", "..X..", "....."],  # corazón
    " ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
}
CHARS = "".join(G.keys())

STYLES = {
    "small": {"scale": 1, "colors": [(255, 250, 180), (255, 224, 90), (255, 184, 40), (246, 132, 24), (220, 84, 16)]},
    "white": {"scale": 1, "colors": [(255, 255, 255), (250, 248, 240), (232, 228, 216), (210, 204, 190), (186, 178, 164)]},
    "label": {"scale": 1, "colors": [(255, 255, 255), (220, 240, 255), (170, 210, 255), (120, 170, 240), (90, 130, 220)]},
    "title": {"scale": 2, "colors": [(255, 250, 160), (255, 220, 60), (255, 168, 30), (244, 100, 20), (210, 40, 20)]},
    "metal": {"scale": 3, "colors": [(255, 255, 255), (220, 224, 232), (150, 156, 170), (90, 96, 112), (190, 196, 210)]},
}


def glyph(ch, style):
    st = STYLES[style]
    s = st["scale"]
    rows = G[ch]
    w, h = 5 * s + 2, 7 * s + 3
    img = canvas(w, h)
    cols = st["colors"]
    for y in range(7 * s):
        col = cols[min(len(cols) - 1, y * len(cols) // (7 * s))]
        for x in range(5 * s):
            if rows[y // s][x // s] == "X":
                img.putpixel((x + 1, y + 1), col + (255,))
    img = outline(img)
    # sombra dura abajo a la derecha, como en los arcade
    shadow = canvas(w, h)
    for y in range(h - 1):
        for x in range(w - 1):
            if img.getpixel((x, y))[3] and not img.getpixel((x + 1, y + 1))[3]:
                shadow.putpixel((x + 1, y + 1), (12, 10, 16, 255))
    shadow.alpha_composite(img)
    return shadow


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    meta = {"chars": CHARS, "styles": {}}
    rows = []
    y = 0
    for style, st in STYLES.items():
        s = st["scale"]
        cw, chh = 5 * s + 2, 7 * s + 3
        rows.append((style, y, cw, chh))
        meta["styles"][style] = {"y": y, "w": cw, "h": chh, "advance": cw - 1 + (1 if s > 1 else 0)}
        y += chh
    width = max(r[2] for r in rows) * len(CHARS)
    img = canvas(width, y)
    for style, yy, cw, chh in rows:
        for i, ch in enumerate(CHARS):
            g = glyph(ch, style)
            img.paste(g, (i * cw, yy), g)
    img.save(os.path.join(OUT, "font.png"))
    with open(os.path.join(OUT, "font_meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    preview(img.crop((0, 0, min(width, 17 * 30), y)), 3, os.path.join(PREV, "font.png"))
    print("ok font", img.size, len(CHARS), "caracteres")
