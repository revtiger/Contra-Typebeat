"""Agua del canal de la 1.1 (pedido de Eduardo, 26-10-2026): piezas de ChatGPT animadas con PixelLab.

Entrada: tools/sprites/chatgpt/pueblo/canal/agua_kit.png (ChatGPT; el fondo es un damero gris dibujado, no
         transparencia: se quita desde los bordes). Tres piezas: la tira de agua, el chorro y la espuma.
Animación (PixelLab, animate_image sobre las piezas al doble del tamaño del juego):
  tools/sprites/pixellab/canal_agua/chorro_N.png  el chorro cayendo (0 = la pieza quieta, 1.. = generados)
  tools/sprites/pixellab/canal_agua/espuma_N.png  la espuma burbujeando
Salida (assets/sprites/):
  canal_agua.png         tira de agua que se repite en horizontal (canal.gd la hace correr en dos capas)
  canal_chorro.png       fotogramas del chorro en fila (va encima del chorro quieto del arco)
  canal_espuma.png       fotogramas de la espuma en fila (va sobre el agua, donde cae el chorro)
  canal_agua_meta.json   tamaños y número de fotogramas

Uso:
  python tools/sprites/agua.py base    # recorta las piezas y deja las entradas para PixelLab
  python tools/sprites/agua.py juego   # arma los sprites del juego con lo que devolvió PixelLab
"""
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/pueblo/canal/agua_kit.png"
PL = ROOT / "tools/sprites/pixellab/canal_agua"
OUT = ROOT / "assets/sprites"
AGUA_H = 18          # alto de la franja de agua del canal en el juego (entre el muro y el piso del paseo)
AGUA_ESCALA_X = 0.22  # la tira se aplasta en vertical (el agua vista casi de lado: las ondas quedan como rayas)
CHORRO = (40, 28)    # tamaño del chorro en el juego (tapa el chorro quieto del arco)
ESPUMA = (72, 22)    # tamaño de la espuma en el juego
FUNDE = 16


def sin_damero(im):
	"""El damero gris claro conectado con los bordes pasa a transparente."""
	a = np.array(im.convert("RGB")).astype(int)
	h, w, _ = a.shape
	neutro = (a.max(axis=2) - a.min(axis=2) < 12) & (a.min(axis=2) > 180)
	fondo = np.zeros((h, w), bool)
	cola = deque((y, x) for y in range(h) for x in (0, w - 1) if neutro[y, x])
	cola.extend((y, x) for x in range(w) for y in (0, h - 1) if neutro[y, x])
	for y, x in cola:
		fondo[y, x] = True
	while cola:
		y, x = cola.popleft()
		for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
			if 0 <= yy < h and 0 <= xx < w and neutro[yy, xx] and not fondo[yy, xx]:
				fondo[yy, xx] = True
				cola.append((yy, xx))
	return Image.fromarray(np.dstack([a, np.where(fondo, 0, 255)]).astype(np.uint8), "RGBA")


def piezas(im):
	"""(tira, chorro, espuma): la tira es la mitad de arriba; abajo, el chorro a la izquierda y la espuma."""
	a = np.array(im.getchannel("A")) > 0
	# corte entre la tira y lo de abajo: la primera fila (casi) vacía después de la primera fila llena de la tira
	llena = next(y for y in range(a.shape[0]) if a[y].sum() > a.shape[1] // 2)
	corte = next(y for y in range(llena, a.shape[0]) if a[y].sum() < 4)
	tira = im.crop((0, 0, im.width, corte))
	abajo = im.crop((0, corte, im.width, im.height))
	b = np.array(abajo.getchannel("A")) > 0
	cols = b.any(axis=0)
	# hueco entre el chorro y la espuma: la columna vacía más larga en la mitad izquierda
	xs = np.where(cols)[0]
	huecos = [x for x in range(xs[0], im.width // 2) if not cols[x]]
	medio = huecos[len(huecos) // 2] if huecos else im.width // 4
	chorro = abajo.crop((0, 0, medio, abajo.height))
	espuma = abajo.crop((medio, 0, abajo.width, abajo.height))
	recorta = lambda p: p.crop(p.getchannel("A").point(lambda v: 255 if v > 0 else 0).getbbox())
	return recorta(tira), recorta(chorro), recorta(espuma)


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def sin_corte(im):
	w = im.width - FUNDE
	out = im.crop((0, 0, w, im.height))
	for i in range(FUNDE):
		t = (i + 1) / (FUNDE + 1)
		out.paste(Image.blend(im.crop((w + i, 0, w + i + 1, im.height)), im.crop((i, 0, i + 1, im.height)), t), (i, 0))
	return out


def base():
	tira, chorro, espuma = piezas(sin_damero(Image.open(SRC)))
	# la tira: se le quitan los bordes irregulares de arriba y abajo y se aplasta a AGUA_H
	t = tira.crop((8, 10, tira.width - 8, tira.height - 6))
	agua = t.resize((round(t.width * AGUA_ESCALA_X), AGUA_H), Image.LANCZOS)
	agua.putalpha(255)
	sin_corte(agua).save(OUT / "canal_agua.png")
	PL.mkdir(parents=True, exist_ok=True)
	for name, p, size in (("chorro", chorro, CHORRO), ("espuma", espuma, ESPUMA)):
		doble = nitido(p.resize((size[0] * 2, size[1] * 2), Image.LANCZOS))
		doble.save(PL / f"{name}_0.png")
		print(name, p.size, "->", doble.size)
	print("canal_agua.png", Image.open(OUT / "canal_agua.png").size)


def tira(name, size):
	"""Fotogramas de PixelLab (name_1.., al doble) reducidos al tamaño del juego, en fila."""
	frs = sorted(PL.glob(f"{name}_*.png"), key=lambda p: int(p.stem.split("_")[1]))
	frs = [f for f in frs if int(f.stem.split("_")[1]) > 0]
	out = Image.new("RGBA", (size[0] * len(frs), size[1]), (0, 0, 0, 0))
	for i, f in enumerate(frs):
		im = Image.open(f).convert("RGBA").resize(size, Image.BOX)
		out.alpha_composite(nitido(im), (i * size[0], 0))
	return out, len(frs)


def juego():
	meta = {"agua_h": AGUA_H}
	for name, size in (("chorro", CHORRO), ("espuma", ESPUMA)):
		im, n = tira(name, size)
		im.save(OUT / f"canal_{name}.png")
		meta[name] = {"frame": list(size), "frames": n}
	(OUT / "canal_agua_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print(meta)


if __name__ == "__main__":
	{"base": base, "juego": juego}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
