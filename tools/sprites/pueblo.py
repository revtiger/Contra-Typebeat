"""Fondo y suelo del pueblo de la pampa (fase 1.1, Argentina).

Fuente: ilustraciones de Eduardo (ChatGPT) en tools/sprites/chatgpt/pueblo/:
  cielo_pampa.png  cielo del atardecer con un solo sol y la pampa (fondo lejano)
  tramoNN.png      tramos del pueblo sin cielo (fondo transparente), proporción 2,5:1, uno tras otro
  pueblo_completo.png  pueblo seguido de punta a punta (2000x667, transparente): se le quitan los
                   vecinos, el almacén repetido y el vagón del final, y sale el tramo 04 (ver COMPLETO)
  1_almacen, 2_capilla_taller, 3_plaza_massa (1983x793): escenas de referencia; de la 1 sale la calle.
y tramos hechos con PixelLab (create_image_pro, con los tramos 1 y 2 de referencia de estilo) en
tools/sprites/pixellab/pueblo/ (ver PIXELLAB).
Si existe <nombre>_limpia.png (la misma escena sin personajes) se usa esa.

Salida:
  assets/sprites/bg_pueblo.png      cielo y pampa, 270 px de alto (se mueve muy despacio)
  assets/sprites/pueblo_tramo_NN.png  cada tramo escalado a 270 px de alto (casas a la altura del juego)
  assets/sprites/ground_pueblo.png  tira de adoquines y tierra que se repite en el suelo

Uso: python tools/sprites/pueblo.py
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/pueblo"
OUT = ROOT / "assets/sprites"
SCENES = ["1_almacen", "2_capilla_taller", "3_plaza_massa"]
H = 270

# Cielo: escala y desplazamiento para que el campo amarillo (y=680 en el original)
# quede en y=195 de la pantalla, por encima del suelo (y=230).
SKY_SCALE = 0.4
SKY_FIELD = 680
SKY_FIELD_Y = 195

# Suelo: tramo de calle sin personajes de la escena 1 (coordenadas de la imagen original)
GROUND_BOX = (480, 640, 1400, 793)
GROUND_BLEND = 24

# Tramos cuya calle sale un poco más alta o más baja que la del tramo 1: px que se bajan (+) o suben (-)
TRAMO_DY = {"02": 3}

# Tramo 04 (el último, con la plaza de la capilla para la pelea con Massa) a partir de pueblo_completo.png (coordenadas del original)
COMPLETO = {
	"tramo": "04",
	# [x0, y0, x1, y1, dx]: tapa la zona copiando lo que hay dx px a la izquierda (-) o derecha (+)
	"parches": [
		[576, 420, 614, 512, -36],    # almacenero
		[890, 425, 924, 508, -100],   # mecánico del garaje
		[1096, 444, 1136, 462, -45],  # señor del banco: pared y ventana
		[1094, 455, 1138, 506, -44],  # señor del banco: maceta en su lugar
		[1580, 424, 1616, 512, -36],  # almacenero 2
	],
	"quitar": [408, 748],  # el almacén, que ya sale en el tramo 1
	"fin": 1935,           # se corta antes del vagón para que el pueblo termine en la pared de la estación
	"escala": 0.53,        # las casas a la misma escala que el tramo 1
	"arriba": 64,          # px que se recortan arriba para que la vereda quede como en el tramo 1
}

# Tramos que son otro tramo dado vuelta (espejo), para variar sin repetir igual: {nuevo: original}
ESPEJO = {}

# Tramos de PixelLab (675x270, transparentes): {tramo: (archivo, x0, x1, arriba)}. Se recorta el margen vacío
# de los lados (x0..x1), se estira a 675 de ancho y se suben "arriba" px para que el bordillo de la vereda
# quede a la altura del tramo 1 (y=211).
PIXELLAB = {
	"03": ("taller_bb.png", 28, 647, 32),  # taller mecánico con el logo B.B. y tractor rojo (25 generaciones)
}


def load(name: str) -> Image.Image:
	clean = SRC / f"{name}_limpia.png"
	return Image.open(clean if clean.exists() else SRC / f"{name}.png").convert("RGB")


def build_sky() -> None:
	src = load("cielo_pampa")
	s = SKY_SCALE
	big = src.resize((round(src.width * s), round(src.height * s)), Image.LANCZOS)
	top = round(SKY_FIELD * s) - SKY_FIELD_Y
	sky = Image.new("RGB", (big.width, H), big.getpixel((big.width // 2, big.height - 1)))
	sky.paste(big.crop((0, top, big.width, min(big.height, top + H))), (0, 0))
	sky.save(OUT / "bg_pueblo.png")
	print("bg_pueblo.png", sky.size)


def build_tramos() -> None:
	for f in sorted(SRC.glob("tramo[0-9][0-9].png")):
		src = Image.open(f).convert("RGBA")
		im = src.resize((round(src.width * H / src.height), H), Image.LANCZOS)
		# bordes nítidos de pixel art: cada píxel es opaco o transparente
		a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
		im.putalpha(a)
		num = f.stem[5:]
		out = Image.new("RGBA", im.size, (0, 0, 0, 0))
		out.paste(im, (0, TRAMO_DY.get(num, 0)))
		name = "pueblo_tramo_" + num + ".png"
		out.save(OUT / name)
		print(name, im.size)


def build_completo() -> None:
	c = COMPLETO
	src = Image.open(SRC / "pueblo_completo.png").convert("RGBA")
	im = src.crop((0, 0, c["fin"], src.height))
	for x0, y0, x1, y1, dx in c["parches"]:
		im.paste(src.crop((x0 + dx, y0, x1 + dx, y1)), (x0, y0))
	q0, q1 = c["quitar"]
	cut = Image.new("RGBA", (im.width - (q1 - q0), im.height), (0, 0, 0, 0))
	cut.paste(im.crop((0, 0, q0, im.height)), (0, 0))
	cut.paste(im.crop((q1, 0, im.width, im.height)), (q0, 0))
	s = c["escala"]
	big = cut.resize((round(cut.width * s), round(cut.height * s)), Image.LANCZOS)
	out = Image.new("RGBA", (big.width, H), (0, 0, 0, 0))
	out.paste(big.crop((0, c["arriba"], big.width, c["arriba"] + H)), (0, 0))
	out.putalpha(out.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	name = "pueblo_tramo_" + c["tramo"] + ".png"
	out.save(OUT / name)
	print(name, out.size)


def build_espejos() -> None:
	for new, orig in ESPEJO.items():
		im = Image.open(OUT / f"pueblo_tramo_{orig}.png").transpose(Image.FLIP_LEFT_RIGHT)
		im.save(OUT / f"pueblo_tramo_{new}.png")
		print(f"pueblo_tramo_{new}.png (espejo del {orig})", im.size)


def build_pixellab() -> None:
	for num, (fname, x0, x1, up) in PIXELLAB.items():
		src = Image.open(ROOT / "tools/sprites/pixellab/pueblo" / fname).convert("RGBA").crop((x0, 0, x1, H))
		s = 675 / src.width
		big = src.resize((675, round(H * s)), Image.LANCZOS)
		out = Image.new("RGBA", (675, H), (0, 0, 0, 0))
		out.paste(big.crop((0, up, 675, up + H)), (0, 0))
		out.putalpha(out.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
		out.save(OUT / f"pueblo_tramo_{num}.png")
		print(f"pueblo_tramo_{num}.png (PixelLab {fname})", out.size)


def build_ground() -> None:
	src = load(SCENES[0]).crop(GROUND_BOX)
	s = H / 793
	g = src.resize((round(src.width * s), round(src.height * s)), Image.LANCZOS)
	# hacer que se repita sin corte: fundir el final con el principio
	n = GROUND_BLEND
	w = g.width - n
	tile = g.crop((0, 0, w, g.height))
	for i in range(n):
		t = (i + 1) / (n + 1)
		head = g.crop((i, 0, i + 1, g.height))
		tail = g.crop((w + i, 0, w + i + 1, g.height))
		tile.paste(Image.blend(tail, head, t), (i, 0))
	tile.save(OUT / "ground_pueblo.png")
	print("ground_pueblo.png", tile.size)


if __name__ == "__main__":
	build_sky()
	build_tramos()
	build_completo()
	build_espejos()
	build_pixellab()
	build_ground()
