"""Nido de ametralladora enemigo: soldado de Argentina agachado tras un búnker de sacos terreros, con una
ametralladora montada que solo apunta a la izquierda (al frente o en diagonal hacia arriba).

Entrada (tools/sprites/pixellab/torreta/):
  nido.png, arma.png           búnker y ametralladora de PixelLab de la primera torreta (sin soldado)
  soldado/maqueta_<dir>.png    maqueta 64x64: la pose de apuntar del soldado (soldier_ar.png) tras el búnker
  soldado/gen1_<i>.png         edit_image de PixelLab sobre las maquetas: el soldado maneja la ametralladora
                               (0 = al frente, 1 = diagonal arriba; la 2, diagonal abajo, salió horizontal y no
                               se usa)
Salida (assets/sprites/):
  turret_soldado.png           un fotograma por dirección (frente, arriba), mirando a la izquierda
  turret_soldado_meta.json     tamaño de fotograma, pies (centro del borde de abajo del búnker) y boca del cañón
                               de cada dirección

Uso: python tools/sprites/turret.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/pixellab/torreta/soldado"
OUT = ROOT / "assets/sprites"
FRAMES = ["gen1_0.png", "gen1_1.png"]


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def boca(im, diagonal):
	"""Punta del cañón: el píxel opaco más a la izquierda (al frente) o más arriba a la izquierda (diagonal)."""
	a = im.getchannel("A").load()
	pts = [(x, y) for y in range(im.height) for x in range(im.width) if a[x, y]]
	return list(min(pts, key=(lambda p: p[0] + p[1]) if diagonal else (lambda p: (p[0], p[1]))))


def main():
	frs = [nitido(Image.open(SRC / f).convert("RGBA")) for f in FRAMES]
	w, h = frs[0].size
	sheet = Image.new("RGBA", (w * len(frs), h), (0, 0, 0, 0))
	for i, fr in enumerate(frs):
		sheet.alpha_composite(fr, (i * w, 0))
	# pies: centro del búnker, 2 px por encima de su fila más baja (los sacos de abajo se hunden un poco en el
	# suelo; si no, el nido parece flotar)
	a = frs[0].getchannel("A")
	bottom = a.getbbox()[3] - 1
	row = a.crop((0, bottom - 3, w, bottom + 1)).getbbox()
	feet = [round((row[0] + row[2]) / 2), bottom - 2]
	meta = {"frame": [w, h], "feet": feet, "dirs": ["frente", "arriba"],
		"muzzles": [boca(frs[0], False), boca(frs[1], True)]}
	sheet.save(OUT / "turret_soldado.png")
	(OUT / "turret_soldado_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("turret_soldado.png", sheet.size, meta)


if __name__ == "__main__":
	main()
