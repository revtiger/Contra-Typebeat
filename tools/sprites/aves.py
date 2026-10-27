"""Aves lejanas para el cielo del pueblo (fase 1.1): siluetas que aletean.

Salida: assets/sprites/aves.png, dos filas de 5 fotogramas:
  fila 0: ave lejana, celdas de 12x8, silueta clara (se funde con el atardecer)
  fila 1: ave más cerca, celdas de 24x16 (la misma silueta al doble), más oscura y con el borde
          de las alas iluminado por el sol
Fotogramas: 0 alas muy arriba, 1 arriba, 2 planeo, 3 abajo, 4 muy abajo. background.gd los recorre
0-1-2-3-4-3-2-1 al aletear y deja el 2 cuando el ave planea.

Uso: python tools/sprites/aves.py
"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets/sprites/aves.png"

FRAMES = [
	[
		"X.........X",
		".X.......X.",
		"..X.....X..",
		"...X...X...",
		"....XXX....",
		".....X.....",
	],
	[
		"...........",
		"XX.......XX",
		"..X.....X..",
		"...XX.XX...",
		"....XXX....",
		".....X.....",
	],
	[
		"...........",
		"...........",
		"XXX.....XXX",
		"...XXXXX...",
		".....X.....",
		"...........",
	],
	[
		"...........",
		"...........",
		"....XXX....",
		"..XX.X.XX..",
		".X.......X.",
		"X.........X",
	],
	[
		"...........",
		"...........",
		"....XXX....",
		"...X.X.X...",
		"...X...X...",
		"..X.....X..",
	],
]

LEJANA = (92, 52, 66, 255)      # violeta apagado: se ve lejos contra el naranja
CERCA = (40, 22, 30, 255)       # casi negro
BRILLO = (170, 96, 60, 255)     # borde de arriba de las alas, iluminado por el atardecer


def frame(rows, scale, color, rim=None):
	cw, ch = 12 * scale, 8 * scale
	im = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
	px = im.load()
	for y, row in enumerate(rows):
		for x, c in enumerate(row):
			if c != "X":
				continue
			for dy in range(scale):
				for dx in range(scale):
					px[x * scale + dx, (y + 1) * scale + dy] = color
	if rim:
		# ilumina el píxel de más arriba de cada columna (lo que mira al sol)
		for x in range(cw):
			for y in range(ch):
				if px[x, y][3]:
					px[x, y] = rim
					break
	return im


def main():
	sheet = Image.new("RGBA", (24 * 5, 8 + 16), (0, 0, 0, 0))
	for i, rows in enumerate(FRAMES):
		sheet.alpha_composite(frame(rows, 1, LEJANA), (i * 12, 0))
		sheet.alpha_composite(frame(rows, 2, CERCA, BRILLO), (i * 24, 8))
	sheet.save(OUT)
	print(OUT.name, sheet.size)


if __name__ == "__main__":
	main()
