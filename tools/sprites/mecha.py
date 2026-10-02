"""Genera las piezas de "La Presidenta Mecha", jefe de la Misión 3 (personaje ficticio de parodia).

Jefe por piezas al estilo Metal Slug: cada parte es un PNG propio que Godot coloca, anima y
puede romper por separado. Inspirado en las referencias del equipo, con cara robótica inventada
y sin nombres, caras ni lemas de personas reales.

Uso:  python tools/sprites/mecha.py
Salida: assets/sprites/mecha_*.png y mecha_meta.json (pivotes de cada pieza).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from px import Pen, canvas, outline, preview  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "preview")

METAL = [(24, 26, 30), (46, 50, 56), (74, 80, 88), (112, 120, 130), (160, 168, 176)]
CHROME = [(120, 126, 136), (170, 176, 186), (214, 218, 226), (244, 246, 250)]
GREEN, WHITE, RED = (0, 118, 70), (236, 236, 236), (204, 30, 46)
GOLD = [(150, 100, 20), (220, 170, 40), (255, 226, 120)]
EYE = [(150, 10, 10), (255, 40, 30), (255, 190, 150)]
HAIR = [(14, 12, 16), (40, 34, 44)]

pivots = {}


def save(name, img, pivot, extra=None):
    img = outline(img)
    img.save(os.path.join(OUT, "mecha_" + name + ".png"))
    pivots[name] = {"size": list(img.size), "pivot": list(pivot)}
    if extra:
        pivots[name].update(extra)
    return img


def rivets(pen, pts):
    for x, y in pts:
        pen.px(x, y, METAL[4])
        pen.px(x + 1, y + 1, METAL[0])


def tricolor_band(pen, a, b, w=3):
    """Banda tricolor en diagonal entre a y b."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = (dx * dx + dy * dy) ** 0.5
    nx, ny = -dy / ln, dx / ln
    for off, col in ((-w, GREEN), (0, WHITE), (w, RED)):
        pen.line((a[0] + nx * off, a[1] + ny * off), (b[0] + nx * off, b[1] + ny * off), col, w)


def torso():
    img = canvas(76, 70)
    p = Pen(img)
    # hombros anchos, pecho blindado, cintura estrecha
    p.poly([(4, 10), (72, 10), (66, 40), (52, 66), (24, 66), (10, 40)], METAL[2])
    p.poly([(4, 10), (20, 10), (22, 40), (24, 66), (10, 40)], METAL[1])
    p.poly([(56, 10), (72, 10), (66, 40), (52, 66), (54, 40)], METAL[3])
    p.rect(8, 8, 60, 4, METAL[3])
    # placas del pecho
    p.poly([(22, 16), (37, 14), (37, 34), (24, 32)], METAL[3])
    p.poly([(39, 14), (54, 16), (52, 32), (39, 34)], METAL[3])
    p.line((22, 32), (37, 35), METAL[1], 1)
    p.line((39, 35), (52, 32), METAL[1], 1)
    # abdomen segmentado
    for i in range(4):
        p.rect(27, 38 + i * 6, 22, 4, METAL[2 if i % 2 else 1])
    # núcleo que brilla
    p.circle(38, 24, 4, EYE[0])
    p.circle(38, 24, 2, EYE[1])
    # banda presidencial tricolor y medalla (estrella, no el escudo nacional)
    tricolor_band(pen=p, a=(60, 10), b=(22, 60), w=3)
    p.circle(28, 50, 6, GOLD[0])
    p.circle(28, 50, 5, GOLD[1])
    p.poly([(28, 45), (29.5, 49), (33, 49), (30, 51.5), (31, 55), (28, 53), (25, 55), (26, 51.5), (23, 49), (26.5, 49)], GOLD[2])
    rivets(p, [(8, 14), (68, 14), (12, 34), (62, 34), (30, 62), (46, 62)])
    return save("torso", img, (38, 66), {"neck": [38, 9], "shoulder_front": [8, 14], "shoulder_back": [66, 14],
                                          "pod_front": [16, 9], "pod_back": [60, 9], "core": [38, 24]})


def head():
    img = canvas(30, 38)
    p = Pen(img)
    # cuello con cables
    p.rect(11, 28, 8, 10, METAL[1])
    p.line((12, 29), (10, 37), METAL[0], 1)
    p.line((18, 29), (20, 37), METAL[0], 1)
    # cara cromada
    p.poly([(5, 8), (25, 8), (26, 20), (21, 30), (9, 30), (4, 20)], CHROME[1])
    p.poly([(5, 8), (12, 8), (11, 29), (9, 30), (4, 20)], CHROME[0])
    p.rect(19, 10, 4, 16, CHROME[2])
    p.line((8, 22), (12, 26), CHROME[0], 1)
    p.line((22, 22), (18, 26), CHROME[0], 1)
    # ojos rojos brillantes y ceño
    p.rect(8, 15, 5, 3, EYE[0])
    p.rect(17, 15, 5, 3, EYE[0])
    p.rect(9, 16, 3, 1, EYE[1])
    p.rect(18, 16, 3, 1, EYE[1])
    p.px(10, 16, EYE[2])
    p.px(19, 16, EYE[2])
    p.line((7, 13), (13, 14), METAL[0], 1)
    p.line((23, 13), (17, 14), METAL[0], 1)
    # boca de rejilla
    p.rect(11, 24, 8, 3, METAL[1])
    for x in range(12, 19, 2):
        p.px(x, 25, METAL[0])
    # pelo negro corto con flequillo recto (diseño inventado)
    p.poly([(3, 12), (4, 3), (15, 0), (26, 3), (27, 12), (24, 9), (6, 9)], HAIR[0])
    p.rect(5, 8, 20, 3, HAIR[0])
    p.rect(3, 9, 3, 12, HAIR[0])
    p.rect(24, 9, 3, 12, HAIR[0])
    p.line((8, 2), (20, 2), HAIR[1], 1)
    return save("head", img, (15, 37), {"eyes": [15, 16]})


def pod():
    img = canvas(28, 32)
    p = Pen(img)
    p.rect(2, 4, 24, 26, METAL[2])
    p.rect(2, 4, 5, 26, METAL[1])
    p.rect(21, 4, 5, 26, METAL[3])
    p.rect(1, 2, 26, 3, METAL[3])
    for r in range(3):
        for c in range(3):
            x, y = 6 + c * 7, 9 + r * 7
            p.circle(x + 1, y + 1, 3, METAL[0])
            p.circle(x + 1, y, 2, RED)
            p.px(x, y - 1, (255, 160, 160))
    p.rect(2, 28, 24, 2, GREEN)
    return save("pod", img, (14, 30), {"launch": [14, 2]})


def gatling(frame):
    img = canvas(72, 30)
    p = Pen(img)
    # brazo segmentado desde el hombro (derecha) hasta la ametralladora (izquierda)
    for i, x in enumerate(range(44, 68, 6)):
        p.rect(x, 9, 6, 11, METAL[2 if i % 2 else 3])
        p.rect(x, 9, 6, 2, METAL[4])
    p.circle(66, 14, 7, METAL[1])
    p.circle(66, 14, 4, METAL[3])
    # carcasa
    p.rect(26, 5, 20, 20, METAL[1])
    p.rect(26, 5, 20, 4, METAL[3])
    p.rect(30, 12, 12, 3, GREEN)
    p.rect(30, 15, 12, 2, WHITE)
    p.rect(30, 17, 12, 3, RED)
    # 6 cañones que giran (dos fotogramas)
    offs = [8, 12, 16, 20] if frame == 0 else [10, 14, 18, 22]
    for i, y in enumerate(offs):
        p.rect(2, y - 1, 25, 3, METAL[3 if i % 2 else 2])
        p.rect(2, y - 1, 25, 1, METAL[4])
    p.rect(0, 7, 4, 17, METAL[1])
    return save("gatling%d" % frame, img, (66, 14), {"muzzle": [0, 15]})


def claw_arm():
    img = canvas(34, 58)
    p = Pen(img)
    # brazo levantado (hombro abajo, garra arriba)
    p.circle(17, 51, 6, METAL[1])
    for i, y in enumerate(range(20, 50, 6)):
        p.rect(12, y, 10, 6, METAL[2 if i % 2 else 3])
        p.rect(12, y, 10, 1, METAL[4])
    p.rect(9, 12, 16, 9, METAL[2])
    p.rect(12, 14, 10, 2, GREEN)
    p.rect(12, 16, 10, 1, WHITE)
    p.rect(12, 17, 10, 2, RED)
    # garra de tres dedos
    for x0, x1 in ((10, 5), (17, 17), (24, 29)):
        p.line((x0, 12), (x1, 3), CHROME[1], 3)
        p.px(x1, 1, CHROME[3])
    return save("claw", img, (17, 51))


def hips():
    img = canvas(60, 22)
    p = Pen(img)
    p.poly([(2, 2), (58, 2), (52, 20), (8, 20)], METAL[2])
    p.rect(2, 2, 56, 3, METAL[3])
    p.rect(8, 9, 44, 2, GREEN)
    p.rect(8, 11, 44, 2, WHITE)
    p.rect(8, 13, 44, 2, RED)
    for x in (6, 54):
        p.circle(x, 12, 5, METAL[1])
        p.circle(x, 12, 2, METAL[3])
    return save("hips", img, (30, 2), {"hip_front": [6, 12], "hip_back": [54, 12]})


def leg_upper():
    img = canvas(16, 48)
    p = Pen(img)
    p.circle(8, 5, 5, METAL[1])
    p.poly([(3, 6), (13, 6), (11, 44), (5, 44)], METAL[2])
    p.rect(3, 6, 3, 38, METAL[1])
    p.rect(11, 6, 2, 38, METAL[3])
    p.rect(4, 20, 8, 2, GREEN)
    p.rect(4, 22, 8, 1, WHITE)
    p.rect(4, 23, 8, 2, RED)
    p.circle(8, 43, 4, METAL[3])
    return save("leg_upper", img, (8, 5), {"length": 38})


def leg_lower():
    img = canvas(18, 104)
    p = Pen(img)
    p.circle(9, 4, 5, METAL[1])
    p.poly([(3, 5), (15, 5), (12, 92), (6, 92)], METAL[2])
    p.rect(3, 5, 3, 60, METAL[1])
    p.rect(12, 5, 2, 70, METAL[3])
    for y in (30, 60):
        p.rect(5, y, 8, 3, METAL[0])
        p.rect(5, y, 8, 1, METAL[4])
    # punta afilada
    p.poly([(6, 90), (12, 90), (9, 103)], CHROME[1])
    p.px(9, 101, CHROME[3])
    return save("leg_lower", img, (9, 4), {"length": 99})


def missile():
    img = canvas(7, 16)
    p = Pen(img)
    p.rect(2, 3, 3, 10, WHITE)
    p.rect(2, 6, 3, 2, GREEN)
    p.rect(2, 8, 3, 2, RED)
    p.poly([(2, 3), (4, 3), (3.5, 0)], RED)
    p.rect(1, 12, 5, 2, METAL[2])
    return save("missile", img, (3, 8))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    parts = [torso(), head(), pod(), gatling(0), gatling(1), claw_arm(), hips(), leg_upper(), leg_lower(), missile()]
    with open(os.path.join(OUT, "mecha_meta.json"), "w") as f:
        json.dump(pivots, f, indent=1)
    # hoja de revisión con todas las piezas
    w = sum(p.width for p in parts) + 4 * len(parts)
    h = max(p.height for p in parts)
    sh = canvas(w, h)
    x = 0
    for part in parts:
        sh.paste(part, (x, 0), part)
        x += part.width + 4
    preview(sh, 3, os.path.join(PREV, "mecha_parts.png"))
    print("ok mecha", len(parts), "piezas")
