"""Vecinos del pueblo (fase 1.1): 12 civiles de perfil de Eduardo (ChatGPT), animados con PixelLab.

Paso 1 (base): corta las 3 hojas de tools/sprites/chatgpt/pueblo/vecinos/hoja_N.png (4 vecinos por hoja,
de perfil mirando a la derecha, fondo transparente) y deja cada uno en un lienzo de BASE x BASE con los pies
abajo al centro: tools/sprites/pixellab/vecinos/<nombre>_base.png. Esas bases se animan con PixelLab
(animate_image, "walking", 8 fotogramas) y los fotogramas se guardan como <nombre>_walk.png (tira horizontal
de 9 fotogramas: el 0 es la base).

Paso 2 (juego): monta assets/sprites/vecinos.png, una fila por vecino: fotograma 0 quieto y 1..8 caminando,
en celdas de FW x FH con los pies en (FW/2, FH-2), a la escala del soldado. Si un vecino aún no tiene
<nombre>_walk.png, su fila repite la pose quieta.

Uso: python tools/sprites/vecinos.py base | juego
"""
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from heroes_sheets import blobs  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/pueblo/vecinos"
PL = ROOT / "tools/sprites/pixellab/vecinos"
OUT = ROOT / "assets/sprites"

# vecinos de cada hoja, de izquierda a derecha
HOJAS = {
	1: ["panadero", "almacenera", "carpintero", "moza"],
	2: ["mecanico", "cartera", "abuelo", "florista"],
	3: ["chico", "chica", "mochilero", "chica_bolso"],
}
NOMBRES = [n for k in sorted(HOJAS) for n in HOJAS[k]]

BASE = 96          # lienzo para PixelLab
BASE_ALTO = 690    # px del original que ocupan BASE_FIG px (misma escala para todos: se respetan las alturas)
BASE_FIG = 88
FW, FH = 40, 52    # celda en el juego
ALTO_JUEGO = 46    # el vecino más alto mide como el soldado
FRAMES = 9


def recortes(k):
	im = Image.open(SRC / f"hoja_{k}.png").convert("RGBA")
	mask = im.getchannel("A").point(lambda v: 255 if v > 100 else 0)
	bs = sorted([b for b in blobs(mask) if b[4] > 200], key=lambda b: b[0])
	out = []
	for b in bs:
		fig = im.crop((b[0], b[1], b[2], b[3]))
		out.append(fig.crop(fig.getchannel("A").point(lambda v: 255 if v > 100 else 0).getbbox()))
	return out


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def base():
	PL.mkdir(parents=True, exist_ok=True)
	s = BASE_FIG / BASE_ALTO
	for k, nombres in HOJAS.items():
		figs = recortes(k)
		assert len(figs) == len(nombres), (k, len(figs))
		for name, fig in zip(nombres, figs):
			f = nitido(fig.resize((round(fig.width * s), round(fig.height * s)), Image.LANCZOS))
			c = Image.new("RGBA", (BASE, BASE), (0, 0, 0, 0))
			c.alpha_composite(f, ((BASE - f.width) // 2, BASE - 2 - f.height))
			c.save(PL / f"{name}_base.png")
			print(name, f.size)


def juego():
	s = ALTO_JUEGO / BASE_FIG
	sheet = Image.new("RGBA", (FW * FRAMES, FH * len(NOMBRES)), (0, 0, 0, 0))
	for row, name in enumerate(NOMBRES):
		walk = PL / f"{name}_walk.png"
		if walk.exists():
			strip = Image.open(walk).convert("RGBA")
			frames = [strip.crop((i * BASE, 0, (i + 1) * BASE, BASE)) for i in range(strip.width // BASE)]
		else:
			frames = [Image.open(PL / f"{name}_base.png").convert("RGBA")]
		frames = (frames + [frames[-1]] * FRAMES)[:FRAMES] if len(frames) > 1 else frames * FRAMES
		for col, fr in enumerate(frames):
			small = nitido(fr.resize((round(BASE * s), round(BASE * s)), Image.LANCZOS))
			# los pies de la base van en y = BASE-2 -> en la celda, en FH-2
			x = col * FW + FW // 2 - small.width // 2
			y = row * FH + (FH - 2) - round((BASE - 2) * s)
			sheet.alpha_composite(small, (x, y))
	sheet.save(OUT / "vecinos.png")
	print("vecinos.png", sheet.size)


if __name__ == "__main__":
	{"base": base, "juego": juego}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
