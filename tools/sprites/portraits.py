"""Retratos de la pantalla ELIGE TU SOLDADO, al estilo de Metal Slug X: cara grande de tres cuartos,
sombreado de cómic, expresión exagerada. Genera la versión a color (elegido) y en sepia (sin elegir).

Soldados: presi, tenienta (ficticios) y comando, hawaiano (diseños de Eduardo).
Uso:  python tools/sprites/portraits.py  ->  assets/sprites/portraits.png (fila 0 color, fila 1 sepia)
Si existe tools/sprites/pixellab/portrait_<id>.png (hecho con PixelLab), se usa en vez del dibujado.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from px import Pen, canvas, outline, preview  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "preview")
AI = os.path.join(os.path.dirname(__file__), "pixellab")  # retratos generados con PixelLab
W, H = 72, 96
INK = (20, 14, 16)

HEROES = {
    "presi": {"skin": [(150, 88, 60), (206, 138, 96), (236, 176, 128), (252, 214, 172)],
              "hair": [(16, 14, 18), (44, 40, 46), (80, 74, 86)], "style": "slick",
              "cloth": [(22, 26, 46), (40, 48, 82), (70, 80, 124)], "mouth": "grin", "extra": "sash",
              "bg": [(70, 30, 26), (30, 14, 14)]},
    "tenienta": {"skin": [(160, 94, 66), (214, 148, 106), (242, 186, 140), (255, 222, 186)],
                 "hair": [(92, 32, 16), (150, 58, 28), (200, 98, 50)], "style": "ponytail",
                 "cloth": [(52, 60, 32), (82, 94, 52), (116, 130, 76)], "mouth": "smirk", "extra": "bandana",
                 "bg": [(30, 52, 60), (12, 20, 26)]},
    # diseños de Eduardo (ChatGPT): el retrato sale de tools/sprites/chatgpt/portrait_<id>.png
    "comando": {},
    "hawaiano": {},
}


def background(p, bg):
    for y in range(H):
        t = y / H
        col = tuple(int(bg[0][i] * (1 - t) + bg[1][i] * t) for i in range(3))
        p.rect(0, y, W, 1, col)
    for i in range(0, W + H, 6):
        p.line((i, 0), (i - 30, 30), tuple(min(255, c + 10) for c in bg[0]), 1)


def shoulders(p, h):
    cl = h["cloth"]
    p.poly([(0, 96), (4, 78), (22, 68), (52, 68), (68, 76), (72, 96)], cl[1])
    p.poly([(0, 96), (4, 78), (22, 68), (30, 70), (22, 96)], cl[0])
    p.poly([(52, 68), (68, 76), (72, 96), (60, 96), (58, 78)], cl[2])
    if h["extra"] == "sash":
        p.poly([(28, 70), (46, 70), (38, 96), (26, 96)], (238, 238, 232))  # camisa
        p.poly([(34, 70), (39, 70), (37, 90), (33, 90)], (180, 24, 36))  # corbata
        for off, col in ((-4, (0, 118, 70)), (0, (236, 236, 236)), (4, (204, 30, 46))):
            p.line((58 + off, 72), (20 + off, 96), col, 4)
        p.circle(26, 90, 4, (226, 176, 38))
        p.px(25, 88, (255, 236, 140))
    else:
        p.poly([(26, 68), (48, 68), (44, 80), (30, 80)], cl[0])  # cuello de la camiseta
        p.line((30, 72), (38, 86), (190, 190, 196), 1)  # cadena de las chapas
        p.rect(36, 86, 5, 7, (200, 200, 206))
        p.rect(37, 87, 3, 1, (150, 150, 156))


def neck_and_face(p, h):
    sk = h["skin"]
    p.poly([(28, 58), (46, 58), (48, 72), (28, 72)], sk[1])
    p.poly([(28, 58), (34, 58), (34, 72), (28, 72)], sk[0])
    face = [(21, 26), (24, 14), (36, 9), (50, 11), (58, 22), (60, 36), (59, 48), (53, 58), (44, 65), (35, 65),
            (27, 58), (22, 48), (20, 36)]
    p.poly(face, sk[2])
    # sombra del lado de atrás y de la mandíbula
    p.poly([(21, 26), (24, 14), (29, 12), (27, 30), (28, 50), (35, 65), (27, 58), (22, 48), (20, 36)], sk[1])
    p.poly([(28, 52), (36, 61), (44, 62), (52, 55), (53, 58), (44, 65), (35, 65), (27, 58)], sk[1])
    # brillo en pómulo y frente
    p.poly([(46, 38), (54, 36), (56, 42), (50, 44)], sk[3])
    p.poly([(38, 16), (50, 15), (52, 20), (40, 21)], sk[3])
    # oreja
    p.poly([(20, 34), (25, 33), (26, 46), (21, 45)], sk[1])
    p.line((22, 36), (23, 43), sk[0], 1)
    return face


def eyes(p, h, angry=True):
    sk = h["skin"]
    # ojo de atrás (más pequeño) y de delante
    for (x, y, w) in ((29, 35, 6), (43, 34, 8)):
        p.rect(x, y, w, 4, (246, 246, 240))
        p.rect(x + w - 3, y + 1, 2, 3, INK)
        p.rect(x, y - 1, w, 1, INK)
        p.rect(x, y + 4, w, 1, sk[1])
    # cejas anguladas (ceño decidido)
    brow = h["hair"][0] if h["style"] != "helmet" else (90, 86, 80)
    if angry:
        p.line((27, 30), (35, 33), brow, 2)
        p.line((42, 32), (53, 28), brow, 3)
    else:
        p.line((27, 31), (35, 30), brow, 2)
        p.line((42, 30), (53, 29), brow, 3)
    # arruga del ceño y nariz
    p.line((38, 32), (38, 36), sk[0], 1)
    p.poly([(51, 40), (57, 47), (52, 49)], sk[2])
    p.line((51, 42), (51, 47), sk[1], 1)
    p.line((52, 49), (56, 48), sk[0], 1)
    p.px(53, 48, INK)


def mouth(p, h):
    sk = h["skin"]
    kind = h["mouth"]
    if kind == "grin":
        p.poly([(37, 53), (53, 51), (51, 56), (40, 57)], INK)
        p.poly([(38, 53), (52, 52), (51, 55), (39, 56)], (250, 250, 244))
        p.line((39, 54), (51, 53), (200, 200, 196), 1)
        p.line((42, 60), (48, 60), sk[1], 1)
    elif kind == "smirk":
        p.line((39, 55), (52, 52), INK, 2)
        p.px(53, 51, INK)
        p.line((41, 58), (48, 58), sk[1], 1)
    elif kind == "yell":
        p.poly([(38, 51), (53, 50), (52, 60), (41, 62)], INK)
        p.poly([(40, 52), (52, 51), (51, 53), (41, 54)], (250, 250, 244))
        p.poly([(42, 58), (50, 57), (49, 60), (43, 61)], (170, 50, 50))
        # gotas de sudor
        p.poly([(58, 26), (61, 31), (58, 33), (56, 30)], (180, 220, 255))
        p.px(58, 28, (255, 255, 255))
    elif kind == "cigar":
        p.line((38, 55), (52, 54), INK, 2)
        p.rect(50, 53, 12, 3, (120, 70, 36))
        p.rect(60, 53, 2, 3, (220, 90, 30))
        p.px(61, 52, (255, 200, 80))
        for i in range(3):
            p.circle(64 + i * 2, 49 - i * 5, 1.5 + i, (190, 190, 190))
    if h["style"] == "helmet":
        # bigote enorme
        hc = h["hair"]
        p.poly([(34, 49), (44, 47), (56, 48), (60, 53), (54, 52), (46, 51), (38, 53), (32, 54)], hc[1])
        p.line((36, 50), (56, 49), hc[2], 1)
        p.line((33, 53), (40, 52), hc[0], 1)


def hair(p, h):
    hc = h["hair"]
    st = h["style"]
    if st == "slick":
        p.poly([(20, 30), (19, 16), (28, 7), (42, 4), (56, 9), (62, 20), (56, 18), (46, 14), (34, 16), (26, 22), (24, 32)], hc[0])
        p.line((30, 9), (54, 12), hc[2], 2)
        p.line((28, 14), (48, 12), hc[1], 1)
        p.poly([(20, 30), (24, 32), (24, 42), (21, 40)], hc[0])  # patilla
    elif st == "ponytail":
        p.poly([(19, 32), (18, 16), (28, 6), (44, 4), (58, 10), (62, 22), (54, 17), (42, 16), (30, 20), (24, 34)], hc[1])
        p.poly([(18, 18), (8, 26), (4, 44), (10, 58), (14, 40), (20, 30)], hc[1])  # coleta
        p.line((10, 30), (8, 48), hc[0], 2)
        p.line((30, 8), (52, 9), hc[2], 2)
        p.line((34, 14), (56, 16), hc[0], 1)
        # pañuelo rojo en la frente
        p.poly([(22, 20), (58, 14), (60, 19), (24, 26)], (196, 30, 34))
        p.line((24, 22), (58, 16), (240, 80, 80), 1)
        p.poly([(22, 20), (14, 18), (12, 24), (22, 24)], (170, 24, 28))
    elif st == "cap":
        # gorra hacia atrás con pelo en punta asomando
        for x in range(26, 58, 5):
            p.poly([(x, 16), (x + 3, 5), (x + 6, 16)], hc[0])
        p.poly([(20, 22), (24, 12), (38, 8), (54, 10), (60, 18), (58, 24), (22, 28)], (40, 90, 170))
        p.poly([(20, 22), (8, 26), (10, 30), (24, 28)], (30, 70, 140))
        p.line((26, 13), (54, 13), (90, 140, 220), 1)
        p.rect(36, 16, 8, 4, (240, 240, 240))
    elif st == "helmet":
        p.poly([(16, 32), (16, 16), (26, 5), (42, 2), (58, 7), (66, 18), (64, 30), (60, 26), (20, 28)], (70, 80, 56))
        p.poly([(16, 32), (16, 16), (26, 5), (32, 4), (26, 28)], (50, 58, 40))
        p.line((28, 8), (56, 9), (110, 122, 88), 2)
        # gafas sobre el casco
        p.rect(28, 19, 30, 7, (40, 36, 30))
        p.rect(31, 20, 10, 5, (120, 190, 220))
        p.rect(45, 20, 10, 5, (120, 190, 220))
        p.px(33, 21, (230, 250, 255))
        p.px(47, 21, (230, 250, 255))
        # parche en el ojo de atrás
        p.rect(28, 33, 8, 6, INK)
        p.line((26, 32), (40, 29), INK, 1)


def portrait(name):
    # si hay un retrato hecho con PixelLab (72x96), se usa ese en lugar del dibujado por código
    # (o con los diseños de ChatGPT de Eduardo, recortados por chatgpt_heroes.py)
    ai = os.path.join(AI, "portrait_%s.png" % name)
    if not os.path.exists(ai):
        ai = os.path.join(os.path.dirname(__file__), "chatgpt", "portrait_%s.png" % name)
    if os.path.exists(ai):
        from PIL import Image
        return Image.open(ai).convert("RGBA").resize((W, H), Image.NEAREST)
    h = HEROES[name]
    img = canvas(W, H)
    p = Pen(img)
    background(p, h["bg"])
    body = canvas(W, H)
    q = Pen(body)
    shoulders(q, h)
    neck_and_face(q, h)
    eyes(q, h, angry=h["mouth"] != "smirk")
    mouth(q, h)
    hair(q, h)
    body = outline(body, INK + (255,))
    img.alpha_composite(body)
    return img


def sepia(img):
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            v = (r * 30 + g * 59 + b * 11) // 100
            v = int(v * 0.75)
            px[x, y] = (min(255, v + 26), min(255, v + 12), v, a)
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    names = list(HEROES)
    sheet = canvas(W * len(names), H * 2)
    for i, n in enumerate(names):
        im = portrait(n)
        sheet.paste(im, (i * W, 0), im)
        se = sepia(im)
        sheet.paste(se, (i * W, H), se)
    sheet.save(os.path.join(OUT, "portraits.png"))
    preview(sheet, 3, os.path.join(PREV, "portraits.png"))
    print("ok portraits", names)
