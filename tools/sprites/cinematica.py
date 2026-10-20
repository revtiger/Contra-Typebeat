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
                           cola girando, los dos en el sentido del reloj); HELI_FRAMES fotogramas (columnas) dan
                           un cuarto de vuelta y se repiten sin salto; cada fila es una inclinación (TILTS), girada
                           a 4x y reducida, para no girar el sprite en el juego (se veía plano, como de papel)
  cine_heli_meta.json      tamaño de fotograma, número de fotogramas, inclinaciones y la puerta por donde salta

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
TILTS = [i * 0.5 for i in range(-12, 13)]  # inclinaciones dibujadas (grados; + = morro abajo), una fila cada una
SS = 4                # se dibuja a 4 veces el tamaño del juego y se reduce al final (bordes limpios)
# en helicoptero.png (px del original, mirando a la izquierda)
BODY_X = (80, 1640)   # del morro (con el cañón) a la cola
HUB = (680, 195)      # centro del rotor principal
ROTOR_R = 650         # largo de una pala
ROTOR_K = 0.30        # aplastamiento del disco del rotor (se ve desde un poco arriba, como en la referencia)
CHORD = (56, 100)     # ancho de la pala en la raíz y en la punta
THICK = 22            # grosor de la pala (lo que se ve de canto)
TAIL = (1630, 320)    # centro del rotor de cola
TAIL_R = 150
FIN = [(1490, 440), (1588, 318), (1652, 330), (1634, 470), (1500, 478)]  # aleta, detrás del rotor de cola
DOOR = (680, 790)     # puerta de la cabina (ventana grande), a la altura del patín
PAD = 10              # margen a los lados (px del juego)
PAD_Y = 12            # margen arriba y abajo para inclinarlo
BLADE = (46, 49, 56)
BLADE_HI = (92, 97, 108)
INK = (14, 14, 18)
STRIPE = (230, 230, 230)
HUB_C = (84, 88, 98)


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def cuerpo_solo(scale):
	"""El helicóptero sin rotores, a la escala dada: se borran las palas del principal (todo lo que hay sobre el
	fuselaje menos el cubo y el mástil) y el rotor de cola (un círculo alrededor de su cubo, menos la aleta)."""
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
	small = big.resize((round(big.width * scale), round(big.height * scale)), Image.LANCZOS)
	# la aleta se repinta lisa (quedaban trozos de la pala de abajo encima)
	d = ImageDraw.Draw(small)
	d.polygon([(x * scale, y * scale) for x, y in FIN], fill=(70, 72, 80, 255), outline=INK + (255,), width=SS)
	return small


def _pala(d, c, ang, r, k, chord, thick, color=None, tips=True):
	"""Una pala con forma de remo desde el centro c, ángulo ang en el plano del rotor (aplastado por k en y):
	la cara de arriba (que se acorta con la perspectiva), el canto (grosor fijo) y las franjas de la punta."""
	def p(u, v):  # u a lo largo de la pala (0..1), v a lo ancho (-1..1)
		ca, sa = math.cos(ang), math.sin(ang)
		w = (chord[0] + (chord[1] - chord[0]) * u) / 2 * v
		x = ca * r * u - sa * w
		y = (sa * r * u + ca * w) * k
		return (c[0] + x, c[1] + y)
	cara = [p(0.08, -1), p(0.97, -1), p(1, -0.4), p(1, 0.4), p(0.97, 1), p(0.08, 1)]
	if color:  # fantasma de la estela: solo la silueta
		d.polygon(cara, fill=color)
		return
	canto = [(x, y + thick) for x, y in cara]
	d.polygon(canto, fill=INK + (255,))
	d.polygon(cara, fill=BLADE + (255,), outline=INK + (255,), width=SS)
	d.line([p(0.12, -0.45), p(0.94, -0.45)], fill=BLADE_HI + (255,), width=SS)
	if tips:
		for u0, u1 in ((0.78, 0.83), (0.87, 0.92)):
			d.polygon([p(u0, -0.85), p(u1, -0.85), p(u1, 0.85), p(u0, 0.85)], fill=STRIPE + (255,))


def _rotor_cola(d, c, ang, r):
	for b in range(4):
		a = ang + b * math.pi / 2
		tip = (c[0] + math.cos(a) * r, c[1] + math.sin(a) * r)
		d.line([c, tip], fill=INK + (255,), width=4 * SS)
		d.line([c, tip], fill=BLADE + (255,), width=2 * SS)
	d.ellipse((c[0] - 2.5 * SS, c[1] - 2.5 * SS, c[0] + 2.5 * SS, c[1] + 2.5 * SS), fill=HUB_C + (255,), outline=INK + (255,), width=SS)


def _fotograma(body, i, W, H, hub, tail, R, r):
	"""Un fotograma a tamaño SS (mirando a la izquierda, como el original): capa opaca y capa de estela."""
	# sentido de giro, ya volteado a la derecha: el principal, el de las agujas del reloj visto desde arriba (la
	# pala de delante pasa hacia la izquierda); el de cola, el del reloj tal como se ve en pantalla. Aquí (antes
	# de voltear) los dos ángulos decrecen
	step = math.radians(90.0 / HELI_FRAMES)
	spin = i * step
	a0 = -spin
	chord = (CHORD[0] * SS * HELI_W / (BODY_X[1] - BODY_X[0]), CHORD[1] * SS * HELI_W / (BODY_X[1] - BODY_X[0]))
	thick = THICK * SS * HELI_W / (BODY_X[1] - BODY_X[0])
	glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	gd = ImageDraw.Draw(glow)
	gd.ellipse((hub[0] - R, hub[1] - R * ROTOR_K, hub[0] + R, hub[1] + R * ROTOR_K), fill=(70, 74, 84, 30))
	for g, al in ((1, 80), (2, 45), (3, 22)):
		for b in range(4):
			_pala(gd, hub, a0 + b * math.pi / 2 + g * step * 1.4, R, ROTOR_K, chord, thick, color=(52, 56, 64, al))
	gd.ellipse((tail[0] - r, tail[1] - r, tail[0] + r, tail[1] + r), fill=(70, 74, 84, 45))
	f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	angs = [a0 + b * math.pi / 2 for b in range(4)]
	d = ImageDraw.Draw(f)
	for a in sorted(angs, key=math.sin):  # de la más lejana a la más cercana
		if math.sin(a) < 0:
			_pala(d, hub, a, R, ROTOR_K, chord, thick)
	f.alpha_composite(body, (PAD * SS, PAD_Y * SS))
	d = ImageDraw.Draw(f)
	for a in sorted(angs, key=math.sin):
		if math.sin(a) >= 0:
			_pala(d, hub, a, R, ROTOR_K, chord, thick)
	d.ellipse((hub[0] - 4 * SS, hub[1] - 2.5 * SS, hub[0] + 4 * SS, hub[1] + 2 * SS), fill=HUB_C + (255,), outline=INK + (255,), width=SS)
	_rotor_cola(d, tail, -spin * 2, r)
	return f, glow


def helicoptero():
	scale = HELI_W / (BODY_X[1] - BODY_X[0])
	body = cuerpo_solo(scale * SS)
	W = body.width + 2 * PAD * SS
	H = body.height + 2 * PAD_Y * SS
	off = (PAD * SS, PAD_Y * SS)
	hub = (HUB[0] * scale * SS + off[0], HUB[1] * scale * SS + off[1])
	tail = (TAIL[0] * scale * SS + off[0], TAIL[1] * scale * SS + off[1])
	R, r = ROTOR_R * scale * SS, TAIL_R * scale * SS
	fw, fh = W // SS, H // SS
	center = (W / 2, H / 2)
	sheet = Image.new("RGBA", (fw * HELI_FRAMES, fh * len(TILTS)), (0, 0, 0, 0))
	for i in range(HELI_FRAMES):
		f, glow = _fotograma(body, i, W, H, hub, tail, R, r)
		f, glow = f.transpose(Image.FLIP_LEFT_RIGHT), glow.transpose(Image.FLIP_LEFT_RIGHT)  # mirando a la derecha
		for row, deg in enumerate(TILTS):
			# + = morro (a la derecha) abajo: giro en el sentido del reloj en pantalla
			fr = f.rotate(-deg, Image.BICUBIC, center=center).resize((fw, fh), Image.LANCZOS)
			gl = glow.rotate(-deg, Image.BICUBIC, center=center).resize((fw, fh), Image.LANCZOS)
			out = gl.copy()
			out.alpha_composite(nitido(fr))
			sheet.alpha_composite(out, (i * fw, row * fh))
	sheet.save(OUT / "cine_heli.png")
	door = [round(fw - (DOOR[0] * scale + PAD)), round(DOOR[1] * scale + PAD_Y)]
	meta = {"frame": [fw, fh], "frames": HELI_FRAMES, "tilts": TILTS, "door": door}
	(OUT / "cine_heli_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("cine_heli.png", sheet.size, "fotograma", (fw, fh), "puerta", door)


def main():
	sky = Image.open(SRC / "cielo_aereo.png").convert("RGB")
	s = SKY_H / sky.height
	sky = sky.resize((round(sky.width * s), SKY_H), Image.LANCZOS)
	sky.save(OUT / "cine_cielo.png")
	print("cine_cielo.png", sky.size)
	helicoptero()


if __name__ == "__main__":
	main()
