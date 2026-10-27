"""Minas y barriles explosivos (pedido de Eduardo, 26-10-2026; dibujados por ChatGPT).

Entrada: tools/sprites/chatgpt/objetos/minas_barriles.png (fondo magenta liso): de izquierda a derecha la mina con
         la luz apagada, la mina con la luz encendida, el barril y el barril dañado (abollado, agujeros, humo).
Salida (assets/sprites/):
  mina.png          dos fotogramas: luz apagada y encendida (mine.gd los alterna)
  barril.png        dos fotogramas: entero y dañado (barrel.gd pasa al segundo con el primer impacto)
  objetos_meta.json tamaño de fotograma de cada uno (los pies en el centro del borde de abajo)

Uso: python tools/sprites/objetos.py
"""
import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/objetos/minas_barriles.png"
OUT = ROOT / "assets/sprites"
MINA_ANCHO = 26    # px en el juego (el soldado mide 48 de alto)
BARRIL_ALTO = 24


def sin_magenta(im):
	"""El magenta del fondo (y su borde mezclado) conectado con los bordes de la imagen pasa a transparente."""
	a = np.array(im.convert("RGB")).astype(int)
	h, w, _ = a.shape
	mag = (a[..., 0] - a[..., 1] > 90) & (a[..., 2] - a[..., 1] > 90)
	fondo = np.zeros((h, w), bool)
	cola = deque((y, x) for y in range(h) for x in (0, w - 1) if mag[y, x])
	cola.extend((y, x) for x in range(w) for y in (0, h - 1) if mag[y, x])
	for y, x in cola:
		fondo[y, x] = True
	while cola:
		y, x = cola.popleft()
		for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
			if 0 <= yy < h and 0 <= xx < w and mag[yy, xx] and not fondo[yy, xx]:
				fondo[yy, xx] = True
				cola.append((yy, xx))
	# el magenta que queda encerrado (huecos entre piezas) y los bordes que tiran a violeta también son fondo:
	# los objetos no tienen ese color
	fondo |= (a[..., 0] - a[..., 1] > 70) & (a[..., 2] - a[..., 1] > 70)
	return Image.fromarray(np.dstack([a, np.where(fondo, 0, 255)]).astype(np.uint8), "RGBA")


def piezas(im):
	"""Las piezas separadas por columnas vacías, de izquierda a derecha."""
	a = np.array(im.getchannel("A")) > 0
	cols = a.any(axis=0)
	out = []
	x = 0
	while x < len(cols):
		if cols[x]:
			x0 = x
			while x < len(cols) and cols[x]:
				x += 1
			if x - x0 > 20:
				p = im.crop((x0, 0, x, im.height))
				out.append(p.crop(p.getchannel("A").getbbox()))
		x += 1
	return out


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def fila(frames):
	"""Fotogramas del mismo tamaño (el más grande), apoyados en el borde de abajo y centrados."""
	fw = max(f.width for f in frames)
	fh = max(f.height for f in frames)
	out = Image.new("RGBA", (fw * len(frames), fh), (0, 0, 0, 0))
	for i, f in enumerate(frames):
		out.alpha_composite(f, (i * fw + (fw - f.width) // 2, fh - f.height))
	return out, [fw, fh]


def main():
	mina0, mina1, barril0, barril1 = piezas(sin_magenta(Image.open(SRC)))
	s = MINA_ANCHO / mina0.width
	minas = [nitido(m.resize((round(m.width * s), round(m.height * s)), Image.LANCZOS)) for m in (mina0, mina1)]
	s = BARRIL_ALTO / barril0.height
	# el barril dañado a la misma escala, sin el humo que sube por encima del barril (el humo lo hace el juego)
	b1 = barril1.crop((0, barril1.height - barril0.height, barril1.width, barril1.height))
	barriles = [nitido(b.resize((round(b.width * s), round(b.height * s)), Image.LANCZOS)) for b in (barril0, b1)]
	meta = {}
	for name, frames in (("mina", minas), ("barril", barriles)):
		im, size = fila(frames)
		im.save(OUT / f"{name}.png")
		meta[name] = {"frame": size}
	(OUT / "objetos_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print(meta)


if __name__ == "__main__":
	main()
