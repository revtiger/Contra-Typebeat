"""Canal de la 1.1 con el kit de piezas de ChatGPT (pedido de Eduardo, 25-10-2026): muro de piedra, arco de desagüe
con cascada, baranda de hierro entre pilares, paseo de adoquines y rampa recta que baja de la calle al paseo.

Entrada: tools/sprites/chatgpt/pueblo/canal/kit_canal.png (fondo negro: se quita desde los bordes).
Todas las piezas van a la escala S (las piedras del muro, del paseo y de la rampa quedan del mismo tamaño) menos la
baranda (en el kit es más alta que un soldado) y el arco (se encaja en el alto del muro).
Salida (assets/sprites/):
  canal_muro.png     muro con remate arriba, recortado a MURO_H; se repite en horizontal sin corte
  canal_piedra.png   el muro sin el remate: relleno de abajo del paseo y de las rampas
  canal_arco.png     arco de desagüe con reja y cascada, con los bordes fundidos con el muro
  canal_baranda.png  baranda de pilar a pilar (se repite)
  canal_piso.png     franja del piso de adoquines del paseo que se ve por encima de los pies (PISO px)
  canal_borde.png    borde de piedra del paseo, donde se pisa
  canal_rampa.png    rampa que baja de izquierda a derecha, con el pilar de la esquina y su muro
  canal_meta.json    medidas que usan canal.gd, terrain.gd y la plantilla "pueblo" de levels.gd

Uso: python tools/sprites/canal_kit.py
"""
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/pueblo/canal/kit_canal.png"
OUT = ROOT / "assets/sprites"
S = 0.45
FUNDE = 14  # px (ya a escala) que se funden en cada borde para que la tira se repita sin corte
MURO_H = 76  # alto del muro en el juego (se corta lo de abajo para que quepan el agua y el piso)
BARANDA_H = 40

# cajas en el kit (px del original)
MURO = (27, 18, 942, 222)              # remate arriba (18) … agua (205)
MURO_REMATE = 52                       # fila donde termina el remate del muro
ARCO = (300, 240, 680, 476)            # el arco con un poco de muro a cada lado, del remate al agua
BARANDA = (965, 62, 1320, 228)         # del borde izquierdo de un pilar al del siguiente
PISO_SRC = (100, 541, 1430, 569)       # las filas de delante del piso de adoquines
BORDE_SRC = (100, 569, 1430, 607)      # borde de piedra del paseo (arriba se pisa)
RAMPA = (40, 630, 1236, 982)           # pilar de la esquina, rampa y el comienzo del paseo
RAMPA_INICIO = (275, 653)              # donde empieza a bajar la rampa (arriba del remate)
RAMPA_FIN = (1200, 889)                # donde llega al paseo


def sin_fondo(im):
	"""El negro del fondo (conectado con los bordes de la imagen) pasa a transparente."""
	a = np.array(im.convert("RGB")).astype(int)
	h, w, _ = a.shape
	oscuro = a.max(axis=2) <= 14
	fondo = np.zeros((h, w), bool)
	cola = deque()
	for x in range(w):
		for y in (0, h - 1):
			if oscuro[y, x]:
				fondo[y, x] = True
				cola.append((y, x))
	for y in range(h):
		for x in (0, w - 1):
			if oscuro[y, x] and not fondo[y, x]:
				fondo[y, x] = True
				cola.append((y, x))
	while cola:
		y, x = cola.popleft()
		for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
			if 0 <= yy < h and 0 <= xx < w and oscuro[yy, xx] and not fondo[yy, xx]:
				fondo[yy, xx] = True
				cola.append((yy, xx))
	rgba = np.dstack([a, np.where(fondo, 0, 255)]).astype(np.uint8)
	return Image.fromarray(rgba, "RGBA")


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def escala(im, sx, sy=None):
	sy = sx if sy is None else sy
	return nitido(im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.LANCZOS))


def sin_corte(im):
	"""El final se funde con el principio: la tira se repite sin que se note la unión."""
	w = im.width - FUNDE
	out = im.crop((0, 0, w, im.height))
	for i in range(FUNDE):
		t = (i + 1) / (FUNDE + 1)
		head = im.crop((i, 0, i + 1, im.height))
		tail = im.crop((w + i, 0, w + i + 1, im.height))
		out.paste(Image.blend(tail, head, t), (i, 0))
	return out


def con_bordes(pieza, muro):
	"""Los bordes de la pieza se funden con el muro, para ponerla entre dos tramos de muro."""
	pieza = pieza.copy()
	h = min(pieza.height, muro.height)
	for i in range(FUNDE):
		t = (i + 1) / (FUNDE + 1)
		izq = muro.crop((muro.width - FUNDE + i, 0, muro.width - FUNDE + i + 1, h))
		der = muro.crop((i, 0, i + 1, h))
		a = pieza.crop((i, 0, i + 1, h))
		b = pieza.crop((pieza.width - FUNDE + i, 0, pieza.width - FUNDE + i + 1, h))
		pieza.paste(Image.blend(izq, a, t), (i, 0))
		pieza.paste(Image.blend(b, der, t), (pieza.width - FUNDE + i, 0))
	return pieza


def main():
	kit = sin_fondo(Image.open(SRC))
	muro_full = escala(kit.crop(MURO), S)
	muro = sin_corte(muro_full.crop((0, 0, muro_full.width, MURO_H)))
	muro.save(OUT / "canal_muro.png")
	remate = round((MURO_REMATE - MURO[1]) * S)
	piedra = sin_corte(muro_full.crop((0, remate, muro_full.width, muro_full.height - round(17 * S))))
	piedra.save(OUT / "canal_piedra.png")
	# arco: del remate al agua en MURO_H + 6 px (la cascada cae al agua del canal)
	ah = ARCO[3] - ARCO[1]
	arco = escala(kit.crop((ARCO[0], ARCO[1], ARCO[2], ARCO[3] + 30)), 0.4, (MURO_H + 6) / ah)
	arco = con_bordes(arco, muro)
	arco.save(OUT / "canal_arco.png")
	bar = kit.crop(BARANDA)
	bar = escala(bar, BARANDA_H / bar.height)
	bar.save(OUT / "canal_baranda.png")
	piso = sin_corte(escala(kit.crop(PISO_SRC), S))
	piso.save(OUT / "canal_piso.png")
	borde = sin_corte(escala(kit.crop(BORDE_SRC), S))
	borde.save(OUT / "canal_borde.png")
	rampa = escala(kit.crop(RAMPA), S)
	rampa.save(OUT / "canal_rampa.png")
	ini = [round((RAMPA_INICIO[0] - RAMPA[0]) * S), round((RAMPA_INICIO[1] - RAMPA[1]) * S)]
	fin = [round((RAMPA_FIN[0] - RAMPA[0]) * S), round((RAMPA_FIN[1] - RAMPA[1]) * S)]
	meta = {
		"escala": S,
		"muro_h": MURO_H,
		"piso": piso.height,                # franja del piso que se ve por encima de los pies
		"baja": fin[1] - ini[1],             # cuánto baja la rampa: del nivel de la calle al del paseo
		"rampa_largo": fin[0] - ini[0],
		"rampa_inicio": ini,                 # en px de canal_rampa.png
		"rampa_fin": fin,
		"arco_agua": MURO_H + 6,
	}
	(OUT / "canal_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print({n: Image.open(OUT / f"canal_{n}.png").size for n in ["muro", "piedra", "arco", "baranda", "piso", "borde", "rampa"]})
	print(meta)


if __name__ == "__main__":
	main()
