"""Helicóptero de ataque enemigo (ejército argentino del juego) que sobrevuela el canal de la 1.1 y dispara hacia
abajo. Dibujado por ChatGPT a pedido de Eduardo (25-10-2026), con el piloto como los soldados del juego.

Entrada: tools/sprites/chatgpt/heli/heli_giro.png (fondo transparente): hoja de giro con el mismo helicóptero en 5
         posiciones de izquierda a derecha: perfil izquierda, tres cuartos izquierda, de frente, tres cuartos
         derecha, perfil derecha. Sin aspas (las dibuja el juego).
Salida (assets/sprites/):
  helicoptero.png        las 5 posiciones en fila, alineadas por el eje del rotor principal
  helicoptero_meta.json  tamaño de fotograma, eje del rotor, boca de la ametralladora y dirección del cañón de cada
                         posición, y el buje del rotor de cola (null de frente, que no se ve)

Uso: python tools/sprites/helicoptero.py
"""
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/heli/heli_giro.png"
OUT = ROOT / "assets/sprites"
# el helicóptero de perfil queda de unos 100 px de largo (los soldados miden ~48)
ESCALA = 0.215
MARGEN = 4


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def manchas(a):
	"""Etiqueta las manchas opacas conectadas (4 vecinos) de la máscara a. Devuelve (etiquetas, n)."""
	lab = np.zeros(a.shape, int)
	n = 0
	h, w = a.shape
	for y0, x0 in np.argwhere(a):
		if lab[y0, x0]:
			continue
		n += 1
		pila = [(y0, x0)]
		lab[y0, x0] = n
		while pila:
			y, x = pila.pop()
			for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
				if 0 <= yy < h and 0 <= xx < w and a[yy, xx] and not lab[yy, xx]:
					lab[yy, xx] = n
					pila.append((yy, xx))
	return lab, n


def poses(im):
	"""Separa las 5 posiciones (se tocan en columnas, no en píxeles): manchas conectadas a un cuarto del tamaño; las
	5 más grandes son los helicópteros y cada pieza suelta va con el más cercano."""
	k = 4
	a = np.array(im.getchannel("A").resize((im.width // k, im.height // k), Image.BOX)) > 100
	lab, n = manchas(a)
	tam = [(lab == i).sum() for i in range(1, n + 1)]
	grandes = sorted(range(1, n + 1), key=lambda i: -tam[i - 1])[:5]
	grandes.sort(key=lambda i: np.argwhere(lab == i)[:, 1].mean())
	centros = [np.argwhere(lab == i)[:, 1].mean() for i in grandes]
	dueno = np.zeros(n + 1, int)
	for i in range(1, n + 1):
		cx = np.argwhere(lab == i)[:, 1].mean()
		dueno[i] = int(np.argmin([abs(cx - c) for c in centros]))
	# a quién pertenece cada celda: la de su mancha o, si quedó vacía al reducir (bordes finos), la del más cercano
	cerca = np.argmin(np.abs(np.arange(lab.shape[1])[:, None] - np.array(centros)[None, :]), axis=1)
	quien = np.where(lab > 0, dueno[lab], cerca[None, :])
	full = np.array(im)
	quien = np.kron(quien, np.ones((k, k), int))
	quien = np.pad(quien, ((0, im.height - quien.shape[0]), (0, im.width - quien.shape[1])), mode="edge")
	out = []
	for j in range(5):
		mask = quien == j
		px = full.copy()
		px[~mask] = 0
		p = Image.fromarray(px)
		out.append(p.crop(p.getchannel("A").point(lambda v: 255 if v > 100 else 0).getbbox()))
	return out


def eje(p):
	"""(x, y) de la punta del mástil del rotor: el centro de los píxeles opacos de las filas de más arriba."""
	a = np.array(p.getchannel("A")) > 0
	ys = np.where(a.any(axis=1))[0]
	top = ys[0]
	xs = np.where(a[top:top + 3].any(axis=0))[0]
	return (xs[0] + xs[-1]) / 2.0, float(top)


def boca(p, lado):
	"""Punta del cañón: el píxel opaco más a la izquierda / derecha de la mitad de abajo, o el más bajo (de frente)."""
	a = np.array(p.getchannel("A")) > 0
	h = a.shape[0]
	pts = np.argwhere(a)
	if lado == 0:
		y, x = pts[pts[:, 0].argmax()]
		return [int(x), int(y)]
	pts = pts[pts[:, 0] > h * 0.55]
	i = pts[:, 1].argmin() if lado < 0 else pts[:, 1].argmax()
	y, x = pts[i]
	return [int(x), int(y)]


def cola(p, lado):
	"""Buje del rotor de cola: lo más alejado de la cabina en la mitad de arriba (lado = hacia dónde mira)."""
	if lado == 0:
		return None
	a = np.array(p.getchannel("A")) > 0
	h = a.shape[0]
	pts = np.argwhere(a[: int(h * 0.55)])
	# mira a la izquierda: la cola está a la derecha
	i = pts[:, 1].argmax() if lado < 0 else pts[:, 1].argmin()
	y, x = pts[i]
	# el extremo es la punta del brazo del buje (en cruz): el centro está unos px hacia dentro, a la misma altura
	return [int(x) + (-4 if lado < 0 else 4), int(y)]


def cano(p, lado, m):
	"""Dirección del cañón: de un punto 14 px atrás sobre el cañón hasta la boca (de frente, hacia abajo)."""
	if lado == 0:
		return [0.0, 1.0]
	a = np.array(p.getchannel("A")) > 0
	x = m[0] - 14 * lado
	ys = np.where(a[:, x])[0]
	ys = ys[ys > m[1] - 14]
	y = (ys[0] + ys[-1]) / 2.0 if len(ys) else m[1] - 5
	d = (m[0] - x, m[1] - y)
	n = math.hypot(*d)
	return [round(float(d[0] / n), 3), round(float(d[1] / n), 3)]


def main():
	im = Image.open(SRC).convert("RGBA")
	lados = [-1, -1, 0, 1, 1]
	frs = [nitido(p.resize((round(p.width * ESCALA), round(p.height * ESCALA)), Image.LANCZOS)) for p in poses(im)]
	ejes = [eje(f) for f in frs]
	# fotograma común con el eje del rotor en el mismo punto
	izq = max(e[0] for e in ejes) + MARGEN
	der = max(f.width - e[0] for f, e in zip(frs, ejes)) + MARGEN
	arriba = max(e[1] for e in ejes) + MARGEN
	abajo = max(f.height - e[1] for f, e in zip(frs, ejes)) + MARGEN
	fw, fh = int(math.ceil(izq + der)), int(math.ceil(arriba + abajo))
	pivote = [int(round(izq)), int(round(arriba))]
	sheet = Image.new("RGBA", (fw * len(frs), fh), (0, 0, 0, 0))
	meta = {"frame": [fw, fh], "rotor": pivote, "muzzles": [], "aims": [], "tails": []}
	for i, (f, e) in enumerate(zip(frs, ejes)):
		ox, oy = round(pivote[0] - e[0]), round(pivote[1] - e[1])
		sheet.alpha_composite(f, (i * fw + ox, oy))
		m = boca(f, lados[i])
		meta["aims"].append(cano(f, lados[i], m))
		meta["muzzles"].append([m[0] + ox, m[1] + oy])
		t = cola(f, lados[i])
		meta["tails"].append(None if t is None else [t[0] + ox, t[1] + oy])
	sheet.save(OUT / "helicoptero.png")
	(OUT / "helicoptero_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("helicoptero.png", sheet.size, meta)


if __name__ == "__main__":
	main()
