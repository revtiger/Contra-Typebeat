"""Sprites de cuerpo entero de Eduardo y Eder a partir de sus hojas hechas con ChatGPT.

Entrada: tools/sprites/chatgpt/sprites_<id>_N.png, 4x4 poses cada una, fondo transparente.
  Hoja 1: fila 0 quieto (4) · fila 1 correr (4) · fila 2 agachado, salto (sube), salto (encogido), aterrizaje
          fila 3 disparar (4, con fogonazo en la 1 y la 2)
  Hoja 2: fila 0 granada (4) · fila 1 al suelo, cuerpo a tierra, cuerpo a tierra disparando, levantarse
          fila 2 victoria (4) · fila 3 cuchillo (4)
  Hoja 3: fila 0 disparar arriba quieto · fila 1 disparar arriba corriendo
          fila 2 disparar en diagonal abajo quieto · fila 3 ídem corriendo
  Hoja 4: fila 0 disparar en diagonal arriba quieto · fila 1 ídem corriendo · filas 2-3 barrida y levantarse
  Hoja 5: filas 0-1 paracaídas y aterrizaje (más altas) · filas 2-3 muerte (cae de espaldas y queda tumbado)
  (Las hojas 3-5 son la propuesta de Eduardo de docs/propuestas/poses_extra, aceptada el 16-10-2026.)
Las poses se localizan solas: cada pose es una mancha grande; las filas se ordenan por altura y, si dos
poses se tocan (el arma de una toca los pies de la de arriba), se parten por la franja más vacía.

Para que encajen con el resto del juego (pixel art de verdad, no ilustraciones reducidas):
- el fogonazo dibujado se quita de cada pose y su sitio pasa a ser la boca del arma (el juego dibuja el suyo);
- todas las poses de un soldado comparten una paleta de PALETTE colores, sin tramado;
- cada pose lleva un contorno oscuro de 1 px, como los sprites hechos por código;
- en las carreras el cuerpo se alinea por el torso (no por las botas) para que no tiemble de lado.

Salida: assets/sprites/player_<id>_body.png (una fila por animación, fotogramas FWxFH con los pies en FEET)
        assets/sprites/player_<id>_body_meta.json (animaciones y boca del arma en cada dirección)
player.gd usa estas hojas en lugar de piernas + torso cuando existen.

Si existe tools/sprites/heroes/<id>/<anim>/<anim>_NN.png (fotogramas sueltos ya a escala, hechos por
chatgpt_frames.py y retocables a mano), esa animación se monta con ellos en lugar de con las poses de las hojas.
Esos fotogramas no se tocan (ya son pixel art); si son del tamaño viejo (LEGACY) se recolocan por los pies.

Uso: python tools/sprites/heroes_sheets.py
"""
import glob
import json
import os

from PIL import Image, ImageFilter

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "chatgpt")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")
FRAMES = os.path.join(HERE, "heroes")

HEROES = ["eduardo", "eder", "junnie"]
FW, FH = 96, 80       # más alto que antes para que quepa el arma apuntando arriba
FEET = (40, 76)       # pies (centro de las piernas) dentro del fotograma
LEGACY = {(80, 60): (30, 58)}  # tamaño viejo de fotograma suelto -> sus pies
HEIGHT = 46           # alto en el juego del personaje quieto (el Presi mide ~44)
PALETTE = 48          # colores por soldado
INK = (18, 14, 16, 255)
FLASH_EDGE = 0.05    # parte mínima del fogonazo que toca el fondo (la piel da 0-0,01; el fuego 0,09 o más)

# poses tumbadas: se centran en el fotograma en lugar de alinear los pies
WIDE = ("prone", "die")
# poses de disparo: se les quita el fogonazo y cualquier chispa suelta
AIM_ANIMS = ("shoot", "prone", "up", "up_run", "diag_up", "diag_up_run", "diag_down")
# carreras: se alinean por el torso
TORSO_ALIGN = ("run", "up_run", "diag_up_run")
# animación: [(hoja, fila, columna), ...], fps, bucle
# En las de apuntar quieto, el fotograma 0 es la pose en reposo y el 1 la del retroceso al disparar.
ANIMS = {
	"idle": ([(1, 0, c) for c in range(4)], 6, True),
	"run": ([(1, 1, c) for c in range(4)], 12, True),
	"jump": ([(1, 2, 1), (1, 2, 2)], 1, False),
	"crouch": ([(1, 2, 0)], 1, True),
	"shoot": ([(1, 3, 0), (1, 3, 1), (1, 3, 2), (1, 3, 3)], 20, False),
	"throw": ([(2, 0, c) for c in range(4)], 14, False),
	"prone": ([(2, 1, 1), (2, 1, 2)], 1, False),
	"go_prone": ([(2, 1, 0)], 1, False),
	"die": ([(5, 2, c) for c in range(4)] + [(5, 3, c) for c in range(4)], 10, False),
	"win": ([(2, 2, c) for c in range(4)], 5, True),
	"knife": ([(2, 3, c) for c in range(4)], 18, False),
	"up": ([(3, 0, 3), (3, 0, 1)], 1, False),
	"up_run": ([(3, 1, c) for c in range(4)], 12, True),
	"diag_up": ([(4, 0, 3), (4, 0, 1)], 1, False),
	"diag_up_run": ([(4, 1, c) for c in range(4)], 12, True),
	"diag_down": ([(3, 2, 3), (3, 2, 1)], 1, False),
}
# boca del arma de cada dirección: animación de la que sale (la pose con el fogonazo más grande)
MUZZLE_FROM = {"shoot": "shoot", "up": "up", "diag_up": "diag_up", "diag_down": "diag_down", "prone": "prone"}

# Carreras al estilo Metal Slug: piernas de la carrera de 10 fotogramas (heroes/eduardo/run, hecha por un amigo
# de Eduardo) y, por encima de la cadera, el torso firme de la pose de apuntar (el arma no se mueve al correr).
RUN_LEGS = os.path.join(FRAMES, "eduardo", "run")
RUN_TORSO = {"run": "idle", "up_run": "up", "diag_up_run": "diag_up"}
RUN_FPS = 13
# Arrastrarse cuerpo a tierra: la pose tumbada con las piernas empujando (desplazamiento de la mitad de atrás)
CRAWL_DX = [0, 1, 2, 1]
CRAWL_FPS = 8
HIP = 17              # altura de la cadera sobre los pies: por debajo, piernas; por encima, torso
BOB = 2               # rebote máximo del torso al correr (px)
# Fogonazos de verdad (los que venían dibujados en las poses), pequeño y grande por dirección.
FLASH_SRC = {
	"fwd": [(1, 3, 1), (1, 3, 2)],
	"up": [(3, 0, 0), (3, 0, 1)],
	"diag_up": [(4, 0, 1), (4, 0, 2)],
	"diag_down": [(3, 2, 0), (3, 2, 1)],
}
FLASH_CELL = 40
# Punta del cañón en cada fotograma: dirección hacia la que apunta cada animación
TIP_DIR = {
	"idle": (1, 0), "run": (1, 0), "shoot": (1, 0), "jump": (1, 0), "prone": (1, 0), "crawl": (1, 0),
	"up": (0, -1), "up_run": (0, -1), "diag_up": (1, -1), "diag_up_run": (1, -1), "diag_down": (1, 1),
}       # cada fogonazo en una casilla de 40x40 con la boca del arma en el centro

# animaciones hechas con fotogramas sueltos: fps y duración relativa de cada fotograma (sustituyen a ANIMS)
LOOSE = {
	# correr (v18 = piernas de la v15/v16 y arco del arma redibujado), 10 fotogramas. A 13 fps el ciclo dura
	# 0,77 s, algo más pausado que a 16 (0,63 s, sin patinar); a cambio la bota apoyada patina ~1,5 px por fotograma.
	"run": (13, [1] * 10),
}


# soldados con ropa negra: el relleno negro se aclara a gris carbón para que se vean las líneas (pliegues,
# piernas al correr); las líneas, casi negras, se quedan como están
LIFT_BLACKS = {"junnie"}
LINE_MAX = 12     # por debajo de este brillo es línea (no se toca)
LIFT_TOP = 90     # hasta este brillo se aclara


def lift_blacks(im):
	"""Aclara los negros y grises oscuros sin color (ropa, botas, arma) que no son líneas."""
	im = im.copy()
	px = im.load()
	for y in range(im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			if not a:
				continue
			hi, lo = max(r, g, b), min(r, g, b)
			v = (r + g + b) / 3
			# sin color: el pelo (castaño) tiene más rojo que azul y no se toca
			if LINE_MAX <= v <= LIFT_TOP and hi - lo <= 8 and r - b <= 4:
				t = 30 + (v - LINE_MAX) * 1.1
				px[x, y] = (round(t), round(t + 2), round(t + 10), a)  # carbón azulado
	return im


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


def _split_tallest(big, mask, split):
	"""Parte en dos la mancha más alta (dos poses pegadas una encima de otra) por su fila más vacía."""
	heights = sorted(b[3] - b[1] for b in big)
	median = heights[len(heights) // 2]
	b = max(big, key=lambda p: p[3] - p[1])
	if b[3] - b[1] < median * 1.5:
		return False
	lo, hi = b[1] + (b[3] - b[1]) // 3, b[1] + 2 * (b[3] - b[1]) // 3
	cut = min(range(lo, hi), key=lambda y: sum(1 for x in range(b[0], b[2]) if mask.getpixel((x, y))))
	big.remove(b)
	split.append(b)
	for y0, y1 in ((b[1], cut), (cut, b[3])):
		bb = mask.crop((b[0], y0, b[2], y1)).getbbox()
		big.append([b[0] + bb[0], y0 + bb[1], b[0] + bb[2], y0 + bb[3], b[4] // 2])
	return True


def _split_widest(big, mask, split):
	"""Parte en dos la mancha más ancha (dos poses tumbadas pegadas de lado) por su columna más vacía."""
	widths = sorted(b[2] - b[0] for b in big)
	median = widths[len(widths) // 2]
	b = max(big, key=lambda p: p[2] - p[0])
	if b[2] - b[0] < median * 1.5:
		return False
	lo, hi = b[0] + (b[2] - b[0]) // 3, b[0] + 2 * (b[2] - b[0]) // 3
	cut = min(range(lo, hi), key=lambda x: sum(1 for y in range(b[1], b[3]) if mask.getpixel((x, y))))
	big.remove(b)
	split.append(b)
	for x0, x1 in ((b[0], cut), (cut, b[2])):
		bb = mask.crop((x0, b[1], x1, b[3])).getbbox()
		big.append([x0 + bb[0], b[1] + bb[1], x0 + bb[2], b[1] + bb[3], b[4] // 2])
	return True


def cells(path, rows=4, cols=4):
	"""Recorta las poses de una hoja: devuelve cells[fila][columna] = imagen RGBA.
	Las manchas pequeñas (granada en el aire, estela, fogonazo, cuerdas) se unen a la pose más cercana."""
	im = Image.open(path).convert("RGBA")
	mask = alpha_mask(im)
	found = blobs(mask)
	n = rows * cols
	big = sorted([b for b in found if b[4] > 400], key=lambda b: -b[4])
	if len(big) > n:
		# el paracaídas sale como mancha aparte: se queda con la pose de debajo
		big = big[:n]
	split = []  # manchas originales que se partieron (no se vuelven a unir)
	while len(big) < n:
		# se parte la mancha más desproporcionada: la más alta (poses una encima de otra) o la más ancha
		# (poses tumbadas pegadas de lado)
		hs = sorted(q[3] - q[1] for q in big)
		ws = sorted(q[2] - q[0] for q in big)
		tall = max(q[3] - q[1] for q in big) / hs[len(hs) // 2]
		wide = max(q[2] - q[0] for q in big) / ws[len(ws) // 2]
		first, second = (_split_widest, _split_tallest) if wide > tall else (_split_tallest, _split_widest)
		if not (first(big, mask, split) or second(big, mask, split)):
			break
	if len(big) != n:
		raise SystemExit("%s: se esperaban %d poses y hay %d" % (path, n, len(big)))
	for b in found:
		if b in big or b in split or b[4] < 3:
			continue
		cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
		near = min(big, key=lambda p: max(p[0] - cx, 0, cx - p[2]) + max(p[1] - cy, 0, cy - p[3]))
		near[0], near[1], near[2], near[3] = min(near[0], b[0]), min(near[1], b[1]), max(near[2], b[2]), max(near[3], b[3])
	# filas por orden de altura (las filas pueden medir distinto), columnas por orden horizontal
	by_y = sorted(big, key=lambda p: (p[1] + p[3]) / 2)
	grid = []
	for r in range(rows):
		row = sorted(by_y[r * cols:(r + 1) * cols], key=lambda p: (p[0] + p[2]) / 2)
		grid.append([im.crop((max(p[0] - 2, 0), max(p[1] - 2, 0), p[2] + 2, p[3] + 2)) for p in row])
	return grid


def feet_x(cell):
	"""Centro horizontal de las botas: los píxeles opacos de la franja inferior."""
	m = alpha_mask(cell)
	b = m.getbbox()
	band = m.crop((b[0], b[3] - max(8, (b[3] - b[1]) // 10), b[2], b[3]))
	bb = band.getbbox()
	return b[0] + (bb[0] + bb[2]) / 2.0


def torso_x(cell):
	"""Centro horizontal de la cabeza y los hombros (franja superior), para alinear las carreras."""
	m = alpha_mask(cell)
	b = m.getbbox()
	band = m.crop((b[0], b[1], b[2], b[1] + (b[3] - b[1]) * 35 // 100))
	bb = band.getbbox()
	return b[0] + (bb[0] + bb[2]) / 2.0


def _is_flash(r, g, b, a):
	"""Colores del fogonazo: naranja muy saturado, amarillo intenso o blanco caliente (la piel tiene más azul)."""
	if a < 100:
		return False
	return (r > 225 and g > 90 and b < 75) or (r > 240 and g > 200 and b < 160 and r - b > 90) or (r > 245 and g > 245 and b > 215)


def strip_flash(cell):
	"""Quita el fogonazo de la pose. Devuelve (pose sin fogonazo, boca del arma o None, tamaño, fogonazo solo).
	El fogonazo es la mancha de colores de fuego que toca el fondo (sale fuera de la silueta); la piel,
	aunque tenga colores parecidos, siempre queda dentro del cuerpo. La boca es el píxel del fogonazo más
	cercano al centro del cuerpo (donde el fuego toca el cañón)."""
	im = cell.copy()
	px = im.load()
	w, h = im.size
	hot = [[_is_flash(*px[x, y]) for x in range(w)] for y in range(h)]
	seen = [[False] * w for _ in range(h)]

	def outside(x, y):
		return not (0 <= x < w and 0 <= y < h) or px[x, y][3] < 100

	comps = []
	for y in range(h):
		for x in range(w):
			if not hot[y][x] or seen[y][x]:
				continue
			stack, comp = [(x, y)], []
			seen[y][x] = True
			while stack:
				cx, cy = stack.pop()
				comp.append((cx, cy))
				for nx in (cx - 1, cx, cx + 1):
					for ny in (cy - 1, cy, cy + 1):
						if 0 <= nx < w and 0 <= ny < h and hot[ny][nx] and not seen[ny][nx]:
							seen[ny][nx] = True
							stack.append((nx, ny))
			edge = sum(1 for (cx, cy) in comp if any(outside(cx + dx, cy + dy) for dx in (-3, 0, 3) for dy in (-3, 0, 3)))
			if len(comp) >= 30 and edge / len(comp) >= FLASH_EDGE:
				comps.append(comp)
	if not comps:
		return im, None, 0, None
	comps.sort(key=len, reverse=True)
	main = comps[0]
	mx = sum(p[0] for p in main) / len(main)
	my = sum(p[1] for p in main) / len(main)
	# chispas sueltas del mismo fogonazo
	gone = set(main)
	for comp in comps[1:]:
		if min(abs(p[0] - mx) + abs(p[1] - my) for p in comp) < 90:
			gone.update(comp)
	# halo alrededor (3 px): anaranjado o claro, sin tocar el gris oscuro del arma
	halo = set()
	for (x, y) in gone:
		for nx in range(x - 3, x + 4):
			for ny in range(y - 3, y + 4):
				if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in gone:
					r, g, b, a = px[nx, ny]
					if a > 0 and ((r > 150 and r > g > b and r - b > 70) or min(r, g, b) > 170):
						halo.add((nx, ny))
	body = [(x, y) for y in range(h) for x in range(w) if px[x, y][3] > 100 and (x, y) not in gone]
	bx = sum(p[0] for p in body) / len(body)
	by = sum(p[1] for p in body) / len(body)
	muzzle = min(main, key=lambda p: (p[0] - bx) ** 2 + (p[1] - by) ** 2)
	fire = Image.new("RGBA", im.size, (0, 0, 0, 0))
	fpx = fire.load()
	for p in gone | halo:
		fpx[p] = px[p]
		px[p] = (0, 0, 0, 0)
	return im, muzzle, len(main), fire


def keep_largest(im):
	"""Deja solo la figura principal (quita chispas sueltas que quedan del fogonazo)."""
	px = im.load()
	w, h = im.size
	seen = set()
	parts = []
	for y in range(h):
		for x in range(w):
			if px[x, y][3] == 0 or (x, y) in seen:
				continue
			stack, part = [(x, y)], []
			seen.add((x, y))
			while stack:
				cx, cy = stack.pop()
				part.append((cx, cy))
				for nx in (cx - 1, cx, cx + 1):
					for ny in (cy - 1, cy, cy + 1):
						if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and (nx, ny) not in seen:
							seen.add((nx, ny))
							stack.append((nx, ny))
			parts.append(part)
	parts.sort(key=len, reverse=True)
	for part in parts[1:]:
		for p in part:
			px[p] = (0, 0, 0, 0)
	return im


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


def to_palette(im, pal):
	"""Pasa la pose a la paleta del soldado (sin tramado) y le pone el contorno oscuro de 1 px."""
	a = im.getchannel("A")
	q = im.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")
	q.putalpha(a)
	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	out.paste(Image.new("RGBA", im.size, INK), mask=a.filter(ImageFilter.MaxFilter(3)))
	out.alpha_composite(q)
	return out


def _is_gun(r, g, b):
	"""Gris del arma (poco color, ni negro del contorno ni claro)."""
	return max(r, g, b) - min(r, g, b) < 22 and 40 < (r + g + b) / 3 < 150


def _pants_to_gray(r, g, b):
	"""Pantalón caqui de Eduardo -> gris de Eder (misma luz). Las botas (marrón más rojizo) no se tocan."""
	if r > g > b and g >= 0.69 * r and (r + g + b) / 3 >= 60:
		v = int((r + g + b) / 3 * 0.42)
		return (v + 18, v + 16, v + 24)
	return None


def _drop_specks(im, min_px):
	"""Quita las manchas sueltas de menos de min_px píxeles (restos del arma que llevaban las piernas)."""
	px = im.load()
	w, h = im.size
	seen = set()
	for y in range(h):
		for x in range(w):
			if px[x, y][3] == 0 or (x, y) in seen:
				continue
			stack, part = [(x, y)], []
			seen.add((x, y))
			while stack:
				cx, cy = stack.pop()
				part.append((cx, cy))
				for nx in (cx - 1, cx, cx + 1):
					for ny in (cy - 1, cy, cy + 1):
						if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and (nx, ny) not in seen:
							seen.add((nx, ny))
							stack.append((nx, ny))
			if len(part) < min_px:
				for q in part:
					px[q] = (0, 0, 0, 0)


def run_frames(torso, hero):
	"""Carrera: piernas de RUN_LEGS (sin el arma que llevaban) + torso fijo con un pequeño rebote.
	Devuelve (fotogramas, rebote de cada uno)."""
	paths = sorted(glob.glob(os.path.join(RUN_LEGS, "run_[0-9][0-9].png")))
	legs = []
	for p in paths:
		im = Image.open(p).convert("RGBA")
		lf = LEGACY.get(im.size, FEET)
		f = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		f.alpha_composite(im, (FEET[0] - lf[0], FEET[1] - lf[1]))
		legs.append(f)
	top0 = legs[0].getbbox()[1]
	torso_part = torso.crop((0, 0, FW, FEET[1] - HIP))
	frames, bobs = [], []
	for f in legs:
		bob = max(-BOB, min(BOB, f.getbbox()[1] - top0))
		cut = FEET[1] - HIP + bob
		px = f.load()
		for y in range(FH):
			for x in range(FW):
				r, g, b, a = px[x, y]
				if a == 0:
					continue
				# fuera: lo que queda por encima de la cadera, el arma inclinada y el contorno (se rehace)
				if y < cut or _is_gun(r, g, b) or (r + g + b) / 3 < 40:
					px[x, y] = (0, 0, 0, 0)
				elif hero != "eduardo" and y < FEET[1] - 6:
					c = _pants_to_gray(r, g, b)
					if c:
						px[x, y] = c + (255,)
		_drop_specks(f, 8)
		out = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		out.paste(Image.new("RGBA", (FW, FH), INK), mask=f.getchannel("A").filter(ImageFilter.MaxFilter(3)))
		out.alpha_composite(f)
		out.alpha_composite(torso_part, (0, bob))
		frames.append(out)
		bobs.append(bob)
	return frames, bobs


def gun_tip(frame, d):
	"""Punta del cañón: el píxel gris del arma (o su contorno) más lejos en la dirección d, sin contar
	las botas. Coordenadas relativas a los pies."""
	px = frame.load()
	best, best_v = None, None
	for y in range(FEET[1] - 5):
		for x in range(FW):
			r, g, b, a = px[x, y]
			if a == 0 or max(r, g, b) - min(r, g, b) > 28 or (r + g + b) / 3 > 130:
				continue
			v = x * d[0] + y * d[1]
			if best_v is None or v > best_v:
				best, best_v = (x, y), v
	return [best[0] - FEET[0], best[1] - FEET[1]]


def _add_row(sheet, frames):
	"""Devuelve la hoja con una fila más al final."""
	out = Image.new("RGBA", (sheet.width, sheet.height + FH), (0, 0, 0, 0))
	out.alpha_composite(sheet)
	for col, f in enumerate(frames):
		out.alpha_composite(f, (col * FW, sheet.height))
	return out


def crawl_frames(prone):
	"""Arrastrarse: la mitad de atrás de la pose tumbada (piernas) avanza y vuelve; el resto queda quieto."""
	b = prone.getbbox()
	split = b[0] + (b[2] - b[0]) * 45 // 100
	back = prone.crop((0, 0, split, FH))
	front = prone.crop((split, 0, FW, FH))
	out = []
	for dx in CRAWL_DX:
		f = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		f.alpha_composite(back, (dx, 0))
		f.alpha_composite(front, (split, 0))
		out.append(f)
	return out


def flash_sheet(hero, sheets, scale):
	"""Hoja de fogonazos: una fila por dirección, pequeño y grande, con la boca del arma en el centro."""
	half = FLASH_CELL // 2
	sheet = Image.new("RGBA", (FLASH_CELL * 2, FLASH_CELL * len(FLASH_SRC)), (0, 0, 0, 0))
	rows = {}
	for row, (key, srcs) in enumerate(FLASH_SRC.items()):
		found = []
		for (s, r, c) in srcs:
			_, mz, size, fire = strip_flash(sheets[s][r][c])
			if mz is None:
				continue
			small = clean(fire.resize((max(1, round(fire.width * scale)), max(1, round(fire.height * scale))), Image.LANCZOS))
			cell = Image.new("RGBA", (FLASH_CELL, FLASH_CELL), (0, 0, 0, 0))
			cell.paste(small, (round(half - mz[0] * scale), round(half - mz[1] * scale)), small)
			found.append((size, cell))
		found.sort(key=lambda f: f[0])
		for col, (_, cell) in enumerate(found[:2]):
			sheet.alpha_composite(cell, (col * FLASH_CELL, row * FLASH_CELL))
		rows[key] = row
	a = sheet.getchannel("A")
	q = sheet.convert("RGB").quantize(colors=12, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
	q.putalpha(a)
	q.save(os.path.join(OUT, "player_%s_flash.png" % hero))
	return {"frame": [FLASH_CELL, FLASH_CELL], "anchor": [half, half], "rows": rows}


def loose_frames(hero, anim):
	"""Fotogramas sueltos de heroes/<id>/<anim>/ en orden, o None si no hay."""
	paths = sorted(glob.glob(os.path.join(FRAMES, hero, anim, "%s_[0-9][0-9].png" % anim)))
	return [Image.open(p).convert("RGBA") for p in paths] or None


def build(hero):
	sheets = {}
	for path in sorted(glob.glob(os.path.join(SRC, "sprites_%s_[0-9].png" % hero))):
		sheets[int(path[-5])] = cells(path)
	idle = sheets[1][0][0]
	ib = alpha_mask(idle).getbbox()
	scale = HEIGHT / float(ib[3] - ib[1])
	loose = {name: loose_frames(hero, name) for name in ANIMS}
	if hero == "eduardo":
		loose["run"] = None  # heroes/eduardo/run son las piernas (RUN_LEGS) de las carreras de Eduardo y Eder
	anims = {n: v for n, v in ANIMS.items() if loose[n] or all(s in sheets for s, _, _ in v[0])}

	# 1) cada pose: sin fogonazo, reducida y colocada en su fotograma (aún con todos sus colores)
	placed = {}   # nombre -> [(fotograma, boca en coordenadas del fotograma o None)]
	for name, (frames, fps, loop) in anims.items():
		if loose[name]:
			continue
		placed[name] = []
		for (s, r, c) in frames:
			cell, mz, size, _ = strip_flash(sheets[s][r][c])
			if hero in LIFT_BLACKS:
				cell = lift_blacks(cell)
			b = alpha_mask(cell).getbbox()
			small = clean(cell.resize((max(1, round(cell.width * scale)), max(1, round(cell.height * scale))), Image.LANCZOS))
			if name in AIM_ANIMS:
				small = keep_largest(small)
			if name in WIDE:
				ox = round(FW / 2 - (b[0] + b[2]) / 2 * scale)
			elif name in TORSO_ALIGN:
				ox = round(FEET[0] - torso_x(cell) * scale)
			else:
				ox = round(FEET[0] - feet_x(cell) * scale)
			oy = round(FEET[1] - b[3] * scale) - 1  # -1: el contorno de las botas queda sobre el suelo
			frame = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
			frame.paste(small, (ox, oy), small)
			placed[name].append((frame, None if mz is None else (mz[0] * scale + ox, mz[1] * scale + oy, size)))

	# 2) paleta común del soldado a partir de todas sus poses
	strip = Image.new("RGB", (FW * sum(len(v) for v in placed.values()), FH), (0, 0, 0))
	x = 0
	for frames in placed.values():
		for frame, _ in frames:
			strip.paste(frame.convert("RGB"), (x, 0), frame)
			x += FW
	opaque = [px for px in strip.get_flattened_data() if px != (0, 0, 0)]
	sample = Image.new("RGB", (len(opaque), 1))
	sample.putdata(opaque)
	pal = sample.quantize(colors=PALETTE, method=Image.Quantize.MEDIANCUT, kmeans=3)

	# 3) hoja final
	n_legs = len(glob.glob(os.path.join(RUN_LEGS, "run_[0-9][0-9].png")))
	cols = max([len(loose[n]) if loose[n] else len(v[0]) for n, v in anims.items()] + [n_legs])
	sheet = Image.new("RGBA", (FW * cols, FH * len(anims)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "feet": list(FEET), "anims": {}, "muzzle": {}}
	for row, (name, (frames, fps, loop)) in enumerate(anims.items()):
		if loose[name]:
			for col, frame in enumerate(loose[name]):
				lf = LEGACY.get(frame.size, FEET)
				sheet.alpha_composite(frame, (col * FW + FEET[0] - lf[0], row * FH + FEET[1] - lf[1]))
			meta["anims"][name] = {"row": row, "frames": len(loose[name]), "fps": fps, "loop": loop}
			if name in LOOSE:
				meta["anims"][name]["fps"] = LOOSE[name][0]
				if len(LOOSE[name][1]) == len(loose[name]):
					meta["anims"][name]["durations"] = LOOSE[name][1]
			continue
		if name in RUN_TORSO:
			torso = to_palette(placed[RUN_TORSO[name]][0][0], pal)
			run, bobs = run_frames(torso, hero)
			for col, frame in enumerate(run):
				sheet.alpha_composite(frame, (col * FW, row * FH))
			meta["anims"][name] = {"row": row, "frames": len(run), "fps": RUN_FPS, "loop": True}
			meta.setdefault("bob", {})[name] = bobs
			continue
		for col, (frame, _) in enumerate(placed[name]):
			sheet.alpha_composite(to_palette(frame, pal), (col * FW, row * FH))
		meta["anims"][name] = {"row": row, "frames": len(frames), "fps": fps, "loop": loop}

	# arrastrarse (sale de la pose tumbada ya en paleta)
	prone_row = meta["anims"]["prone"]["row"]
	crawl = crawl_frames(sheet.crop((0, prone_row * FH, FW, (prone_row + 1) * FH)))
	sheet = _add_row(sheet, crawl)
	meta["anims"]["crawl"] = {"row": sheet.height // FH - 1, "frames": len(crawl), "fps": CRAWL_FPS, "loop": True}

	# 4) boca del arma de cada dirección (relativa a los pies)
	for key, name in MUZZLE_FROM.items():
		points = [p for _, p in placed.get(name, []) if p]
		if points:
			p = max(points, key=lambda q: q[2])
			meta["muzzle"][key] = [round(p[0] - FEET[0]), round(p[1] - FEET[1])]
	# de frente (quieto y corriendo) y agachado: sin fogonazo; el píxel opaco más a la derecha a la altura del cañón
	def tip(anim, y0, y1):
		fr = sheet.crop((0, meta["anims"][anim]["row"] * FH, FW, (meta["anims"][anim]["row"] + 1) * FH))
		m = alpha_mask(fr)
		best = None
		for y in range(FEET[1] - y1, FEET[1] - y0):
			bb = m.crop((0, y, FW, y + 1)).getbbox()
			if bb and (best is None or bb[2] > best[0]):
				best = (bb[2], y)
		return [best[0] - FEET[0], best[1] - FEET[1]]
	meta["muzzle"]["fwd"] = tip("idle", 16, 36)
	meta["muzzle"]["crouch_fwd"] = tip("crouch", 8, 28)

	# punta del cañón en cada fotograma (el fogonazo sale de ahí aunque el arma se mueva)
	meta["tips"] = {}
	for name, d in TIP_DIR.items():
		a = meta["anims"].get(name)
		if a:
			meta["tips"][name] = [gun_tip(sheet.crop((c * FW, a["row"] * FH, (c + 1) * FW, (a["row"] + 1) * FH)), d)
				for c in range(a["frames"])]
	meta["flash"] = flash_sheet(hero, sheets, scale)
	sheet.save(os.path.join(OUT, "player_%s_body.png" % hero))
	with open(os.path.join(OUT, "player_%s_body_meta.json" % hero), "w", encoding="utf-8", newline="\n") as f:
		json.dump(meta, f, indent=1)
	print("ok", hero, "escala %.3f" % scale, "animaciones", len(anims), "bocas", meta["muzzle"])


if __name__ == "__main__":
	for hero_id in HEROES:
		build(hero_id)
