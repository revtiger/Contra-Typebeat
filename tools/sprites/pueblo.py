"""Fondo y suelo del pueblo de la pampa (fase 1.1, Argentina).

Fuente: ilustraciones de Eduardo (ChatGPT) en tools/sprites/chatgpt/pueblo/:
  cielo_pampa.png  cielo del atardecer con un solo sol y la pampa (fondo lejano)
  1_almacen, 2_capilla_taller, 3_plaza_massa (1983x793): escenas de referencia;
  de la 1 sale la calle. Los edificios se añadirán aparte como capa propia.
Si existe <nombre>_limpia.png (la misma escena sin personajes) se usa esa.

Salida:
  assets/sprites/bg_pueblo.png      cielo y pampa, 270 px de alto (se mueve muy despacio)
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
	build_ground()
