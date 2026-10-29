"""Estación y tren de la 1.1 (tramo 3b, pedido de Eduardo, 28-10-2026). Dibujos de ChatGPT sobre fondo magenta.

Entrada (tools/sprites/chatgpt/tren/):
  tren_kit.png      el tren normal, avanzando a la izquierda: locomotora con ténder, vagón de pasajeros, plataforma
                    con cajones y bolsas, vagón de carga con la puerta abierta y furgón de cola
  estacion_kit.png  vías, andén, barrera levantada y bajada, boletería, tanque de agua, señal del paso a nivel y cartel
  (tren_militar_descartado.png: la primera versión, blindada; Eduardo pidió un tren normal)
Salida (assets/sprites/):
  tren_<vagon>.png      cada vagón (locomotora, pasajeros, plataforma, carga, cola)
  estacion_<pieza>.png  cada pieza de la estación (vias y anden se repiten en horizontal sin corte)
  tren_meta.json        tamaños, dónde apoyan las ruedas, las ventanas del vagón de pasajeros, la puerta del de carga, la
                        chimenea de la locomotora, y la fila de las vías donde apoyan las ruedas

Uso: python tools/sprites/tren.py
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from helicoptero import manchas  # noqa: E402
from objetos import nitido, sin_magenta  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/tren"
OUT = ROOT / "assets/sprites"
VAGONES = ["locomotora", "pasajeros", "plataforma", "carga", "cola"]
LOCO_ALTO = 80     # alto de la locomotora en el juego (los vagones a la misma escala)
# piezas de la estación: centro aproximado en estacion_kit.png (para reconocerlas) y alto en el juego
ESTACION = {
	"vias": ((521, 201), 26),
	"anden": ((532, 407), 40),
	"barrera_arriba": ((1178, 261), None),  # a la escala de la bajada
	"barrera_abajo": ((1450, 396), 40),
	"boleteria": ((337, 771), 118),
	"tanque": ((869, 760), 128),
	"senal": ((1157, 782), 74),
	"cartel": ((1466, 831), 52),
}
FUNDE = 12


def piezas(im, minimo):
	"""Piezas separadas (manchas conectadas a un cuarto del tamaño); las sueltas chicas van con la grande más cercana.
	Devuelve [(caja en la imagen, pieza recortada)]."""
	k = 4
	a = np.array(im.getchannel("A").resize((im.width // k, im.height // k), Image.BOX)) > 100
	lab, n = manchas(a)
	tam = {i: int((lab == i).sum()) for i in range(1, n + 1)}
	grandes = [i for i in tam if tam[i] >= minimo]
	cent = {i: np.argwhere(lab == i).mean(axis=0) for i in range(1, n + 1)}
	dueno = {}
	for i in range(1, n + 1):
		dueno[i] = i if i in grandes else min(grandes, key=lambda g: np.linalg.norm(cent[i] - cent[g]))
	full = np.array(im)
	lab_big = np.kron(lab, np.ones((k, k), int))
	lab_big = np.pad(lab_big, ((0, im.height - lab_big.shape[0]), (0, im.width - lab_big.shape[1])), mode="edge")
	out = []
	for g in grandes:
		ids = [i for i in dueno if dueno[i] == g]
		mask = np.isin(lab_big, ids)
		# los bordes finos que se perdieron al reducir: lo opaco a 1 celda de la mancha
		px = full.copy()
		px[~mask] = 0
		p = Image.fromarray(px, "RGBA")
		box = p.getchannel("A").getbbox()
		out.append((box, p.crop(box)))
	return out


def por_enganches(im, n):
	"""Corta el tren en n vagones por los enganches: tramos de columnas donde lo opaco es muy bajo (solo el gancho)."""
	a = np.array(im.getchannel("A")) > 0
	alto = a.sum(axis=0)
	xs = np.where(alto > 0)[0]
	x0, x1 = xs[0], xs[-1] + 1
	fino = alto < 0.12 * alto.max()
	tramos = []
	x = x0
	while x < x1:
		if fino[x]:
			j = x
			while j < x1 and fino[j]:
				j += 1
			tramos.append((x, j))
			x = j
		else:
			x += 1
	# los n - 1 tramos finos más anchos son los enganches
	cortes = sorted(sorted(tramos, key=lambda t: t[0] - t[1])[:n - 1])
	bordes = [x0] + [(a0 + b0) // 2 for a0, b0 in cortes] + [x1]
	out = []
	for i in range(n):
		p = im.crop((bordes[i], 0, bordes[i + 1], im.height))
		box = p.getchannel("A").getbbox()
		out.append(((bordes[i] + box[0], box[1], bordes[i] + box[2], box[3]), p.crop(box)))
	return out


def escala(im, s):
	return nitido(im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS))


def sin_corte(im):
	w = im.width - FUNDE
	out = im.crop((0, 0, w, im.height))
	for i in range(FUNDE):
		t = (i + 1) / (FUNDE + 1)
		out.paste(Image.blend(im.crop((w + i, 0, w + i + 1, im.height)), im.crop((i, 0, i + 1, im.height)), t), (i, 0))
	return out


def huecos(im, fila0, fila1, oscuro=60, minimo=3):
	"""Rectángulos oscuros (ventanas, puerta) entre las filas fila0 y fila1: tramos de columnas con mayoría oscura."""
	a = np.array(im).astype(int)
	lum = a[..., :3].mean(axis=2)
	banda = (lum[fila0:fila1] < oscuro) & (a[fila0:fila1, :, 3] > 0)
	cols = banda.mean(axis=0) > 0.45
	out = []
	x = 0
	while x < len(cols):
		if cols[x]:
			x0 = x
			while x < len(cols) and cols[x]:
				x += 1
			if x - x0 >= minimo:
				rows = np.where(banda[:, x0:x].mean(axis=1) > 0.4)[0]
				out.append([int(x0), int(fila0 + rows[0]), int(x), int(fila0 + rows[-1] + 1)])
		x += 1
	return out


def main():
	meta = {"vagones": {}, "estacion": {}}
	# tren
	tren = sin_magenta(Image.open(SRC / "tren_kit.png"))
	ps = por_enganches(tren, len(VAGONES))
	s = LOCO_ALTO / ps[0][1].height
	for name, (box, p) in zip(VAGONES, ps):
		im = escala(p, s)
		im.save(OUT / f"tren_{name}.png")
		info = {"size": list(im.size)}
		if name == "pasajeros":
			h = im.height
			info["ventanas"] = huecos(im, int(h * 0.2), int(h * 0.6), minimo=8)  # las puertas de los extremos son más angostas
		elif name == "carga":
			h = im.height
			puertas = huecos(im, int(h * 0.15), int(h * 0.75), oscuro=50, minimo=8)
			info["puerta"] = max(puertas, key=lambda r: r[2] - r[0])
		elif name == "locomotora":
			a = np.array(im.getchannel("A")) > 0
			ys, xs = np.nonzero(a)
			top = ys.min()
			cx = xs[ys <= top + 2]
			info["chimenea"] = [int((cx.min() + cx.max()) // 2), int(top)]
		elif name == "plataforma":
			# la cubierta (donde están los cajones): la fila más alta con opaco en todo el ancho
			a = np.array(im.getchannel("A")) > 0
			llenas = [y for y in range(im.height) if a[y].mean() > 0.9]
			info["cubierta"] = int(llenas[0]) if llenas else int(im.height * 0.6)
		elif name == "cola":
			a = np.array(im.getchannel("A")) > 0
			llenas = [y for y in range(im.height) if a[y].mean() > 0.9]
			info["cubierta"] = int(llenas[0]) if llenas else int(im.height * 0.7)
		meta["vagones"][name] = info
	meta["escala"] = round(s, 4)
	# estación
	est = sin_magenta(Image.open(SRC / "estacion_kit.png"))
	ps = piezas(est, 300)
	asignadas = {}
	for name, ((cx, cy), _) in ESTACION.items():
		box, p = min(ps, key=lambda q: (((q[0][0] + q[0][2]) / 2 - cx) ** 2 + ((q[0][1] + q[0][3]) / 2 - cy) ** 2))
		asignadas[name] = p
	s_barrera = ESTACION["barrera_abajo"][1] / asignadas["barrera_abajo"].height
	for name, (_, alto) in ESTACION.items():
		p = asignadas[name]
		k = s_barrera if alto is None else alto / p.height
		im = escala(p, k)
		if name in ("vias", "anden"):
			# los bordes de la tira (irregulares) fuera, y que se repita sin corte
			im = sin_corte(im.crop((3, 0, im.width - 3, im.height)))
		im.save(OUT / f"estacion_{name}.png")
		meta["estacion"][name] = {"size": list(im.size)}
		if name.startswith("barrera"):
			# x del centro del poste (la base, abajo): las dos versiones se alinean por ahí
			b = np.array(im.getchannel("A"))[-4:] > 0
			xs = np.nonzero(b.any(axis=0))[0]
			meta["estacion"][name]["poste"] = int((xs[0] + xs[-1]) // 2)
	# las ruedas apoyan en el riel de delante (el de abajo en la tira de las vías): la fila clara más baja
	v = np.array(Image.open(OUT / "estacion_vias.png")).astype(int)
	lum = v[..., :3].mean(axis=2).mean(axis=1)
	meta["estacion"]["vias"]["riel"] = int(np.argmax(lum[len(lum) // 2:]) + len(lum) // 2)
	(OUT / "tren_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print(json.dumps(meta, indent=1))


if __name__ == "__main__":
	main()
