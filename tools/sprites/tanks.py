"""Tanques enemigos (rediseño de Eduardo, 26-10-2026): comunista (estilo T-34), israelí (estilo Merkava) y
estadounidense (estilo Abrams), dibujados por ChatGPT y con las orugas animadas con PixelLab. Del alto de Massa
(ALTO px, sin contar antenas).

Entrada: tools/sprites/chatgpt/objetos/tanques.png (fondo magenta liso): arriba los tres tanques mirando a la
         izquierda; abajo cada uno destruido (chamuscado, cañón doblado, fuego y humo).
Animación (PixelLab, animate_image): tools/sprites/pixellab/tanques/<tipo>_N.png (0 = la pieza, 1.. = generados).
Salida:  assets/sprites/tank_<tipo>.png (fotogramas en una fila) y tank_<tipo>_roto.png (la chatarra)
         assets/sprites/tanks_meta.json: por tipo, tamaño de fotograma, número de fotogramas, base (fila de las
         orugas que apoya en el suelo), centro del casco y boca del cañón (relativos a la base), tamaño del casco y,
         de la chatarra, su tamaño, base y centro

Uso:
  python tools/sprites/tanks.py base    # recorta las piezas y deja las entradas para PixelLab
  python tools/sprites/tanks.py juego   # arma los sprites del juego con lo que devolvió PixelLab
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from helicoptero import manchas  # noqa: E402
from objetos import nitido, sin_magenta  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/objetos/tanques.png"
PL = ROOT / "tools/sprites/pixellab/tanques"
OUT = ROOT / "assets/sprites"
TYPES = ["comunista", "israeli", "usa"]
ALTO = 60          # alto del tanque comunista en el juego (los otros a la misma escala)
PL_ANCHO = 246     # ancho del más ancho en la entrada de PixelLab (con el margen, máximo 256)
MARGEN = 4


def tramos(mask, axis, minimo):
	"""Tramos de filas (axis=1) o columnas (axis=0) con algo opaco, separados por huecos."""
	v = mask.any(axis=axis)
	out = []
	i = 0
	while i < len(v):
		if v[i]:
			j = i
			while j < len(v) and v[j]:
				j += 1
			if j - i >= minimo:
				out.append((i, j))
			i = j
		else:
			i += 1
	return out


def piezas():
	"""{tipo: (tanque, chatarra)} recortados."""
	im = sin_magenta(Image.open(SRC))
	a = np.array(im.getchannel("A")) > 0
	filas = tramos(a, 1, 40)
	assert len(filas) == 2, filas
	out = {}
	k = 4
	for y0, y1 in filas:
		# en cada fila, tres manchas grandes (los cañones se cruzan por columnas, no por píxeles); cada pieza suelta
		# (humo, escombros) va con la mancha grande más cercana
		fila = im.crop((0, y0, im.width, y1))
		chica = np.array(fila.getchannel("A").resize((fila.width // k, fila.height // k), Image.BOX)) > 100
		lab, n = manchas(chica)
		tam = [(lab == i).sum() for i in range(1, n + 1)]
		grandes = sorted(range(1, n + 1), key=lambda i: -tam[i - 1])[:3]
		grandes.sort(key=lambda i: np.argwhere(lab == i)[:, 1].mean())
		centros = [np.argwhere(lab == i)[:, 1].mean() for i in grandes]
		dueno = np.zeros(n + 1, int)
		for i in range(1, n + 1):
			dueno[i] = int(np.argmin([abs(np.argwhere(lab == i)[:, 1].mean() - c) for c in centros]))
		cerca = np.argmin(np.abs(np.arange(lab.shape[1])[:, None] - np.array(centros)[None, :]), axis=1)
		quien = np.where(lab > 0, dueno[lab], cerca[None, :])
		quien = np.kron(quien, np.ones((k, k), int))
		quien = np.pad(quien, ((0, fila.height - quien.shape[0]), (0, fila.width - quien.shape[1])), mode="edge")
		px = np.array(fila)
		for j, t in enumerate(TYPES):
			q = px.copy()
			q[quien != j] = 0
			p = Image.fromarray(q, "RGBA")
			out.setdefault(t, []).append(p.crop(p.getchannel("A").getbbox()))
	return out


def sin_violeta(im, humo=False):
	"""PixelLab a veces devuelve píxeles violetas del magenta del fondo original: pasan a transparentes. Con humo,
	también el humo gris que quedó violáceo al mezclarse con el magenta (los tanques y el fuego no tiran a violeta)."""
	a = np.array(im).astype(int)
	violeta = (a[..., 0] - a[..., 1] > 35) & (a[..., 2] - a[..., 1] > 35)
	if humo:
		violeta |= (a[..., 2] - a[..., 1] > 8) & (a[..., 0] - a[..., 1] > 4)
	a[violeta, 3] = 0
	return Image.fromarray(a.astype(np.uint8), "RGBA")


def escala_juego(ps):
	return ALTO / ps["comunista"][0].height


def base():
	ps = piezas()
	s = PL_ANCHO / max(p[0].width for p in ps.values())
	PL.mkdir(parents=True, exist_ok=True)
	for old in PL.glob("*.png"):
		old.unlink()
	for t, (tanque, _) in ps.items():
		im = nitido(tanque.resize((round(tanque.width * s), round(tanque.height * s)), Image.LANCZOS))
		lienzo = Image.new("RGBA", (im.width + 2 * MARGEN, im.height + 2 * MARGEN), (0, 0, 0, 0))
		lienzo.alpha_composite(im, (MARGEN, MARGEN))
		lienzo.save(PL / f"{t}_0.png")
		print(t, tanque.size, "->", lienzo.size)


def medidas(m):
	"""base, centro del casco, tamaño del casco y boca del cañón de un fotograma (máscara opaca)."""
	a = np.array(m) > 0
	ys, xs = np.nonzero(a)
	top, bot = ys.min(), ys.max() + 1
	# casco: el ancho de la mitad de abajo (orugas), sin el cañón
	abajo = np.nonzero(a[(top + bot) // 2:bot].any(axis=0))[0]
	cx = (abajo[0] + abajo[-1]) // 2
	# boca del cañón: el píxel opaco más a la izquierda en la mitad de arriba
	arriba = a[top:(top + bot) // 2]
	cy, cxm = min(((y, x) for y, x in np.argwhere(arriba)), key=lambda p: p[1])
	return bot, int(cx), [int(abajo[-1] - abajo[0]), int(bot - top)], [int(cxm - cx), int(cy + top - bot)]


def juego():
	ps = piezas()
	g = escala_juego(ps)
	meta = {}
	for t in TYPES:
		frs = sorted(PL.glob(f"{t}_*.png"), key=lambda p: int(p.stem.split("_")[1]))
		frs = [sin_violeta(Image.open(f).convert("RGBA")) for f in frs]
		if len(frs) > 1:
			frs = frs[1:]  # el 0 es la entrada; los generados ya forman el ciclo
		k = g * ps[t][0].width / (frs[0].width - 2 * MARGEN)
		frs = [nitido(f.resize((round(f.width * k), round(f.height * k)), Image.BOX)) for f in frs]
		w, h = frs[0].size
		strip = Image.new("RGBA", (w * len(frs), h), (0, 0, 0, 0))
		for i, f in enumerate(frs):
			strip.alpha_composite(f, (i * w, 0))
		strip.save(OUT / f"tank_{t}.png")
		bot, cx, hull, muzzle = medidas(frs[0].getchannel("A"))
		# la chatarra sin el humo de arriba (mezclado con el magenta, sale rosa; el humo lo hace el juego)
		r = ps[t][1]
		r = r.crop((0, max(0, r.height - round(ps[t][0].height * 1.08)), r.width, r.height))
		r = sin_violeta(r, humo=True)
		r = r.crop(r.getchannel("A").getbbox())
		roto = nitido(r.resize((round(r.width * g), round(r.height * g)), Image.LANCZOS))
		roto.save(OUT / f"tank_{t}_roto.png")
		rb, rcx, _, _ = medidas(roto.getchannel("A"))
		meta[t] = {
			"frame": [w, h], "frames": len(frs), "base": int(bot), "center_x": cx, "hull": hull, "muzzle": muzzle,
			"roto": {"size": list(roto.size), "base": int(rb), "center_x": rcx},
		}
		print("ok tank", t, meta[t])
	(OUT / "tanks_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")


if __name__ == "__main__":
	{"base": base, "juego": juego}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
