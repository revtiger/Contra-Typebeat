"""Arte de la cinemática de llegada a la 1.1 (scripts/cinematica_llegada.gd), dibujado por Eduardo con ChatGPT.

Fuente (tools/sprites/chatgpt/cinematica/):
  cielo_aereo.png          toma aérea del atardecer por donde llega el helicóptero
  helicoptero.png          el helicóptero (mirando a la izquierda): de aquí sale el cuerpo, sin los rotores
  helicoptero_rotor_4.png  referencia de cómo se ve el rotor de 4 palas en perspectiva
  helicoptero_anim_1/2.png primera tirada de 8 fotogramas (ya no se usa: cada uno estaba dibujado aparte y el
                           cuerpo y las palas temblaban al pasarlos)

Salida (assets/sprites/):
  cine_cielo.png           el cielo a la altura de la pantalla (270 px), más ancho para el paneo
  cine_heli.png            el helicóptero mirando a la derecha (hacia donde vuela): un solo cuerpo fijo y los
                           rotores dibujados aquí en cada fotograma (4 palas en perspectiva con estela y el de
                           cola girando); HELI_FRAMES fotogramas dan un cuarto de vuelta y se repiten sin salto
  cine_heli_meta.json      tamaño de fotograma, número de fotogramas y la puerta por donde salta el soldado

Uso: python tools/sprites/cinematica.py
"""
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/cinematica"
OUT = ROOT / "assets/sprites"

SKY_H = 270
HELI_W = 170          # ancho del cuerpo del helicóptero en el juego (del morro a la cola, sin las palas)
HELI_FRAMES = 12      # un cuarto de vuelta del rotor (4 palas: se repite)
# en helicoptero.png (px del original, mirando a la izquierda)
BODY_X = (80, 1640)   # del morro (con el cañón) a la cola
HUB = (680, 195)      # centro del rotor principal
ROTOR_R = 745         # largo de una pala
ROTOR_K = 0.16        # aplastamiento del disco del rotor (se ve un poco desde arriba)
TAIL = (1630, 320)    # centro del rotor de cola
TAIL_R = 150
FIN = [(1490, 440), (1588, 318), (1652, 330), (1634, 470), (1500, 478)]  # aleta, detrás del rotor de cola
DOOR = (680, 790)     # puerta de la cabina (ventana grande), a la altura del patín
PAD = 10
BLADE = (52, 55, 62)
BLADE_HI = (96, 100, 110)
INK = (16, 16, 20)
STRIPE = (226, 226, 226)


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def cuerpo_solo(scale):
	"""El helicóptero sin rotores, reducido: se borran las palas del principal (todo lo que hay sobre el fuselaje
	menos el cubo y el mástil) y el rotor de cola (un círculo alrededor de su cubo, menos la aleta)."""
	big = Image.open(SRC / "helicoptero.png").convert("RGBA")
	px = big.load()
	fin = Image.new("L", big.size, 0)
	ImageDraw.Draw(fin).polygon(FIN, fill=255)
	fpx = fin.load()
	for y in range(big.height):
		for x in range(big.width):
			if not px[x, y][3]:
				continue
			main = (x < 540 and y < 300) or ((540 <= x < 590 or x >= 770) and y < 240)
			tail = (x - TAIL[0]) ** 2 + (y - TAIL[1]) ** 2 < TAIL_R ** 2 and not fpx[x, y]
			if main or tail:
				px[x, y] = (0, 0, 0, 0)
	small = nitido(big.resize((round(big.width * scale), round(big.height * scale)), Image.LANCZOS))
	# la aleta se repinta lisa (quedaban trozos de la pala de abajo encima)
	d = ImageDraw.Draw(small)
	d.polygon([(x * scale, y * scale) for x, y in FIN], fill=(70, 72, 80, 255), outline=INK + (255,))
	return small


def _pala(d, c, ang, r, k, w, tips=True, alpha=255):
	"""Una pala desde el centro c con ángulo ang (en el plano del rotor), aplastada por k."""
	tip = (c[0] + math.cos(ang) * r, c[1] + math.sin(ang) * r * k)
	if alpha < 255:
		d.line([c, tip], fill=BLADE + (alpha,), width=w)
		return
	d.line([c, tip], fill=INK + (255,), width=w + 2)
	d.line([c, tip], fill=BLADE + (255,), width=w)
	if w >= 2:
		d.line([(c[0], c[1] - 1), (tip[0], tip[1] - 1)], fill=BLADE_HI + (255,), width=1)
	if tips:
		for f0, f1 in ((0.80, 0.85), (0.89, 0.94)):
			a = (c[0] + (tip[0] - c[0]) * f0, c[1] + (tip[1] - c[1]) * f0)
			b = (c[0] + (tip[0] - c[0]) * f1, c[1] + (tip[1] - c[1]) * f1)
			d.line([a, b], fill=STRIPE + (255,), width=w)


def helicoptero():
	scale = HELI_W / (BODY_X[1] - BODY_X[0])
	body = cuerpo_solo(scale)
	W, H = body.width + 2 * PAD, body.height + 2
	hub = (HUB[0] * scale + PAD, HUB[1] * scale)
	tail = (TAIL[0] * scale + PAD, TAIL[1] * scale)
	R, r = ROTOR_R * scale, TAIL_R * scale
	sheet = Image.new("RGBA", (W * HELI_FRAMES, H), (0, 0, 0, 0))
	for i in range(HELI_FRAMES):
		a0 = math.radians(i * 90.0 / HELI_FRAMES)
		f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		# estela del giro: un disco muy tenue y dos fantasmas de cada pala detrás
		blur = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		bd = ImageDraw.Draw(blur)
		bd.ellipse((hub[0] - R, hub[1] - R * ROTOR_K, hub[0] + R, hub[1] + R * ROTOR_K), fill=(70, 74, 84, 34))
		for g, al in ((1, 70), (2, 36)):
			for b in range(4):
				_pala(bd, hub, a0 + b * math.pi / 2 - g * math.radians(10), R, ROTOR_K, 2, alpha=al)
		f.alpha_composite(blur)
		# palas del fondo (por encima del cubo en pantalla) detrás del cuerpo; las de delante, encima
		angs = [a0 + b * math.pi / 2 for b in range(4)]
		d = ImageDraw.Draw(f)
		for a in angs:
			if math.sin(a) < 0:
				_pala(d, hub, a, R, ROTOR_K, 2)
		f.alpha_composite(body, (PAD, 0))
		d = ImageDraw.Draw(f)
		for a in angs:
			if math.sin(a) >= 0:
				_pala(d, hub, a, R, ROTOR_K, 2)
		# rotor de cola: gira en su plano (se ve de lado: círculo entero), el doble de rápido
		tb = Image.new("RGBA", (W, H), (0, 0, 0, 0))
		ImageDraw.Draw(tb).ellipse((tail[0] - r, tail[1] - r, tail[0] + r, tail[1] + r), fill=(70, 74, 84, 40))
		f.alpha_composite(tb)
		d = ImageDraw.Draw(f)
		for b in range(4):
			_pala(d, tail, a0 * 2 + b * math.pi / 2, r, 1.0, 1, tips=False)
		d.ellipse((tail[0] - 2, tail[1] - 2, tail[0] + 2, tail[1] + 2), fill=(90, 94, 104, 255), outline=INK + (255,))
		# mirando a la derecha (hacia donde vuela)
		sheet.alpha_composite(f.transpose(Image.FLIP_LEFT_RIGHT), (i * W, 0))
	sheet.save(OUT / "cine_heli.png")
	door = [round(W - (DOOR[0] * scale + PAD)), round(DOOR[1] * scale)]
	meta = {"frame": [W, H], "frames": HELI_FRAMES, "door": door}
	(OUT / "cine_heli_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("cine_heli.png", sheet.size, "puerta", door)


def main():
	sky = Image.open(SRC / "cielo_aereo.png").convert("RGB")
	s = SKY_H / sky.height
	sky = sky.resize((round(sky.width * s), SKY_H), Image.LANCZOS)
	sky.save(OUT / "cine_cielo.png")
	print("cine_cielo.png", sky.size)
	helicoptero()


if __name__ == "__main__":
	main()
