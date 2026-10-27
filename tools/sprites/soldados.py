"""Soldado enemigo de Argentina (proporciones de Metal Slug, como los héroes), dibujado por Eduardo con ChatGPT.

Fuente: tools/sprites/chatgpt/soldados/poses_1..3.png (el mismo soldado joven, mirando a la izquierda, fondo
transparente; caras.png / caras_v2.png son las 5 caras de referencia):
  poses_1: correr, apuntar al frente, en diagonal hacia arriba, hacia arriba
  poses_2: en guardia (fusil en diagonal hacia abajo), preparar granada, lanzar granada, asustado
  poses_3: recibe el disparo, cae de espaldas, muerto en el suelo
Ciclo de correr: PixelLab (animate_image) a partir de la pose de correr: tools/sprites/pixellab/soldados/
run_base.png -> run.png (tira de 9 fotogramas de BASE x BASE; el 0 es la base).

Salida: assets/sprites/soldier_ar.png + soldier_ar_meta.json (filas como soldier_meta.json, más "die",
y la boca del fusil de cada pose de apuntar). Mirando a la derecha, como el resto de sprites.

Uso: python tools/sprites/soldados.py base | juego
"""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from heroes_sheets import blobs  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/soldados"
PL = ROOT / "tools/sprites/pixellab/soldados"
OUT = ROOT / "assets/sprites"

FW, FH = 80, 64
FEET = (40, 62)
ESCALA = 48 / 510      # la pose de apuntar al frente mide 48 px, como Eduardo
BASE = 128             # lienzo para PixelLab (el doble de la escala del juego)


def poses(n):
	im = Image.open(SRC / f"poses_{n}.png").convert("RGBA")
	mask = im.getchannel("A").point(lambda v: 255 if v > 100 else 0)
	bs = sorted([b for b in blobs(mask) if b[4] > 2000], key=lambda b: b[0])  # fuera la granada en el aire
	out = []
	for b in bs:
		f = im.crop(b[:4])
		# solo la figura: lo que asoma de la pose vecina en el recorte se borra (relleno desde un píxel suyo)
		m = f.getchannel("A").point(lambda v: 255 if v > 100 else 0)
		seed = next((x, y) for y in range(m.height - 1, 0, -1) for x in range(m.width // 3, m.width) if m.getpixel((x, y)))
		ImageDraw.floodfill(m, seed, 128)
		f.putalpha(Image.eval(m, lambda v: 255 if v == 128 else 0))
		out.append(f.crop(f.getchannel("A").getbbox()))
	return out


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def escala(f, s=ESCALA):
	return nitido(f.resize((max(1, round(f.width * s)), max(1, round(f.height * s))), Image.LANCZOS))


def pies_x(f, tumbado=False):
	"""x del centro de los pies (de las botas, abajo del todo), para alinear las poses."""
	if tumbado:
		return f.width / 2
	a = f.getchannel("A")
	h = f.height
	band = a.crop((0, int(h * 0.82), f.width, h)).getbbox()
	return (band[0] + band[2]) / 2 if band else f.width / 2


def celda(f, tumbado=False):
	"""Pose escalada (mirando a la izquierda) -> celda FWxFH mirando a la derecha con los pies en FEET."""
	f = f.transpose(Image.FLIP_LEFT_RIGHT)
	c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
	x = round(FEET[0] - pies_x(f, tumbado))
	c.alpha_composite(f, (x, FEET[1] + 1 - f.height))
	return c


def boca(c, d):
	"""Punta del fusil en la celda: el píxel opaco más lejos en la dirección d (mirando a la derecha),
	por encima de las botas."""
	px = c.getchannel("A").load()
	best, bp = None, None
	for y in range(FEET[1] - 10):
		for x in range(FW):
			if px[x, y] > 128:
				v = x * d[0] + y * d[1]
				if best is None or v > best:
					best, bp = v, (x, y)
	return [bp[0] - FEET[0], bp[1] - FEET[1]]


def base():
	PL.mkdir(parents=True, exist_ok=True)
	run = poses(1)[0]
	s = ESCALA * BASE / FH
	f = escala(run, s)
	c = Image.new("RGBA", (BASE, BASE), (0, 0, 0, 0))
	c.alpha_composite(f, ((BASE - f.width) // 2, BASE - 4 - f.height))
	c.save(PL / "run_base.png")
	print("run_base.png", f.size)


def juego():
	p1, p2, p3 = poses(1), poses(2), poses(3)
	cell = lambda f, t=False: celda(escala(f), t)
	guardia = cell(p2[0])
	aims = [cell(p1[1]), cell(p1[2]), cell(p1[3]), guardia]
	# correr: fotogramas de PixelLab (si aún no están, la pose de correr sola)
	run_strip = PL / "run.png"
	if run_strip.exists():
		strip = Image.open(run_strip).convert("RGBA")
		# el cuerpo queda en su sitio en todos los fotogramas: se escalan enteros (128 -> 64) y la línea de los
		# pies (BASE-4) cae justo en FEET; así el ciclo no tiembla
		run = []
		for i in range(1, strip.width // BASE):
			fr = nitido(strip.crop((i * BASE, 0, (i + 1) * BASE, BASE)).resize((FH, FH), Image.LANCZOS))
			c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
			c.alpha_composite(fr.transpose(Image.FLIP_LEFT_RIGHT), ((FW - FH) // 2, 0))
			run.append(c)
	else:
		run = [cell(p1[0])]
	run = (run * 8)[:8]
	panic = cell(p2[3])
	panic2 = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
	panic2.alpha_composite(panic.crop((0, 0, FW, FH - 1)), (0, 1))  # tiembla 1 px
	rows = {
		"idle": [guardia],
		"run": run,
		"panic": [panic, panic2],
		"throw": [cell(p2[1]), cell(p2[2])],
		"aim": aims,
		"flee": run,
		"die": [cell(p3[0]), cell(p3[1], True), cell(p3[2], True)],
	}
	sheet = Image.new("RGBA", (FW * 8, FH * len(rows)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "feet": list(FEET), "rows": {}, "aim_degrees": [0, -45, -90, 45]}
	for r, (name, frames) in enumerate(rows.items()):
		meta["rows"][name] = r
		for i, fr in enumerate(frames):
			sheet.alpha_composite(fr, (i * FW, r * FH))
	meta["muzzles"] = [boca(aims[0], (1, 0)), boca(aims[1], (1, -1)), boca(aims[2], (0, -1)), boca(aims[3], (1, 1))]
	meta["hand"] = [20, -30]  # de dónde sale la granada (mano adelantada al lanzar)
	sheet.save(OUT / "soldier_ar.png")
	(OUT / "soldier_ar_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("soldier_ar.png", sheet.size, "bocas", meta["muzzles"])


# --- caras: variantes del mismo soldado (caras_v2.png) pintadas a la escala del juego ---
# A 48 px de alto la cara mide unos 6x6 px: no se pega otra cabeza, se cambian sus colores en cada fotograma
# (piel, pelo) y se pinta el bigote o la barba. La dirección de la cara sale de la gorra: "abajo" va de la gorra
# al centro de la cara (así también funciona en las poses de muerte, tumbado) y "delante" es su perpendicular.
VARIANTES = {
	1: {"pelo": "negro", "piel": "tostada", "bigote": True},
	2: {"pelo": "negro", "piel": "morena"},
	3: {"pelo": "canoso", "barba": "canosa"},
	4: {"pelo": "rojo", "barba": "rojiza"},
}


def _hsv(c):
	import colorsys
	return colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)


def _rgb(h, s, v, a=255):
	import colorsys
	r, g, b = colorsys.hsv_to_rgb(h, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))
	return (round(r * 255), round(g * 255), round(b * 255), a)


def es_piel(c):
	h, s, v = _hsv(c)
	return c[3] > 0 and h < 0.088 and s > 0.3 and v > 0.5


def es_gorra(c):
	h, s, v = _hsv(c)
	return c[3] > 0 and 0.088 <= h <= 0.14 and s > 0.35 and v > 0.3


def es_pelo(c):
	h, s, v = _hsv(c)
	return c[3] > 0 and h < 0.075 and 0.1 <= s <= 0.65 and 0.12 <= v <= 0.5


def _componentes(px, w, h, pred):
	vistos, comps = set(), []
	for y in range(h):
		for x in range(w):
			if (x, y) in vistos or not pred(px[x, y]):
				continue
			pila, comp = [(x, y)], []
			vistos.add((x, y))
			while pila:
				p = pila.pop()
				comp.append(p)
				for q in ((p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)):
					if 0 <= q[0] < w and 0 <= q[1] < h and q not in vistos and pred(px[q]):
						vistos.add(q)
						pila.append(q)
			comps.append(comp)
	return comps


def _centro(ps):
	return (sum(p[0] for p in ps) / len(ps), sum(p[1] for p in ps) / len(ps))


def cara(fr, v):
	"""Fotograma FWxFH -> el mismo con la cara de la variante v."""
	fr = fr.copy()
	px = fr.load()
	w, h = fr.size
	gorras = [c for c in _componentes(px, w, h, es_gorra) if len(c) >= 6]
	pieles = [c for c in _componentes(px, w, h, es_piel) if len(c) >= 4]
	piel_toda = [p for c in pieles for p in c]
	if not gorras or not pieles:
		return fr
	# la gorra y la cara son la pareja (manchas de khaki y de piel) más grande que se toca (a 3 px o menos):
	# así no se confunden con el camuflaje ni con las manos
	def cerca(a, b):
		sb = set(b)
		return any((p[0] + dx, p[1] + dy) in sb for p in a for dx in range(-3, 4) for dy in range(-3, 4))
	pares = [(g, c) for g in gorras if len(g) >= 15 for c in pieles if cerca(c, g)]
	if not pares:
		return fr
	gorra, cara_ps = max(pares, key=lambda gc_: len(gc_[0]) + 2 * len(gc_[1]))
	gc = _centro(gorra)
	fc = _centro(cara_ps)
	ux, uy = fc[0] - gc[0], fc[1] - gc[1]
	n = (ux * ux + uy * uy) ** 0.5 or 1.0
	ux, uy = ux / n, uy / n
	fx, fy = uy, -ux  # delante
	ds = {p: (p[0] - gc[0]) * ux + (p[1] - gc[1]) * uy for p in cara_ps}
	d0, d1 = min(ds.values()), max(ds.values())
	dn = {p: (d - d0) / ((d1 - d0) or 1.0) for p, d in ds.items()}
	sv = {p: (p[0] - fc[0]) * fx + (p[1] - fc[1]) * fy for p in cara_ps}
	# pelo: lo que no es gorra ni piel junto a la cara, con color de pelo
	x0 = min(p[0] for p in cara_ps) - 4
	x1 = max(p[0] for p in cara_ps) + 4
	y0 = min(p[1] for p in cara_ps) - 4
	y1 = max(p[1] for p in cara_ps) + 4
	mid = (d0 + d1) / 2
	cand = {(x, y) for y in range(max(0, y0), min(h, y1 + 1)) for x in range(max(0, x0), min(w, x1 + 1))
		if es_pelo(px[x, y]) and (x - gc[0]) * ux + (y - gc[1]) * uy <= mid}
	# solo el pelo pegado a la cara (no el camuflaje ni la sombra de la gorra)
	cara_set = set(cara_ps)
	vec8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
	pila = [p for p in cand if any((p[0] + dx, p[1] + dy) in cara_set for dx, dy in vec8)]
	pelo = set(pila)
	while pila:
		p = pila.pop()
		for dx, dy in vec8:
			q = (p[0] + dx, p[1] + dy)
			if q in cand and q not in pelo:
				pelo.add(q)
				pila.append(q)
	op = VARIANTES[v]
	# piel (toda: cara y brazos)
	if op.get("piel"):
		for p in piel_toda:
			hh, s, val = _hsv(px[p])
			if op["piel"] == "morena":
				px[p] = _rgb(0.06, s * 0.9 + 0.05, val * 0.55 + 0.02)
			else:
				px[p] = _rgb(hh * 0.85, s * 1.05, val * 0.86)
	for p in pelo:
		hh, s, val = _hsv(px[p])
		if op["pelo"] == "negro":
			px[p] = _rgb(0.05, s * 0.5, val * 0.45)
		elif op["pelo"] == "canoso":
			g = round(110 + val * 230)
			px[p] = (min(255, g), min(255, g), min(255, g + 6), 255)
		elif op["pelo"] == "rojo":
			px[p] = _rgb(0.045, 0.72, 0.35 + val * 0.9)
	if op.get("barba"):
		for p in cara_ps:
			if dn[p] >= 0.6:
				hh, s, val = _hsv(px[p])
				if op["barba"] == "canosa":
					g = round(95 + val * 95) if dn[p] < 0.8 else round(120 + val * 85)
					px[p] = (min(255, g), min(255, g), min(255, g + 8), 255)
				else:
					px[p] = _rgb(0.05, 0.65, val * 0.68)
	if op.get("bigote"):
		frente = [p for p in cara_ps if sv[p] >= 0.0 and 0.5 <= dn[p] <= 0.72]
		for p in frente:
			px[p] = (34, 20, 14, 255)
	return fr


def caras():
	"""soldier_ar.png -> soldier_ar_1..4.png (las mismas filas con otra cara)."""
	sheet = Image.open(OUT / "soldier_ar.png").convert("RGBA")
	for v in VARIANTES:
		out = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
		for y in range(0, sheet.height, FH):
			for x in range(0, sheet.width, FW):
				fr = sheet.crop((x, y, x + FW, y + FH))
				if fr.getbbox():
					out.alpha_composite(cara(fr, v), (x, y))
		out.save(OUT / f"soldier_ar_{v}.png")
		print(f"soldier_ar_{v}.png")


if __name__ == "__main__":
	{"base": base, "juego": juego, "caras": caras}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
