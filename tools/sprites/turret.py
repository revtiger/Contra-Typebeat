"""Nido de ametralladora enemigo: soldado de Argentina tras un muro de sacos terreros, con una ametralladora montada
que solo apunta a la izquierda (al frente o en diagonal hacia arriba). Dibujado por Eduardo con ChatGPT.

Entrada: tools/sprites/chatgpt/torreta/nido_soldado.png (fondo transparente, mirando a la izquierda): las dos
         poses lado a lado, a la izquierda al frente y a la derecha en diagonal.
Salida (assets/sprites/):
  turret_soldado.png        un fotograma por dirección (frente, arriba)
  turret_soldado_meta.json  tamaño de fotograma, pies (centro del borde de abajo de los sacos) y boca del cañón de
                            cada dirección

Uso: python tools/sprites/turret.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/torreta/nido_soldado.png"
OUT = ROOT / "assets/sprites"
# la cara del soldado sale del mismo tamaño que la de soldier_ar.png (tools/sprites/soldados.py)
ESCALA = 0.1
FW, FH = 96, 72


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def poses():
	"""Las dos poses recortadas, cada una alineada por la base de los sacos (fila más baja)."""
	im = Image.open(SRC).convert("RGBA")
	a = im.getchannel("A").point(lambda v: 255 if v > 100 else 0)
	# corte entre las dos poses: la columna vacía más cercana al centro
	cols = [a.crop((x, 0, x + 1, im.height)).getbbox() is None for x in range(im.width)]
	mid = min((x for x in range(im.width) if cols[x]), key=lambda x: abs(x - im.width // 2))
	out = []
	for box in ((0, 0, mid, im.height), (mid, 0, im.width, im.height)):
		p = im.crop(box)
		out.append(p.crop(p.getchannel("A").point(lambda v: 255 if v > 100 else 0).getbbox()))
	return out


def base_sacos(im):
	"""(x centro, y) de la base de los sacos: la fila opaca más baja y el tramo de sacos de esa zona."""
	a = im.getchannel("A")
	bottom = a.getbbox()[3] - 1
	row = a.crop((0, bottom - 3, im.width, bottom + 1)).getbbox()
	return (row[0] + row[2]) / 2, bottom


def boca(im, diagonal):
	"""Punta del cañón: el píxel opaco más a la izquierda (al frente) o más arriba a la izquierda (diagonal)."""
	a = im.getchannel("A").load()
	pts = [(x, y) for y in range(im.height) for x in range(im.width) if a[x, y]]
	return list(min(pts, key=(lambda p: p[0] + p[1]) if diagonal else (lambda p: (p[0], p[1]))))


def main():
	frs = []
	for p in poses():
		p = nitido(p.resize((round(p.width * ESCALA), round(p.height * ESCALA)), Image.LANCZOS))
		frs.append(p)
	# todas con la base de los sacos en el mismo punto del fotograma
	feet = (FW // 2, FH - 3)
	sheet = Image.new("RGBA", (FW * len(frs), FH), (0, 0, 0, 0))
	cuadros = []
	for i, p in enumerate(frs):
		cx, by = base_sacos(p)
		f = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		f.alpha_composite(p, (round(feet[0] - cx), feet[1] - by))
		cuadros.append(f)
		sheet.alpha_composite(f, (i * FW, 0))
	# los sacos de abajo se hunden 2 px en el suelo (si no, el nido parece flotar)
	meta = {"frame": [FW, FH], "feet": [feet[0], feet[1] - 2], "dirs": ["frente", "arriba"],
		"muzzles": [boca(cuadros[0], False), boca(cuadros[1], True)]}
	sheet.save(OUT / "turret_soldado.png")
	(OUT / "turret_soldado_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("turret_soldado.png", sheet.size, [p.size for p in frs], meta)


if __name__ == "__main__":
	main()
