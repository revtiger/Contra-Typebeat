"""Tanques enemigos hechos con PixelLab: comunista (estilo T-34), israelí (estilo Merkava) y estadounidense
(estilo Abrams). Cada uno es una imagen de 64x48 mirando a la izquierda animada con animate_image (orugas).

Entrada: tools/sprites/pixellab/tanques/<tipo>_N.png (fotogramas en orden; el 0 es la imagen original)
Salida:  assets/sprites/tank_<tipo>.png (fotogramas en una fila)
         assets/sprites/tanks_meta.json: por tipo, tamaño de fotograma, número de fotogramas, base (fila de las
         orugas que apoya en el suelo), centro del casco y boca del cañón (relativos a la base), y ancho del casco

Uso: python tools/sprites/tanks.py
"""
import glob
import json
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "tanques")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")
TYPES = ["comunista", "israeli", "usa"]


def opaque(im):
	return im.getchannel("A").point(lambda v: 255 if v > 100 else 0)


if __name__ == "__main__":
	meta = {}
	for t in TYPES:
		paths = sorted(glob.glob(os.path.join(SRC, "%s_[0-9].png" % t)))
		frames = [Image.open(p).convert("RGBA") for p in paths]
		w, h = frames[0].size
		strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
		for i, f in enumerate(frames):
			strip.alpha_composite(f, (i * w, 0))
		strip.save(os.path.join(OUT, "tank_%s.png" % t))
		m = opaque(frames[0])
		b = m.getbbox()
		base = b[3]
		# boca del cañón: el píxel opaco más a la izquierda en la mitad de arriba (el cañón apunta a la izquierda)
		best = None
		for y in range(b[1], b[1] + (b[3] - b[1]) // 2):
			bb = m.crop((0, y, w, y + 1)).getbbox()
			if bb and (best is None or bb[0] < best[0]):
				best = (bb[0], y)
		# casco: ancho de la mitad de abajo (orugas), sin el cañón
		hb = m.crop((0, (b[1] + b[3]) // 2, w, b[3])).getbbox()
		cx = (hb[0] + hb[2]) // 2
		meta[t] = {
			"frame": [w, h], "frames": len(frames), "base": base, "center_x": cx,
			"hull": [hb[2] - hb[0], b[3] - b[1]],
			"muzzle": [best[0] - cx, best[1] - base],
		}
		print("ok tank", t, meta[t])
	with open(os.path.join(OUT, "tanks_meta.json"), "w", encoding="utf-8", newline="\n") as f:
		json.dump(meta, f, indent=1)
