"""Genera los sprites del protagonista (traje + banda presidencial tricolor + mochila) y de los
soldados enemigos, al estilo Metal Slug: piernas y torso en hojas separadas para que las piernas
corran mientras el torso apunta.

Uso:  python tools/sprites/humans.py
Salida: assets/sprites/player_legs.png, player_torso.png, player_death.png, player_meta.json,
        soldier_jungle.png, soldier_desert.png, soldier_meta.json (+ vistas previas en tools/sprites/preview/)

Todas las hojas usan fotogramas de 48x48 con los pies en (24, 46).
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from px import Pen, canvas, limb, outline, polar, preview, sheet  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
PREV = os.path.join(os.path.dirname(__file__), "preview")
FW, FH = 48, 48
FEET_Y = 46
HIP = (24, 30)

# ---------- paletas ----------
SKIN = [(176, 110, 78), (226, 160, 116), (248, 200, 156)]
HAIR = [(18, 16, 18), (46, 40, 40)]
GUN = [(30, 30, 36), (60, 60, 70), (104, 104, 116)]
WOOD = [(96, 56, 28), (134, 82, 40)]
SHOE = [(18, 18, 22), (54, 54, 62)]

HERO = {
    "cloth": [(24, 28, 46), (40, 46, 74), (66, 74, 110)],  # traje azul marino
    "pants": [(22, 25, 42), (36, 41, 66), (56, 62, 96)],
    "shirt": [(190, 190, 190), (238, 238, 230)],
    "tie": (186, 28, 38),
    "pack": [(64, 66, 40), (92, 94, 58), (124, 126, 80)],
}
SOLDIERS = {
    "jungle": {"cloth": [(48, 56, 32), (76, 88, 50), (106, 120, 70)],
               "pants": [(42, 48, 28), (66, 76, 44), (92, 104, 62)],
               "helmet": [(40, 48, 28), (70, 82, 46), (100, 114, 66)]},
    "desert": {"cloth": [(128, 104, 66), (172, 146, 98), (206, 184, 134)],
               "pants": [(112, 90, 56), (150, 126, 84), (186, 162, 114)],
               "helmet": [(120, 30, 26), (170, 48, 38), (206, 80, 64)]},
}


# ---------- piernas ----------
def leg_points(hip, thigh, bend):
    knee = polar(hip, 8, thigh)
    foot = polar(knee, 8, thigh - bend)
    return knee, foot


def draw_leg(pen, hip, thigh, bend, pants, far):
    knee, foot = leg_points(hip, thigh, bend)
    col = pants[0] if far else pants[1]
    limb(pen, hip, knee, col, 5, pants[0])
    limb(pen, knee, foot, col, 4, pants[0])
    if not far:
        pen.line((hip[0] + 1, hip[1] - 1), (knee[0] + 1, knee[1] - 1), pants[2], 1)
    # zapato hacia delante
    sx, sy = round(foot[0]), round(foot[1])
    pen.rect(sx - 2, sy - 1, 6, 3, SHOE[0])
    pen.rect(sx - 1, sy - 1, 4, 1, SHOE[1])
    return foot


def legs_frame(pose, pants, hip=HIP):
    """pose = ((thigh, bend) pierna cercana, (thigh, bend) pierna lejana). Devuelve (img, bob)."""
    near, far = pose
    feet = [leg_points(hip, *near)[1], leg_points(hip, *far)[1]]
    bob = round(FEET_Y - max(f[1] for f in feet) - 1)
    h = (hip[0], hip[1] + bob)
    img = canvas(FW, FH)
    pen = Pen(img)
    draw_leg(pen, (h[0] - 1, h[1]), far[0], far[1], pants, True)
    draw_leg(pen, (h[0] + 1, h[1]), near[0], near[1], pants, False)
    pen.rect(h[0] - 4, h[1] - 2, 9, 4, pants[1])
    return outline(img), bob


RUN_THIGH = [32, 22, 6, -14, -30, -22, 0, 20]
RUN_BEND = [12, 6, 12, 34, 56, 74, 58, 30]


def run_pose(i):
    j = (i + 4) % 8
    return ((RUN_THIGH[i], RUN_BEND[i]), (RUN_THIGH[j], RUN_BEND[j]))


def crouch_legs(pants, step=0):
    img = canvas(FW, FH)
    pen = Pen(img)
    hip = (24, 38)
    s = [0, 1, 0, -1][step]
    # pierna lejana: rodilla en el suelo
    limb(pen, hip, (19 + s, 44), pants[0], 5)
    limb(pen, (19 + s, 44), (13 + s, 45), pants[0], 4)
    pen.rect(10 + s, 44, 5, 3, SHOE[0])
    # pierna cercana: pie apoyado delante
    limb(pen, (hip[0] + 1, hip[1]), (31 - s, 37), pants[1], 5, pants[0])
    limb(pen, (31 - s, 37), (31 - s, 45), pants[1], 4, pants[0])
    pen.rect(30 - s, 44, 6, 3, SHOE[0])
    pen.rect(31 - s, 44, 4, 1, SHOE[1])
    pen.rect(hip[0] - 4, hip[1] - 2, 9, 4, pants[1])
    return outline(img)


# ---------- rifle ----------
def rifle(pen, grip, u, n=None):
    """Rifle tipo AK. grip = empuñadura; u = dirección del cañón; n = hacia donde cuelga el cargador."""
    if n is None:
        n = (-u[1], u[0]) if u[0] >= 0 else (u[1], -u[0])

    def p(t, o):
        return (grip[0] + u[0] * t + n[0] * o, grip[1] + u[1] * t + n[1] * o)

    def quad(t0, t1, o0, o1, col):
        pen.poly([p(t0, o0), p(t1, o0), p(t1, o1), p(t0, o1)], col)

    quad(-9, -3, -1, 2, WOOD[0])
    quad(-9, -4, -1, 0, WOOD[1])
    quad(-3, 7, -2, 1, GUN[1])
    quad(-3, 7, -2, -1, GUN[2])
    pen.poly([p(1, 1), p(4, 1), p(6, 6), p(3, 6)], GUN[0])
    pen.poly([p(-2, 1), p(0, 1), p(-1, 4), p(-3, 4)], GUN[0])
    quad(7, 12, -1, 1, WOOD[1])
    quad(12, 18, -1, 0, GUN[0])
    pen.px(*p(17, -2), GUN[0])
    return p(19, -0.5)


def hand(pen, pt):
    pen.circle(pt[0], pt[1], 1.5, SKIN[1])


# ---------- torsos ----------
def hero_body(pen, dy=0):
    """Mochila, chaqueta, camisa, corbata, banda tricolor, cuello y cabeza del protagonista."""
    cl, sh, pk = HERO["cloth"], HERO["shirt"], HERO["pack"]
    y = lambda v: v + dy  # noqa: E731
    # mochila a la espalda
    pen.rect(13, y(19), 7, 12, pk[1])
    pen.rect(13, y(19), 7, 3, pk[2])
    pen.rect(13, y(27), 7, 1, pk[0])
    pen.rect(12, y(22), 1, 8, pk[0])
    # chaqueta
    pen.poly([(18, y(19)), (30, y(19)), (30, y(32)), (19, y(32))], cl[1])
    pen.rect(18, y(19), 3, 13, cl[0])
    pen.rect(29, y(20), 1, 12, cl[2])
    # camisa, solapas y corbata
    pen.poly([(24, y(19)), (29, y(19)), (27, y(26))], sh[1])
    pen.px(24, y(20), sh[0])
    pen.rect(26, y(20), 2, 8, HERO["tie"])
    pen.rect(26, y(20), 2, 1, (120, 16, 24))
    # banda presidencial tricolor en diagonal (hombro delantero -> cadera trasera)
    a, b = (29, y(19)), (19, y(31))
    for off, col in ((-2.4, (0, 118, 70)), (0, (236, 236, 236)), (2.4, (204, 30, 46))):
        pen.line((a[0] + off * 0.8, a[1] + off * 0.6), (b[0] + off * 0.8, b[1] + off * 0.6), col, 3)
    pen.circle(22, y(27), 2.5, (226, 176, 38))
    pen.px(21, y(26), (255, 230, 120))
    pen.px(23, y(28), (150, 100, 20))
    # correa de la mochila
    pen.line((20, y(19)), (21, y(26)), pk[0], 1)
    # cuello y cabeza (cabezón estilo Metal Slug)
    pen.rect(23, y(16), 4, 4, SKIN[0])
    head(pen, dy)


def head(pen, dy=0, helmet=None):
    y = lambda v: v + dy  # noqa: E731
    pen.rect(20, y(6), 10, 11, SKIN[1])
    pen.rect(20, y(15), 10, 2, SKIN[0])
    pen.rect(29, y(8), 1, 7, SKIN[2])
    pen.px(30, y(11), SKIN[1])
    pen.px(30, y(12), SKIN[0])
    if helmet is None:
        pen.rect(20, y(5), 10, 3, HAIR[0])
        pen.rect(20, y(5), 3, 9, HAIR[0])
        pen.rect(22, y(5), 7, 1, HAIR[1])
        pen.rect(23, y(8), 1, 4, HAIR[0])
    else:
        pen.rect(19, y(4), 12, 5, helmet[1])
        pen.rect(19, y(8), 13, 1, helmet[0])
        pen.rect(21, y(4), 7, 1, helmet[2])
        pen.rect(20, y(9), 2, 5, HAIR[0])
    pen.rect(23, y(10), 2, 3, SKIN[0])
    pen.rect(25, y(9), 4, 1, HAIR[0])
    pen.rect(26, y(10), 2, 1, (240, 240, 240))
    pen.px(27, y(10), (10, 10, 10))
    pen.rect(26, y(14), 3, 1, (120, 40, 40))


def arm(pen, shoulder, elbow, hnd, cloth):
    limb(pen, shoulder, elbow, cloth[1], 4, cloth[0])
    limb(pen, elbow, hnd, cloth[1], 3, cloth[0])
    hand(pen, hnd)


def aim_torso(body_fn, cloth, aim, recoil=0, dy=0):
    """Torso con el arma apuntando. Devuelve (img, boca_del_cañón)."""
    img = canvas(FW, FH)
    pen = Pen(img)
    sh_n, sh_f = (27, 21 + dy), (21, 21 + dy)
    # el brazo lejano va detrás del cuerpo; así la banda del pecho queda a la vista
    if aim == "fwd":
        g = (28 - recoil, 27 + dy)
        arm(pen, sh_f, (26, 26 + dy), (36 - recoil, 27 + dy), cloth)
        body_fn(pen, dy)
        m = rifle(pen, g, (1, 0), (0, 1))
        arm(pen, sh_n, (25, 27 + dy), (g[0], g[1] + 1), cloth)
    elif aim == "up":
        g = (32, 27 + dy + recoil)
        arm(pen, sh_f, (28, 23 + dy), (32, 19 + dy + recoil), cloth)
        body_fn(pen, dy)
        m = rifle(pen, g, (0, -1), (1, 0))
        arm(pen, sh_n, (29, 26 + dy), (g[0] - 1, g[1]), cloth)
    elif aim == "down":
        g = (28, 24 + dy - recoil)
        arm(pen, sh_f, (25, 27 + dy), (28, 32 + dy - recoil), cloth)
        body_fn(pen, dy)
        m = rifle(pen, g, (0, 1), (-1, 0))
        arm(pen, sh_n, (30, 23 + dy), (g[0] + 1, g[1]), cloth)
    img = outline(img)
    return img, (round(m[0]), round(m[1]))


def throw_torso(body_fn, cloth, stage, dy=0):
    img = canvas(FW, FH)
    pen = Pen(img)
    body_fn(pen, dy)
    rifle(pen, (25, 30 + dy), (0.9, 0.44), (-0.44, 0.9))
    if stage == 0:
        arm(pen, (27, 21 + dy), (23, 16 + dy), (20, 12 + dy), cloth)
        pen.circle(19, 10 + dy, 2, (54, 70, 40))
    else:
        arm(pen, (27, 21 + dy), (31, 17 + dy), (35, 15 + dy), cloth)
    return outline(img)


def knife_torso(body_fn, cloth, stage, dy=0):
    img = canvas(FW, FH)
    pen = Pen(img)
    body_fn(pen, dy)
    rifle(pen, (24, 30 + dy), (0.9, 0.44), (-0.44, 0.9))
    hands = [(23, 19), (37, 22), (34, 27)]
    hx, hy = hands[stage]
    arm(pen, (27, 21 + dy), (28 if stage else 24, 22 + dy), (hx, hy + dy), cloth)
    if stage == 1:
        pen.line((hx + 1, hy + dy), (hx + 8, hy + dy - 2), (220, 224, 232), 2)
    elif stage == 2:
        pen.line((hx + 1, hy + dy), (hx + 6, hy + dy + 4), (220, 224, 232), 2)
    return outline(img)


# ---------- generación ----------
def hero():
    pants = HERO["pants"]
    legs_rows, bobs = [], {}
    idle, _ = legs_frame(((6, 6), (-6, 8)), pants)
    run = []
    bobs["run"] = []
    for i in range(8):
        f, b = legs_frame(run_pose(i), pants)
        run.append(f)
        bobs["run"].append(b)
    jump = [legs_frame(((55, 95), (20, 70)), pants)[0], legs_frame(((25, 40), (-10, 25)), pants)[0]]
    crouch = [crouch_legs(pants, 0)]
    crawl = [crouch_legs(pants, i) for i in range(4)]
    legs_rows = [[idle], run, jump, crouch, crawl]
    legs_anims = {"idle": 0, "run": 1, "jump": 2, "crouch": 3, "crawl": 4}

    cloth = HERO["cloth"]
    rows, muzzle = [], {}
    names = []
    for name, aim, dy in (("fwd", "fwd", 0), ("up", "up", 0), ("down", "down", 0), ("crouch_fwd", "fwd", 8)):
        frames = []
        for rc in (0, 1):
            f, m = aim_torso(hero_body, cloth, aim, rc, dy)
            frames.append(f)
            if rc == 0:
                muzzle[name] = [m[0] - 24, m[1] - FEET_Y]
        rows.append(frames)
        names.append(name)
    rows.append([throw_torso(hero_body, cloth, s) for s in (0, 1)])
    names.append("throw")
    rows.append([throw_torso(hero_body, cloth, s, 8) for s in (0, 1)])
    names.append("crouch_throw")
    rows.append([knife_torso(hero_body, cloth, s) for s in range(3)])
    names.append("knife")
    rows.append([knife_torso(hero_body, cloth, s, 8) for s in range(3)])
    names.append("crouch_knife")

    # muerte: cuerpo entero que cae de espaldas (hoja de 64x48, pies en (46, 46))
    full = canvas(FW, FH)
    full.alpha_composite(idle)
    full.alpha_composite(aim_torso(hero_body, cloth, "fwd")[0])
    death = []
    for ang, lift in ((12, 0), (40, 2), (72, 4), (90, 6)):
        fr = canvas(64, 48)
        fr.paste(full, (22, 0), full)
        fr = fr.rotate(ang, resample=0, center=(46, 46))
        shifted = canvas(64, 48)
        shifted.paste(fr, (0, -lift), fr)
        death.append(shifted)

    save_sheet("player_legs", legs_rows)
    save_sheet("player_torso", rows)
    save_sheet("player_death", [death], 64)
    meta = {"frame": [FW, FH], "feet": [24, FEET_Y], "legs": legs_anims, "torso": {n: i for i, n in enumerate(names)},
            "bob": bobs, "muzzle": muzzle, "death_frame": [64, 48], "death_feet": [46, 46]}
    with open(os.path.join(OUT, "player_meta.json"), "w") as f:
        json.dump(meta, f, indent=1)


def soldier(theme):
    pal = SOLDIERS[theme]
    cloth, pants, helmet = pal["cloth"], pal["pants"], pal["helmet"]

    def body(pen, dy=0):
        y = lambda v: v + dy  # noqa: E731
        pen.poly([(19, y(19)), (29, y(19)), (29, y(32)), (19, y(32))], cloth[1])
        pen.rect(19, y(19), 3, 13, cloth[0])
        pen.rect(28, y(20), 1, 12, cloth[2])
        pen.rect(19, y(29), 10, 2, (60, 44, 26))
        pen.rect(25, y(24), 3, 3, cloth[0])
        pen.rect(21, y(24), 3, 3, cloth[0])
        pen.rect(23, y(16), 4, 4, SKIN[0])
        head(pen, dy, helmet)

    def panic(stage):
        img = canvas(FW, FH)
        pen = Pen(img)
        body(pen)
        lift = stage * 2
        arm(pen, (21, 21), (18, 14 - lift), (19, 7 - lift), cloth)
        arm(pen, (27, 21), (30, 14 - lift), (29, 7 - lift), cloth)
        pen.rect(26, 13, 2, 2, (20, 10, 10))
        return outline(img)

    legs_idle, _ = legs_frame(((6, 6), (-6, 8)), pants)
    runs = [legs_frame(run_pose(i), pants) for i in range(8)]

    def full(legs, torso, bob=0):
        f = canvas(FW, FH)
        f.alpha_composite(legs)
        t = canvas(FW, FH)
        t.paste(torso, (0, bob), torso)
        f.alpha_composite(t)
        return f

    fwd = aim_torso(body, cloth, "fwd")[0]
    rows = [
        [full(legs_idle, fwd)],
        [full(l, fwd, b) for l, b in runs],
        [full(legs_idle, panic(s)) for s in (0, 1)],
        [full(legs_idle, throw_torso(body, cloth, s)) for s in (0, 1)],
    ]
    # francotirador: apuntando adelante, diagonal arriba, arriba y diagonal abajo
    aims = []
    for deg in (0, -45, -90, 45):
        img = canvas(FW, FH)
        pen = Pen(img)
        body(pen)
        r = math.radians(deg)
        u = (math.cos(r), math.sin(r))
        g = (28, 25)
        rifle(pen, g, u)
        arm(pen, (21, 21), (25, 24), (round(g[0] + u[0] * 8), round(g[1] + u[1] * 8)), cloth)
        arm(pen, (27, 21), (25, 26), g, cloth)
        aims.append(full(legs_idle, outline(img)))
    rows.append(aims)
    rows.append([full(l, panic(i % 2), b) for i, (l, b) in enumerate(runs)])
    save_sheet("soldier_" + theme, rows)
    return {"idle": 0, "run": 1, "panic": 2, "throw": 3, "aim": 4, "flee": 5}


def save_sheet(name, rows, fw=FW):
    img = sheet(rows, fw, FH)
    img.save(os.path.join(OUT, name + ".png"))
    preview(img, 4, os.path.join(PREV, name + ".png"))
    print("ok", name, img.size)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREV, exist_ok=True)
    hero()
    rows = {}
    for th in SOLDIERS:
        rows = soldier(th)
    with open(os.path.join(OUT, "soldier_meta.json"), "w") as f:
        json.dump({"frame": [FW, FH], "feet": [24, FEET_Y], "rows": rows, "aim_degrees": [0, -45, -90, 45]}, f, indent=1)
