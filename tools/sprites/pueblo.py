"""Fondo y suelo del pueblo de la pampa (fase 1.1, Argentina).

Fuente: las 3 ilustraciones de Eduardo (ChatGPT) en tools/sprites/chatgpt/pueblo/,
1983x793 cada una: 1 almacén, 2 capilla y taller B.B., 3 plaza (jefe Massa).
Si existe <nombre>_limpia.png (la misma escena sin héroe, soldados ni jefe) se usa esa.

Salida:
  assets/sprites/bg_pueblo.png      las 3 escenas en fila, escaladas a 270 px de alto
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
SEAM = 16  # px de fundido entre escenas (luego un poste tapa la unión)

# Suelo: tramo de calle sin personajes de la escena 1 (coordenadas de la imagen original)
GROUND_BOX = (480, 640, 1400, 793)
GROUND_BLEND = 24


def load(name: str) -> Image.Image:
	clean = SRC / f"{name}_limpia.png"
	return Image.open(clean if clean.exists() else SRC / f"{name}.png").convert("RGB")


def scaled(im: Image.Image) -> Image.Image:
	w = round(im.width * H / im.height)
	return im.resize((w, H), Image.LANCZOS)


def crossfade(a: Image.Image, b: Image.Image, n: int) -> Image.Image:
	"""Pega b a la derecha de a, fundiendo n columnas."""
	out = Image.new("RGB", (a.width + b.width - n, H))
	out.paste(a, (0, 0))
	out.paste(b, (a.width - n, 0))
	for i in range(n):
		t = (i + 1) / (n + 1)
		ca = a.crop((a.width - n + i, 0, a.width - n + i + 1, H))
		cb = b.crop((i, 0, i + 1, H))
		out.paste(Image.blend(ca, cb, t), (a.width - n + i, 0))
	return out


def build_bg() -> list:
	parts = [scaled(load(n)) for n in SCENES]
	bg = parts[0]
	seams = []
	for p in parts[1:]:
		seams.append(bg.width - SEAM // 2)
		bg = crossfade(bg, p, SEAM)
	bg.save(OUT / "bg_pueblo.png")
	print("bg_pueblo.png", bg.size, "uniones en x =", seams)
	return seams


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
	build_bg()
	build_ground()
