"""Hoja de sprites animada de Sergio Massa (minijefe 1.1).

Entrada: tools/sprites/pixellab/massa/<anim>_<i>.png, animaciones hechas con PixelLab (animate_image)
a partir de pixellab/politicos/massa.png:
  idle (5), walk (9), talk (9: discurso con micrófono), throw (9: lanza un fajo), thumbs (9: pulgar arriba)
  weapon.png (La Maquinita, cañón de imprimir billetes) y bundle.png (fajo de billetes)
Los fotogramas de 64 px de ancho se colocan en un lienzo de 96 con los pies en el mismo sitio
que los de 96 (pies en PIVOT). Se quitan las sombras grises que PixelLab pinta bajo los pies.

Salida: assets/sprites/boss_massa.png (una fila por animación, fotogramas de 96x128),
        assets/sprites/boss_massa_weapon.png, assets/sprites/boss_massa_bundle.png,
        assets/sprites/boss_massa_meta.json (filas, número de fotogramas y puntos útiles).

Uso: python tools/sprites/massa.py
"""
import json
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "massa")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")

FW, FH = 96, 128
# en los fotogramas de 96 px Massa está a la derecha: sus pies quedan en x = 61
PIVOT = (61, 127)
NARROW_SHIFT = 29  # los fotogramas de 64 px tienen los pies en x = 32 -> 32 + 29 = 61
# (animación, archivo de origen, fotogramas usados). walk2 es la segunda tirada de la caminata
# (la primera apenas movía las piernas); su ciclo útil son los fotogramas 2 a 8.
ANIMS = [
	("idle", "idle", range(5)),
	("walk", "walk2", range(2, 9)),
	("talk", "talk", range(9)),
	("throw", "throw", range(9)),
	("thumbs", "thumbs", range(9)),
]


def no_shadow(im):
	"""Quita la sombra gris y semitransparente que PixelLab dibuja en el suelo."""
	px = im.load()
	for y in range(im.height - 12, im.height):
		for x in range(im.width):
			r, g, b, a = px[x, y]
			grey = max(r, g, b) - min(r, g, b) < 28
			if a > 0 and grey and max(r, g, b) > 70:
				px[x, y] = (0, 0, 0, 0)
			elif 0 < a < 200:
				px[x, y] = (0, 0, 0, 0)
	return im


def frame(name, i):
	im = Image.open(os.path.join(SRC, "%s_%d.png" % (name, i))).convert("RGBA")
	canvas = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
	canvas.alpha_composite(im, (NARROW_SHIFT if im.width == 64 else 0, FH - im.height))
	return no_shadow(canvas)


def main():
	cols = max(len(fr) for _, _, fr in ANIMS)
	sheet = Image.new("RGBA", (FW * cols, FH * len(ANIMS)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "pivot": list(PIVOT), "anims": {}}
	for row, (name, src, frames) in enumerate(ANIMS):
		for col, i in enumerate(frames):
			sheet.alpha_composite(frame(src, i), (col * FW, row * FH))
		meta["anims"][name] = {"row": row, "frames": len(frames)}
	# puntos útiles en píxeles del fotograma (mirando a la izquierda)
	meta["mic"] = [28, 44]         # micrófono en el discurso: salen las promesas
	meta["hand_throw"] = [8, 38]   # mano al soltar el fajo (fotograma 6 de throw)
	meta["shoulder"] = [60, 49]    # hombro donde se apoya La Maquinita
	sheet.save(os.path.join(OUT, "boss_massa.png"))
	w = Image.open(os.path.join(SRC, "weapon.png")).convert("RGBA")
	w.crop(w.getbbox()).save(os.path.join(OUT, "boss_massa_weapon.png"))
	b = Image.open(os.path.join(SRC, "bundle.png")).convert("RGBA")
	b.crop(b.getbbox()).save(os.path.join(OUT, "boss_massa_bundle.png"))
	with open(os.path.join(OUT, "boss_massa_meta.json"), "w", encoding="utf-8") as f:
		json.dump(meta, f, indent=1)
	print("ok boss_massa", sheet.size)


if __name__ == "__main__":
	main()
