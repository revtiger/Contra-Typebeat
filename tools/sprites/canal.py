"""Canalón y cajas de la 1.1 (pueblo de la pampa).

  canal_pared.png  pared del fondo del canal de desagüe: losas de concreto con juntas, grietas, manchas de humedad
                   y algo de musgo, con el borde de arriba (el bordillo de la calle). Se repite en horizontal sin corte.
  canal_fondo.png  fondo del canal: barro oscuro con charcos que reflejan el atardecer. Se repite en horizontal.
  caja.png         caja de madera para subir a los toldos (PixelLab: tools/sprites/pixellab/pueblo_extra/caja.png),
                   reducida a CAJA px.
terrain.gd dibuja el canal (tramos de suelo más bajos que la calle) con estas tiras; caja.gd, las cajas.

Uso: python tools/sprites/canal.py
"""
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/sprites"
PL = ROOT / "tools/sprites/pixellab/pueblo_extra"

W = 192          # ancho de la tira (se repite)
PARED_H = 28     # alto de la pared: de la calle (y 230) al fondo del canal (y 258)
FONDO_H = 14
LOSA = 48        # ancho de cada losa de concreto
CAJA = 24

# concreto viejo con la luz cálida del atardecer
CONCRETO = [(92, 84, 86), (108, 99, 98), (124, 113, 108), (140, 128, 119), (158, 144, 130)]
JUNTA = (58, 50, 56)
HUMEDAD = (74, 70, 72)
MUSGO = [(78, 92, 50), (98, 112, 58)]
BORDE = [(176, 160, 140), (150, 136, 122), (70, 58, 60)]
BARRO = [(44, 32, 30), (58, 42, 36), (72, 52, 42), (86, 64, 50)]
CHARCO = [(120, 70, 60), (186, 104, 70), (236, 156, 92), (250, 206, 140)]


def ruido(w, h, seed, escala):
	"""Ruido suave que se repite en horizontal (suma de senos con fases al azar)."""
	import math
	rnd = random.Random(seed)
	ondas = [(rnd.randint(1, 6), rnd.uniform(0.2, 1.0), rnd.uniform(0, 6.3), rnd.uniform(0, 6.3)) for _ in range(6)]
	out = []
	for y in range(h):
		fila = []
		for x in range(w):
			v = 0.0
			for k, a, fx, fy in ondas:
				v += a * math.sin(2 * math.pi * k * x / w + fx) * math.cos(y / escala * k * 0.7 + fy)
			fila.append(v)
		out.append(fila)
	return out


def pared():
	rnd = random.Random(7)
	im = Image.new("RGB", (W, PARED_H))
	px = im.load()
	n = ruido(W, PARED_H, 3, 6.0)
	for y in range(PARED_H):
		for x in range(W):
			v = n[y][x] * 0.35 + rnd.uniform(-0.45, 0.45)
			# más oscuro abajo (sombra del fondo del canal) y claro arriba
			v += 1.6 - 2.4 * y / PARED_H
			i = max(0, min(len(CONCRETO) - 1, int(round(v + 1.5))))
			px[x, y] = CONCRETO[i]
	# manchas de humedad que bajan desde las juntas
	for x0 in range(0, W, LOSA):
		for k in range(2):
			sx = (x0 + rnd.randint(6, LOSA - 6)) % W
			for y in range(4, rnd.randint(14, PARED_H)):
				px[sx, y] = HUMEDAD
				if rnd.random() < 0.4:
					px[(sx + 1) % W, y] = HUMEDAD
	# juntas verticales entre losas y una junta horizontal
	for x0 in range(0, W, LOSA):
		for y in range(4, PARED_H):
			px[x0, y] = JUNTA
	for x in range(W):
		px[x, 15] = JUNTA
	# grietas
	for _ in range(5):
		x, y = rnd.randrange(W), rnd.randint(6, PARED_H - 4)
		for _ in range(rnd.randint(4, 9)):
			px[x % W, y] = JUNTA
			x += rnd.choice((-1, 0, 1, 1))
			y = max(5, min(PARED_H - 1, y + rnd.choice((0, 1, 1))))
	# musgo al pie de la pared
	for x in range(W):
		h = int(max(0, n[PARED_H - 1][x] * 2.2 + rnd.uniform(-1, 2)))
		for y in range(PARED_H - h, PARED_H):
			px[x, y] = MUSGO[rnd.randrange(2)]
	# bordillo de la calle arriba
	for x in range(W):
		px[x, 0] = BORDE[0]
		px[x, 1] = BORDE[0] if rnd.random() < 0.8 else BORDE[1]
		px[x, 2] = BORDE[1]
		px[x, 3] = BORDE[2]
	im.save(OUT / "canal_pared.png")
	print("canal_pared.png", im.size)


def fondo():
	rnd = random.Random(11)
	im = Image.new("RGB", (W, FONDO_H))
	px = im.load()
	n = ruido(W, FONDO_H, 5, 3.0)
	for y in range(FONDO_H):
		for x in range(W):
			v = n[y][x] * 0.5 + rnd.uniform(-0.6, 0.6) + 1.5 - y * 0.12
			px[x, y] = BARRO[max(0, min(3, int(round(v))))]
	# charcos alargados que reflejan el cielo del atardecer
	x = 6
	while x < W - 30:
		w = rnd.randint(14, 30)
		y = rnd.randint(2, 6)
		for dx in range(w):
			t = dx / (w - 1)
			alto = 1 if t < 0.15 or t > 0.85 else 2
			for dy in range(alto):
				c = CHARCO[min(3, 1 + int(2.6 * (1 - abs(t - 0.5) * 2)) - dy)]
				px[x + dx, y + dy] = c
		px[x + w // 3, y] = CHARCO[3]
		x += w + rnd.randint(18, 44)
	# piedritas
	for _ in range(14):
		x, y = rnd.randrange(W), rnd.randint(5, FONDO_H - 2)
		px[x, y] = (120, 104, 92)
		px[x, y + 1] = (60, 46, 40)
	# borde de arriba, mojado
	for x in range(W):
		px[x, 0] = (34, 26, 26)
	im.save(OUT / "canal_fondo.png")
	print("canal_fondo.png", im.size)


def caja():
	src = Image.open(PL / "caja.png").convert("RGBA")
	src = src.crop(src.getbbox())
	im = src.resize((CAJA, CAJA), Image.LANCZOS)
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 110 else 0))
	im.save(OUT / "caja.png")
	print("caja.png", im.size)


if __name__ == "__main__":
	pared()
	fondo()
	caja()
