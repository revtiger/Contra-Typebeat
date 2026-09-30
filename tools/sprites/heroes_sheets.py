"""Sprites de cuerpo entero de Eduardo y Eder a partir de sus hojas hechas con ChatGPT.

Entrada: tools/sprites/chatgpt/sprites_<id>_1.png y sprites_<id>_2.png, 4x4 poses cada una, fondo transparente.
  Hoja 1: fila 0 quieto (4) · fila 1 correr (4) · fila 2 agachado, salto (sube), salto (encogido), aterrizaje
          fila 3 disparar (4, con fogonazo en la 2 y la 3)
  Hoja 2: fila 0 granada (4) · fila 1 al suelo, cuerpo a tierra, cuerpo a tierra disparando, levantarse
          fila 2 victoria (4) · fila 3 cuchillo (4)
Las poses se localizan solas (bandas vacías entre filas y columnas) y los efectos sueltos
(granada en el aire, estela del cuchillo) se quedan en la celda de su pose.

Salida: assets/sprites/player_<id>_body.png (una fila por animación, fotogramas FWxFH con los pies en FEET)
        assets/sprites/player_<id>_body_meta.json (animaciones y boca del arma)
player.gd usa estas hojas en lugar de piernas + torso cuando existen.

Uso: python tools/sprites/heroes_sheets.py
"""
import json
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "chatgpt")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")

HEROES = ["eduardo", "eder"]
FW, FH = 80, 60
FEET = (30, 58)       # pies (centro de las piernas) dentro del fotograma
HEIGHT = 46           # alto en el juego del personaje quieto (el Presi mide ~44)

# poses tumbadas: se centran en el fotograma en lugar de alinear los pies
WIDE = ("prone", "die")
# animación: [(hoja, fila, columna), ...], fps, bucle
ANIMS = {
	"idle": ([(1, 0, c) for c in range(4)], 6, True),
	"run": ([(1, 1, c) for c in range(4)], 12, True),
	"jump": ([(1, 2, 1), (1, 2, 2)], 1, False),
	"crouch": ([(1, 2, 0)], 1, True),
	"shoot": ([(1, 3, 0), (1, 3, 1), (1, 3, 2), (1, 3, 3)], 20, False),
	"throw": ([(2, 0, c) for c in range(4)], 14, False),
	"prone": ([(2, 1, 1), (2, 1, 2)], 1, False),
	"die": ([(2, 1, 0), (2, 1, 1)], 6, False),
	"win": ([(2, 2, c) for c in range(4)], 5, True),
	"knife": ([(2, 3, c) for c in range(4)], 18, False),
}


def alpha_mask(im):
	return im.getchannel("A").point(lambda v: 255 if v > 100 else 0)


def blobs(mask, step=3):
	"""Manchas conectadas de la máscara (muestreada cada `step` px): lista de [x0, y0, x1, y1, área]."""
	w, h = mask.size[0] // step, mask.size[1] // step
	small = mask.resize((w, h), Image.NEAREST).load()
	seen = [[False] * w for _ in range(h)]
	out = []
	for sy in range(h):
		for sx in range(w):
			if seen[sy][sx] or not small[sx, sy]:
				continue
			stack = [(sx, sy)]
			seen[sy][sx] = True
			x0, y0, x1, y1, n = sx, sy, sx, sy, 0
			while stack:
				x, y = stack.pop()
				n += 1
				x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
				for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
					if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and small[nx, ny]:
						seen[ny][nx] = True
						stack.append((nx, ny))
			out.append([x0 * step, y0 * step, (x1 + 1) * step, (y1 + 1) * step, n])
	return out


def cells(path):
	"""Recorta las 16 poses de una hoja: devuelve cells[fila][columna] = imagen RGBA.
	Cada pose es una mancha grande; se asigna a su casilla de la cuadrícula 4x4 por su centro.
	Las manchas pequeñas (granada en el aire, estela, fogonazo) se unen a la pose más cercana."""
	im = Image.open(path).convert("RGBA")
	found = blobs(alpha_mask(im))
	big = sorted([b for b in found if b[4] > 400], key=lambda b: -b[4])[:16]
	if len(big) != 16:
		raise SystemExit("%s: se esperaban 16 poses y hay %d" % (path, len(big)))
	for b in found:
		if b in big or b[4] < 3:
			continue
		cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
		near = min(big, key=lambda p: max(p[0] - cx, 0, cx - p[2]) + max(p[1] - cy, 0, cy - p[3]))
		near[0], near[1], near[2], near[3] = min(near[0], b[0]), min(near[1], b[1]), max(near[2], b[2]), max(near[3], b[3])
	grid = [[None] * 4 for _ in range(4)]
	for p in big:
		r = min(3, int((p[1] + p[3]) / 2 / (im.height / 4)))
		c = min(3, int((p[0] + p[2]) / 2 / (im.width / 4)))
		if grid[r][c] is not None:
			raise SystemExit("%s: dos poses en la casilla %d,%d" % (path, r, c))
		grid[r][c] = im.crop((max(p[0] - 2, 0), max(p[1] - 2, 0), p[2] + 2, p[3] + 2))
	return grid


def feet_x(cell):
	"""Centro horizontal de las botas: los píxeles opacos de la franja inferior."""
	m = alpha_mask(cell)
	b = m.getbbox()
	band = m.crop((b[0], b[3] - max(8, (b[3] - b[1]) // 10), b[2], b[3]))
	bb = band.getbbox()
	return b[0] + (bb[0] + bb[2]) / 2.0


def clean(im):
	"""Alfa binaria y quita el halo blanco que deja el fondo al reducir."""
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if a < 110 or (r > 225 and g > 225 and b > 225 and a < 250):
				px[x, y] = (0, 0, 0, 0)
			else:
				px[x, y] = (r, g, b, 255)
	return im


def build(hero):
	sheets = {1: cells(os.path.join(SRC, "sprites_%s_1.png" % hero)),
		2: cells(os.path.join(SRC, "sprites_%s_2.png" % hero))}
	idle = sheets[1][0][0]
	ib = alpha_mask(idle).getbbox()
	scale = HEIGHT / float(ib[3] - ib[1])
	cols = max(len(v[0]) for v in ANIMS.values())
	sheet = Image.new("RGBA", (FW * cols, FH * len(ANIMS)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "feet": list(FEET), "anims": {}}
	for row, (name, (frames, fps, loop)) in enumerate(ANIMS.items()):
		for col, (s, r, c) in enumerate(frames):
			cell = sheets[s][r][c]
			b = alpha_mask(cell).getbbox()
			fx = feet_x(cell)
			w, h = cell.size
			small = cell.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
			small = clean(small)
			# pies de la pose (fondo del bbox, centro de las botas) sobre FEET
			ox = round(FEET[0] - fx * scale)
			if name in WIDE:
				# tumbado: el cuerpo es más ancho que el fotograma; se centra la figura entera
				ox = round(FW / 2 - (b[0] + b[2]) / 2 * scale)
			oy = round(FEET[1] - b[3] * scale)
			frame = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
			frame.alpha_composite(small, (ox, oy)) if ox >= 0 and oy >= 0 else frame.paste(small, (ox, oy), small)
			sheet.alpha_composite(frame, (col * FW, row * FH))
		meta["anims"][name] = {"row": row, "frames": len(frames), "fps": fps, "loop": loop}
	# boca del arma: el píxel opaco más a la derecha en la franja de alturas del cañón
	def muzzle(anim, y0, y1):
		fr = sheet.crop((0, meta["anims"][anim]["row"] * FH, FW, (meta["anims"][anim]["row"] + 1) * FH))
		m = alpha_mask(fr)
		best = None
		for y in range(FEET[1] - y1, FEET[1] - y0):
			bb = m.crop((0, y, FW, y + 1)).getbbox()
			if bb and (best is None or bb[2] > best[0]):
				best = (bb[2], y)
		return [best[0] - FEET[0], best[1] - FEET[1]]
	meta["muzzle"] = {"fwd": muzzle("idle", 16, 36), "crouch_fwd": muzzle("crouch", 8, 28), "prone": muzzle("prone", 0, 16)}
	sheet.save(os.path.join(OUT, "player_%s_body.png" % hero))
	with open(os.path.join(OUT, "player_%s_body_meta.json" % hero), "w", encoding="utf-8", newline="\n") as f:
		json.dump(meta, f, indent=1)
	print("ok", hero, "escala %.3f" % scale, "boca", meta["muzzle"]["fwd"])


if __name__ == "__main__":
	for hero_id in HEROES:
		build(hero_id)
