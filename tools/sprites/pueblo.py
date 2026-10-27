"""Fondo, calle y suelo del pueblo de la pampa (fase 1.1, Argentina).

Fuente: piezas sueltas de Eduardo (ChatGPT, fondo transparente) en tools/sprites/chatgpt/pueblo/:
  cielo_pampa.png       cielo del atardecer con un solo sol y la pampa (fondo lejano)
  edificios/<nombre>.png  edificios (1254x1254)
  arboles/<nombre>.png    árboles
  valla.png             valla de madera que cubre los huecos entre edificios
  tramo02.png           de aquí sale la franja de vereda y adoquines de la calle
  1_almacen.png         de aquí sale la tira del suelo (ground_pueblo.png)
La calle entera se arma pieza por pieza según CALLE: edificios en fila, valla en los huecos y
árboles detrás de la valla.

Salida:
  assets/sprites/bg_pueblo.png        cielo y pampa, 270 px de alto (se mueve muy despacio)
  assets/sprites/pueblo_tramo_NN.png  la calle cortada en trozos de TROZO px (el juego los pone en fila)
  assets/sprites/ground_pueblo.png    tira de adoquines y tierra que se repite en el suelo
  scripts/pueblo_casas.gd             puerta, ventanas y vecino de cada edificio en coordenadas del mundo
                                      (civilian.gd: los vecinos pasean frente a su puerta, entran y se asoman)

Uso: python tools/sprites/pueblo.py  (imprime el largo de la calle: es el "end" de la plantilla
"pueblo" en scripts/levels.gd)
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/pueblo"
OUT = ROOT / "assets/sprites"
H = 270

# Cielo: escala y desplazamiento para que el campo amarillo (y=680 en el original)
# quede en y=195 de la pantalla, por encima del suelo (y=230).
SKY_SCALE = 0.4
SKY_FIELD = 680
SKY_FIELD_Y = 195

# Suelo: tramo de calle sin personajes de la escena 1 (coordenadas de la imagen original)
GROUND_BOX = (480, 640, 1400, 793)
GROUND_BLEND = 24

# Edificios: alto de la puerta en el original (px), para dejarlos todos a la misma escala del juego.
# La puerta normal queda de PUERTA px (algo más alta que el soldado); el galpón y la capilla, más grandes.
EDIFICIOS = {
	"casa": 350, "almacen": 355, "casa_2_pisos": 350, "panaderia": 440, "casa_garaje": 320,
	"ferreteria": 412, "capilla": 365, "galpon": 455, "cafe": 380, "encomiendas": 415,
}
# Puerta y ventanas de cada edificio, en px del edificio ya a escala del juego: (x0, y0, x1, y1).
# Las ventanas son el hueco del vidrio, donde se asoma el vecino.
ZONAS = {
	"casa": {"puerta": (80, 62, 100, 117), "ventanas": [(33, 63, 50, 88), (133, 63, 152, 88)]},
	"almacen": {"puerta": (88, 86, 118, 140), "ventanas": [(25, 78, 42, 100)]},
	"casa_2_pisos": {"puerta": (102, 108, 127, 160), "ventanas": [(52, 45, 78, 68), (112, 45, 130, 70), (46, 110, 72, 138)]},
	"panaderia": {"puerta": (90, 63, 112, 112), "ventanas": [(30, 72, 78, 96)]},
	"casa_garaje": {"puerta": (58, 80, 75, 130), "ventanas": [(25, 76, 40, 102)]},
	"ferreteria": {"puerta": (64, 72, 89, 120), "ventanas": [(28, 78, 58, 104), (97, 78, 120, 104)]},
	"capilla": {"puerta": (76, 132, 119, 195), "ventanas": [(34, 136, 52, 160), (142, 136, 160, 160)]},
	"galpon": {"puerta": (52, 60, 125, 131), "ventanas": [(83, 27, 100, 45), (141, 79, 157, 100)]},
	"cafe": {"puerta": (66, 80, 90, 130), "ventanas": [(28, 79, 55, 104), (104, 79, 130, 104)]},
	"encomiendas": {"puerta": (97, 47, 120, 100), "ventanas": [(30, 53, 78, 80)]},
}
# Quién vive en cada edificio (fila de vecinos.png, ver tools/sprites/vecinos.py); si el edificio se repite
# se van turnando. -1 = nadie.
VECINO = {
	"panaderia": [0], "almacen": [1], "ferreteria": [2], "cafe": [3], "casa_garaje": [4, 10],
	"encomiendas": [5], "casa": [6, 8, 9, 11], "capilla": [7], "casa_2_pisos": [9, 3, 11, 8], "galpon": [10],
}

## Escala de la calle (edificios, árboles, valla y huecos). 1 = la original de Eduardo; 1.2 (25-10-2026) los
## acerca un poco (se probó 2 y se redujo un 40 %); los más altos pueden quedar cortados por arriba de la
## pantalla. Las medidas de PUERTA, ZONAS, ARBOLES, VALLA_ALTO y los huecos de CALLE están a escala 1 y se
## multiplican por ESCALA (redondeando a px enteros).
ESCALA = 1.2
PUERTA = 52
PUERTA_GRANDE = {"galpon": 70, "capilla": 62}
BASE = 207  # y donde apoyan los edificios (borde de arriba de la vereda)

# Árboles: alto en el juego (px). El tronco apoya en la vereda, detrás de la valla y de los edificios.
ARBOLES = {
	"ombu": 150, "ombu_grande": 145, "sauce": 135, "alamo": 175, "jacaranda": 140, "pino": 150,
	"eucalipto": 165, "naranjo": 100, "cedro": 155, "palmera": 135,
}

# Valla: alto en el juego y, en el original, dónde empieza y acaba el tramo que se repite (poste izquierdo
# incluido) y dónde está el poste derecho, que cierra cada hueco.
VALLA_ALTO = 34
VALLA_BOX = (102, 106, 1898, 545)
VALLA_REPITE = (102, 1812)

# La calle de punta a punta: nombre = edificio; número = hueco con valla de ese ancho;
# (árbol, ancho) = hueco con valla y un árbol detrás. Al final, la capilla con el ombú grande:
# es la plaza donde pelea Massa (los últimos 480 px).
CALLE = [
	16, "casa", ("ombu", 60), "almacen", ("cedro", 52), "casa_2_pisos", ("jacaranda", 56), "casa_garaje",
	("pino", 54), "casa", ("naranjo", 40), "panaderia", ("ombu", 60), "ferreteria", ("alamo", 40), "cafe",
	("eucalipto", 52), "casa_2_pisos", ("sauce", 54), "encomiendas", ("jacaranda", 56), "casa",
	("cedro", 52), "casa_garaje", ("naranjo", 40), "galpon", ("eucalipto", 52), "casa", ("alamo", 40),
	"casa_2_pisos", ("pino", 54), "casa", ("naranjo", 40), "almacen", ("ombu", 60), "casa_garaje",
	("cedro", 52), "casa", ("jacaranda", 56), "casa_2_pisos", ("ombu_grande", 130), "capilla", ("sauce", 70), 60,
]
TROZO = 800


def load(name: str) -> Image.Image:
	return Image.open(SRC / f"{name}.png").convert("RGB")


def opaco(im: Image.Image) -> Image.Image:
	"""Recorta lo transparente y deja cada píxel opaco o transparente (bordes nítidos de pixel art)."""
	return im.crop(im.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox())


def nitido(im: Image.Image) -> Image.Image:
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def build_sky() -> None:
	src = load("cielo_pampa")
	s = SKY_SCALE
	big = src.resize((round(src.width * s), round(src.height * s)), Image.LANCZOS)
	top = round(SKY_FIELD * s) - SKY_FIELD_Y
	sky = Image.new("RGB", (big.width, H), big.getpixel((big.width // 2, big.height - 1)))
	sky.paste(big.crop((0, top, big.width, min(big.height, top + H))), (0, 0))
	sky.save(OUT / "bg_pueblo.png")
	print("bg_pueblo.png", sky.size)


VALLA_H = round(VALLA_ALTO * ESCALA)


def pegar(out: Image.Image, im: Image.Image, x: int, y: int) -> None:
	"""alpha_composite que recorta lo que se sale por arriba (los edificios altos con ESCALA > 1)."""
	if y < 0:
		im = im.crop((0, -y, im.width, im.height))
		y = 0
	out.alpha_composite(im, (x, y))


def edificio(name: str) -> Image.Image:
	im = opaco(Image.open(SRC / "edificios" / f"{name}.png").convert("RGBA"))
	s = PUERTA_GRANDE.get(name, PUERTA) * ESCALA / EDIFICIOS[name]
	return nitido(im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS))


def arbol(name: str) -> Image.Image:
	im = opaco(Image.open(SRC / "arboles" / f"{name}.png").convert("RGBA"))
	h = round(ARBOLES[name] * ESCALA)
	return nitido(im.resize((round(im.width * h / im.height), h), Image.LANCZOS))


def valla_piezas() -> tuple:
	"""(tramo que se repite, poste derecho) a la escala del juego."""
	src = Image.open(SRC / "valla.png").convert("RGBA")
	x0, y0, x1, y1 = VALLA_BOX
	s = VALLA_H / (y1 - y0)
	def esc(box):
		im = src.crop(box)
		return nitido(im.resize((max(1, round(im.width * s)), VALLA_H), Image.LANCZOS))
	return esc((VALLA_REPITE[0], y0, VALLA_REPITE[1], y1)), esc((VALLA_REPITE[1], y0, x1, y1))


def valla(w: int, rep: Image.Image, poste: Image.Image) -> Image.Image:
	out = Image.new("RGBA", (w, VALLA_H), (0, 0, 0, 0))
	x = 0
	while x < w:
		out.alpha_composite(rep.crop((0, 0, min(rep.width, w - x), VALLA_H)), (x, 0))
		x += rep.width
	out.alpha_composite(poste, (max(0, w - poste.width), 0))
	return out


def build_calle() -> None:
	street = Image.open(SRC / "tramo02.png").convert("RGBA")
	street = street.resize((round(street.width * H / street.height), H), Image.LANCZOS).crop((0, 202, 675, H - 3))  # la vereda del tramo 2 va 3 px más abajo
	rep, poste = valla_piezas()
	parts = []
	for p in CALLE:
		if isinstance(p, int):
			parts.append(("hueco", round(p * ESCALA), None, ""))
		elif isinstance(p, tuple):
			parts.append(("hueco", round(p[1] * ESCALA), arbol(p[0]), p[0]))
		else:
			im = edificio(p)
			parts.append(("edificio", im.width, im, p))
	w = sum(p[1] for p in parts)
	out = Image.new("RGBA", (w, H), (0, 0, 0, 0))
	# rectángulo de cada pieza en el mundo (para el greybox: scripts/greybox.gd)
	piezas = []
	# 1) árboles (detrás de todo), centrados en su hueco
	x = 0
	for kind, pw, im, nombre in parts:
		if kind == "hueco" and im is not None:
			ax, ay = x + pw // 2 - im.width // 2, BASE + 2 - im.height
			pegar(out, im, ax, ay)
			piezas.append(("arbol", nombre, [ax, ay, ax + im.width, ay + im.height]))
		x += pw
	# 2) la vereda y los adoquines
	for sx in range(0, w, street.width):
		out.alpha_composite(street.crop((0, 0, min(street.width, w - sx), street.height)), (sx, 205))
	# 3) la valla en los huecos y los edificios
	x = 0
	casas = []
	turno = {}
	names = [p for p in CALLE if isinstance(p, str)]
	ni = 0
	for kind, pw, im, nombre in parts:
		if kind == "hueco":
			pegar(out, valla(pw, rep, poste), x, BASE + 1 - VALLA_H)
			piezas.append(("valla", "", [x, BASE + 1 - VALLA_H, x + pw, BASE + 1]))
		else:
			pegar(out, im, x, BASE - im.height)
			piezas.append(("edificio", nombre, [x, BASE - im.height, x + im.width, BASE]))
			name = names[ni]
			ni += 1
			top = BASE - im.height
			z = ZONAS[name]
			def mundo(r):
				return [x + round(r[0] * ESCALA), top + round(r[1] * ESCALA), x + round(r[2] * ESCALA), top + round(r[3] * ESCALA)]
			vs = VECINO.get(name, [-1])
			k = vs[turno.get(name, 0) % len(vs)]
			turno[name] = turno.get(name, 0) + 1
			casas.append((name, mundo(z["puerta"]), [mundo(v) for v in z["ventanas"]], k))
		x += pw
	_write_casas(casas, piezas)
	# 4) se corta en trozos para el juego
	for old in OUT.glob("pueblo_tramo_*.png"):
		old.unlink()
	for i, sx in enumerate(range(0, w, TROZO)):
		out.crop((sx, 0, min(w, sx + TROZO), H)).save(OUT / f"pueblo_tramo_{i + 1:02d}.png")
	print("calle del pueblo:", w, "px en", (w + TROZO - 1) // TROZO, "trozos")


def _write_casas(casas, piezas) -> None:
	lines = [
		"extends RefCounted",
		"## Generado por tools/sprites/pueblo.py: no editar a mano.",
		"## Edificios de la calle del pueblo (1.1) en coordenadas del mundo:",
		"## [nombre, puerta [x0, y0, x1, y1], ventanas [[x0, y0, x1, y1], ...], vecino (fila de vecinos.png, -1 nadie)]",
		"const CASAS := [",
	]
	for name, door, wins, k in casas:
		lines.append(f'\t["{name}", {door}, {wins}, {k}],')
	lines.append("]")
	lines.append("## Piezas de la calle (para el greybox): [tipo (edificio, arbol, valla), nombre, [x0, y0, x1, y1]]")
	lines.append("const PIEZAS := [")
	for tipo, nombre, r in piezas:
		lines.append(f'\t["{tipo}", "{nombre}", {r}],')
	lines.append("]")
	(ROOT / "scripts/pueblo_casas.gd").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
	print("pueblo_casas.gd:", len(casas), "edificios")


def build_ground() -> None:
	src = load("1_almacen").crop(GROUND_BOX)
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
	build_calle()
	build_ground()
