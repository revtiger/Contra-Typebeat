"""Sprites de los jefes políticos (historia "ONU: Trying to save the world").

Entrada: tools/sprites/pixellab/politicos/<id>.png (generados con PixelLab, mirando a la izquierda).
Salida:  assets/sprites/pol_<id>.png, recortados al contenido (los pies quedan en el borde inferior).
La fusión final se monta pegando las cabezas de los jefes finales sobre el cuerpo de fusion.png.

Uso: python tools/sprites/politicians.py
"""
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "politicos")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")

IDS = ["massa", "kirchner", "milei", "amlo", "salinas", "sheinbaum", "biden", "obama", "trump",
	"merkel", "scholz", "merz", "lider"]
# cabezas que se pegan en la fusión: (id, centro x, centro y) sobre fusion.png recortado
FUSION_HEADS = [("milei", 40, 32), ("trump", 142, 30), ("sheinbaum", 22, 92), ("merz", 160, 92)]


def crop(im):
	return im.crop(im.getbbox())


def head(im):
	"""Parte superior del personaje: la cabeza y algo de hombros."""
	c = crop(im)
	return c.crop((0, 0, c.width, int(c.height * 0.3)))


def main():
	for pid in IDS:
		im = Image.open(os.path.join(SRC, pid + ".png")).convert("RGBA")
		crop(im).save(os.path.join(OUT, "pol_%s.png" % pid))
	body = crop(Image.open(os.path.join(SRC, "fusion.png")).convert("RGBA"))
	for pid, cx, cy in FUSION_HEADS:
		h = head(Image.open(os.path.join(SRC, pid + ".png")).convert("RGBA"))
		body.alpha_composite(h, (max(0, cx - h.width // 2), max(0, cy - h.height // 2)))
	body.save(os.path.join(OUT, "pol_fusion.png"))
	print("ok", len(IDS) + 1, "sprites")


if __name__ == "__main__":
	main()
