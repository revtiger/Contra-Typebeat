"""Terraza del canal de la 1.1 (pueblo de la pampa), según la referencia de Eduardo
(tools/sprites/chatgpt/pueblo/canal/referencia_canal.png): la calle sube por una rampa a una terraza de piedra con
baranda; por debajo corre el canal con agua (solo decorado) y arcos de desagüe en el muro.

Fuente (PixelLab, create_image_pro con estilo_canal.png, recorte de la referencia, como guía de estilo; cuatro
candidatos de cada uno en tools/sprites/pixellab/pueblo_extra/, se usa el 0):
  muro_N.png        muro de piedra con el borde de adoquines arriba
  muro_arco_N.png   el mismo muro con un arco de desagüe con reja y el chorro de agua
  baranda_N.png     baranda de pilares de arenisca y barrotes de hierro
Salida (assets/sprites/):
  terraza_muro.png     muro que se repite en horizontal sin corte (se funden los bordes)
  terraza_arco.png     arco de desagüe con sus bordes fundidos con el muro
  terraza_baranda.png  baranda de pilar a pilar (se repite)
  terraza_piedra.png   el muro sin el borde de adoquines (relleno de las rampas y de los muros más altos)
terrain.gd los dibuja en los tramos de la calle más altos que ella (la terraza) y en las rampas.

Uso: python tools/sprites/terraza.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/pixellab/pueblo_extra"
OUT = ROOT / "assets/sprites"
FUNDE = 14          # px que se funden en cada borde
BARANDA_PILARES = (14, 101)  # x del borde izquierdo de dos pilares seguidos: de uno al otro se repite


def recorta_alto(im):
	b = im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()
	return im.crop((0, b[1], im.width, b[3]))


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


def con_bordes(arco, muro):
	"""Los bordes del arco se funden con el muro, para ponerlo entre dos tramos de muro."""
	arco = arco.copy()
	h = min(arco.height, muro.height)
	for i in range(FUNDE):
		t = (i + 1) / (FUNDE + 1)
		izq = muro.crop((muro.width - FUNDE + i, 0, muro.width - FUNDE + i + 1, h))
		der = muro.crop((i, 0, i + 1, h))
		a = arco.crop((i, 0, i + 1, h))
		b = arco.crop((arco.width - FUNDE + i, 0, arco.width - FUNDE + i + 1, h))
		arco.paste(Image.blend(izq, a, t), (i, 0))
		arco.paste(Image.blend(b, der, t), (arco.width - FUNDE + i, 0))
	return arco


def main():
	muro = sin_corte(recorta_alto(Image.open(SRC / "muro_0.png").convert("RGBA")))
	muro.save(OUT / "terraza_muro.png")
	muro.crop((0, 18, muro.width, muro.height)).save(OUT / "terraza_piedra.png")
	arco = recorta_alto(Image.open(SRC / "muro_arco_0.png").convert("RGBA"))
	arco = con_bordes(arco, muro)
	arco.save(OUT / "terraza_arco.png")
	bar = Image.open(SRC / "baranda_0.png").convert("RGBA")
	bar = bar.crop((BARANDA_PILARES[0], 0, BARANDA_PILARES[1], bar.height))
	bar.save(OUT / "terraza_baranda.png")
	print("terraza_muro.png", muro.size, "terraza_arco.png", arco.size, "terraza_baranda.png", bar.size)


if __name__ == "__main__":
	main()
