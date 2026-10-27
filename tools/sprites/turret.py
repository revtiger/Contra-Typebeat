"""Nido de ametralladora enemigo: soldado de Argentina tras un muro de sacos terreros, con una ametralladora montada
que solo apunta a la izquierda (al frente o en diagonal hacia arriba). Dibujado por Eduardo con ChatGPT.

Entrada: tools/sprites/chatgpt/torreta/nido_soldado.png (fondo transparente, mirando a la izquierda): las dos
         poses lado a lado, a la izquierda al frente y a la derecha en diagonal.
Deterioro (PixelLab, edit_image sobre el fotograma "frente" ampliado al doble): tools/sprites/pixellab/torreta/danio/
  frente_1_2x.png  sacos dañados (agujeros de bala, arena que se sale)
  frente_2_2x.png  sacos destrozados (hecho a partir del dañado para que el soldado y el arma no se muevan)
  vacio_2x.png     el nido destrozado sin el soldado (queda en la calle cuando muere)
La pose "arriba" de cada estado sale de la de "frente": los píxeles que son iguales en las dos poses intactas
(los sacos y el cuerpo) se toman del frente dañado, y los que cambian (arma y brazos) de la pose "arriba".
Salida (assets/sprites/):
  turret_soldado.png        fila por estado (intacto, dañado, destrozado, vacío), columna por dirección (frente, arriba)
  turret_soldado_meta.json  tamaño de fotograma, pies (centro del borde de abajo de los sacos) y boca del cañón de
                            cada dirección

Uso: python tools/sprites/turret.py
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/torreta/nido_soldado.png"
OUT = ROOT / "assets/sprites"
DANIO = ROOT / "tools/sprites/pixellab/torreta/danio"
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


def alineado(im, ref, filas=slice(0, 60)):
	"""PixelLab devuelve la imagen editada corrida unos píxeles: se mueve para que la parte que no cambia (filas:
	por defecto la de arriba, el soldado y el arma) caiga donde en la imagen de partida."""
	a = np.array(im).astype(int)
	o = np.array(ref).astype(int)
	m = o[filas, :, 3] > 0
	best = None
	for dy in range(-8, 9):
		for dx in range(-14, 15):
			sh = np.roll(np.roll(a, dy, 0), dx, 1)
			e = np.abs(sh[filas, :, :3] - o[filas, :, :3])[m].mean() + 80 * ((sh[filas, :, 3] > 0) != m).mean()
			if best is None or e < best[0]:
				best = (e, dx, dy)
	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	out.alpha_composite(im, (best[1], best[2]))  # (lo que se sale por el borde se pierde)
	return out


def reducido(path, ref=None, filas=slice(0, 60)):
	"""Imagen de PixelLab al doble (alineada con ref) -> tamaño del juego (FWxFH)."""
	im = Image.open(path).convert("RGBA")
	if ref is not None:
		im = alineado(im, ref, filas)
	return nitido(im.resize((im.width // 2, im.height // 2), Image.BOX))


def deterioro(sheet, cuadros, meta):
	"""Añade las filas de los sacos dañados, destrozados y del nido vacío (si están las imágenes)."""
	fuentes = [("danado", DANIO / "frente_1_2x.png"), ("destrozado", DANIO / "frente_2_2x.png")]
	if not all(f.exists() for _, f in fuentes):
		return sheet
	frente, arriba = cuadros
	fa, aa = frente.load(), arriba.load()
	# lo que cambia entre las dos poses (arma y brazos), un píxel más ancho: eso sale de la pose "arriba"
	cambia = Image.new("L", (FW, FH), 0)
	cp = cambia.load()
	for y in range(FH):
		for x in range(FW):
			f, u = fa[x, y], aa[x, y]
			if (f[3] > 0) != (u[3] > 0) or max(abs(f[i] - u[i]) for i in range(3)) > 48:
				cp[x, y] = 255
	cambia = cambia.filter(ImageFilter.MaxFilter(3)).load()
	ref = Image.open(DANIO / "frente_0_2x.png").convert("RGBA")
	filas = []
	for name, path in fuentes:
		d = reducido(path, ref)
		up = d.copy()
		up_px = up.load()
		for y in range(FH):
			for x in range(FW):
				if cambia[x, y]:
					up_px[x, y] = aa[x, y]
		filas.append((name, [d, up]))
	vacio = DANIO / "vacio_2x.png"
	if vacio.exists():
		# el nido vacío sale del destrozado: se alinea por los sacos (la mitad de abajo)
		ref2 = alineado(Image.open(fuentes[1][1]).convert("RGBA"), ref)
		filas.append(("vacio", [reducido(vacio, ref2, slice(90, 144))]))
	out = Image.new("RGBA", (sheet.width, FH * (1 + len(filas))), (0, 0, 0, 0))
	out.alpha_composite(sheet)
	for r, (name, frs) in enumerate(filas, start=1):
		meta["rows"][name] = r
		for c, f in enumerate(frs):
			out.alpha_composite(f, (c * FW, r * FH))
	return out


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
		"muzzles": [boca(cuadros[0], False), boca(cuadros[1], True)], "rows": {"intacto": 0}}
	sheet = deterioro(sheet, cuadros, meta)
	sheet.save(OUT / "turret_soldado.png")
	(OUT / "turret_soldado_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("turret_soldado.png", sheet.size, [p.size for p in frs], meta)


if __name__ == "__main__":
	main()
