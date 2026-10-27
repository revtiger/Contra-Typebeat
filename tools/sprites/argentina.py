"""Fondos y suelos de las fases 1.2 (Quebrada de Humahuaca) y 1.3 (Buenos Aires, Casa Rosada), hechos con PixelLab.

Entrada: tools/sprites/pixellab/argentina/
  fondo_quebrada.png  cerros de colores, cardones y cielo (400x272)
  fondo_baires.png    la Casa Rosada entre edificios antiguos, al atardecer, en vista lateral (400x272)
  suelo_quebrada.png  tira de tierra ocre y roca roja en capas (256x64)
  suelo_baires.png    tira de acera de piedra con panfletos y ladrillo (256x64)

Salida (assets/sprites/):
  bg_quebrada.png  la imagen y su espejo seguidos (800x270): se repite sin cortes y avanza despacio
  bg_baires.png    edificios de los lados de la imagen seguidos y, al final, la imagen entera: el fondo
                   avanza despacio y la Casa Rosada queda en el centro al llegar al jefe (como el pueblo de la 1.1)
  ground_quebrada.png / ground_baires.png  la tira y su espejo (512x64), se repiten sin cortes

Uso: python tools/sprites/argentina.py
"""
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "argentina")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")
H = 270
# Buenos Aires: trozos de los lados (edificio y árbol) con los que se arma el camino hasta la Casa Rosada
BAIRES_LEFT = (0, 110)
BAIRES_RIGHT = (290, 400)
BAIRES_FILLER = ["right", "left", "right", "left"]


def load(name):
	im = Image.open(os.path.join(SRC, name)).convert("RGBA")
	return im.crop((0, im.height - H, im.width, im.height)) if im.height > 64 else im


def mirrored(im):
	out = Image.new("RGBA", (im.width * 2, im.height), (0, 0, 0, 0))
	out.alpha_composite(im)
	out.alpha_composite(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
	return out


if __name__ == "__main__":
	mirrored(load("fondo_quebrada.png")).save(os.path.join(OUT, "bg_quebrada.png"))

	full = load("fondo_baires.png")
	parts = {"left": full.crop((BAIRES_LEFT[0], 0, BAIRES_LEFT[1], H)), "right": full.crop((BAIRES_RIGHT[0], 0, BAIRES_RIGHT[1], H))}
	pieces = [parts[p] for p in BAIRES_FILLER] + [full]
	pano = Image.new("RGBA", (sum(p.width for p in pieces), H), (0, 0, 0, 0))
	x = 0
	for p in pieces:
		pano.alpha_composite(p, (x, 0))
		x += p.width
	pano.save(os.path.join(OUT, "bg_baires.png"))

	for name in ("quebrada", "baires"):
		mirrored(load("suelo_%s.png" % name)).save(os.path.join(OUT, "ground_%s.png" % name))
	print("ok argentina: bg_quebrada", Image.open(os.path.join(OUT, "bg_quebrada.png")).size,
		"bg_baires", pano.size)
