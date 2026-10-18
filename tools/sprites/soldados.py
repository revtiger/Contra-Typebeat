"""Soldado enemigo de Argentina (proporciones de Metal Slug, como los héroes), dibujado por Eduardo con ChatGPT.

Fuente: tools/sprites/chatgpt/soldados/poses_1..3.png (el mismo soldado joven, mirando a la izquierda, fondo
transparente; caras.png / caras_v2.png son las 5 caras de referencia):
  poses_1: correr, apuntar al frente, en diagonal hacia arriba, hacia arriba
  poses_2: en guardia (fusil en diagonal hacia abajo), preparar granada, lanzar granada, asustado
  poses_3: recibe el disparo, cae de espaldas, muerto en el suelo
Ciclo de correr: PixelLab (animate_image) a partir de la pose de correr: tools/sprites/pixellab/soldados/
run_base.png -> run.png (tira de 9 fotogramas de BASE x BASE; el 0 es la base).

Salida: assets/sprites/soldier_ar.png + soldier_ar_meta.json (filas como soldier_meta.json, más "die",
y la boca del fusil de cada pose de apuntar). Mirando a la derecha, como el resto de sprites.

Uso: python tools/sprites/soldados.py base | juego
"""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from heroes_sheets import blobs  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/soldados"
PL = ROOT / "tools/sprites/pixellab/soldados"
OUT = ROOT / "assets/sprites"

FW, FH = 80, 64
FEET = (40, 62)
ESCALA = 48 / 510      # la pose de apuntar al frente mide 48 px, como Eduardo
BASE = 128             # lienzo para PixelLab (el doble de la escala del juego)


def poses(n):
	im = Image.open(SRC / f"poses_{n}.png").convert("RGBA")
	mask = im.getchannel("A").point(lambda v: 255 if v > 100 else 0)
	bs = sorted([b for b in blobs(mask) if b[4] > 2000], key=lambda b: b[0])  # fuera la granada en el aire
	out = []
	for b in bs:
		f = im.crop(b[:4])
		# solo la figura: lo que asoma de la pose vecina en el recorte se borra (relleno desde un píxel suyo)
		m = f.getchannel("A").point(lambda v: 255 if v > 100 else 0)
		seed = next((x, y) for y in range(m.height - 1, 0, -1) for x in range(m.width // 3, m.width) if m.getpixel((x, y)))
		ImageDraw.floodfill(m, seed, 128)
		f.putalpha(Image.eval(m, lambda v: 255 if v == 128 else 0))
		out.append(f.crop(f.getchannel("A").getbbox()))
	return out


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def escala(f, s=ESCALA):
	return nitido(f.resize((max(1, round(f.width * s)), max(1, round(f.height * s))), Image.LANCZOS))


def pies_x(f, tumbado=False):
	"""x del centro de los pies (de las botas, abajo del todo), para alinear las poses."""
	if tumbado:
		return f.width / 2
	a = f.getchannel("A")
	h = f.height
	band = a.crop((0, int(h * 0.82), f.width, h)).getbbox()
	return (band[0] + band[2]) / 2 if band else f.width / 2


def celda(f, tumbado=False):
	"""Pose escalada (mirando a la izquierda) -> celda FWxFH mirando a la derecha con los pies en FEET."""
	f = f.transpose(Image.FLIP_LEFT_RIGHT)
	c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
	x = round(FEET[0] - pies_x(f, tumbado))
	c.alpha_composite(f, (x, FEET[1] + 1 - f.height))
	return c


def boca(c, d):
	"""Punta del fusil en la celda: el píxel opaco más lejos en la dirección d (mirando a la derecha),
	por encima de las botas."""
	px = c.getchannel("A").load()
	best, bp = None, None
	for y in range(FEET[1] - 10):
		for x in range(FW):
			if px[x, y] > 128:
				v = x * d[0] + y * d[1]
				if best is None or v > best:
					best, bp = v, (x, y)
	return [bp[0] - FEET[0], bp[1] - FEET[1]]


def base():
	PL.mkdir(parents=True, exist_ok=True)
	run = poses(1)[0]
	s = ESCALA * BASE / FH
	f = escala(run, s)
	c = Image.new("RGBA", (BASE, BASE), (0, 0, 0, 0))
	c.alpha_composite(f, ((BASE - f.width) // 2, BASE - 4 - f.height))
	c.save(PL / "run_base.png")
	print("run_base.png", f.size)


def juego():
	p1, p2, p3 = poses(1), poses(2), poses(3)
	cell = lambda f, t=False: celda(escala(f), t)
	guardia = cell(p2[0])
	aims = [cell(p1[1]), cell(p1[2]), cell(p1[3]), guardia]
	# correr: fotogramas de PixelLab (si aún no están, la pose de correr sola)
	run_strip = PL / "run.png"
	if run_strip.exists():
		strip = Image.open(run_strip).convert("RGBA")
		# el cuerpo queda en su sitio en todos los fotogramas: se escalan enteros (128 -> 64) y la línea de los
		# pies (BASE-4) cae justo en FEET; así el ciclo no tiembla
		run = []
		for i in range(1, strip.width // BASE):
			fr = nitido(strip.crop((i * BASE, 0, (i + 1) * BASE, BASE)).resize((FH, FH), Image.LANCZOS))
			c = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
			c.alpha_composite(fr.transpose(Image.FLIP_LEFT_RIGHT), ((FW - FH) // 2, 0))
			run.append(c)
	else:
		run = [cell(p1[0])]
	run = (run * 8)[:8]
	panic = cell(p2[3])
	panic2 = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
	panic2.alpha_composite(panic.crop((0, 0, FW, FH - 1)), (0, 1))  # tiembla 1 px
	rows = {
		"idle": [guardia],
		"run": run,
		"panic": [panic, panic2],
		"throw": [cell(p2[1]), cell(p2[2])],
		"aim": aims,
		"flee": run,
		"die": [cell(p3[0]), cell(p3[1], True), cell(p3[2], True)],
	}
	sheet = Image.new("RGBA", (FW * 8, FH * len(rows)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "feet": list(FEET), "rows": {}, "aim_degrees": [0, -45, -90, 45]}
	for r, (name, frames) in enumerate(rows.items()):
		meta["rows"][name] = r
		for i, fr in enumerate(frames):
			sheet.alpha_composite(fr, (i * FW, r * FH))
	meta["muzzles"] = [boca(aims[0], (1, 0)), boca(aims[1], (1, -1)), boca(aims[2], (0, -1)), boca(aims[3], (1, 1))]
	meta["hand"] = [20, -30]  # de dónde sale la granada (mano adelantada al lanzar)
	sheet.save(OUT / "soldier_ar.png")
	(OUT / "soldier_ar_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("soldier_ar.png", sheet.size, "bocas", meta["muzzles"])


if __name__ == "__main__":
	{"base": base, "juego": juego}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
