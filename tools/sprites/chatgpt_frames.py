"""Corta una hoja de animación hecha con ChatGPT en fotogramas sueltos, ya a la escala del juego.

Entrada: tools/sprites/chatgpt/<heroe>_<anim>.png (poses en una cuadrícula, fondo transparente).
Salida:  tools/sprites/heroes/<heroe>/<anim>/<anim>_01.png ... (fotogramas FWxFH de heroes_sheets.py)
         tools/sprites/heroes/<heroe>/<anim>/preview.png (tira ampliada x4 para revisarlos)

Los fotogramas sueltos se pueden retocar a mano (Aseprite) uno a uno; heroes_sheets.py los usa en lugar
de las poses de sprites_<heroe>_1/2.png y monta con ellos la hoja del juego.

- Escala: la misma altura media que tenía la animación vieja en el juego, para no cambiar de tamaño.
- Alto: cada fila de la hoja tiene su línea de suelo (la bota más baja); se conserva lo que sube o baja
  cada pose respecto a ella, que es el rebote del cuerpo. Si la animación está en LIFT, ChatGPT no decide
  la altura: las poses con un pie apoyado pegan la bota más baja al suelo y en las poses en el aire el torso
  (el cañón del arma, lo que sigue el ojo) sube los píxeles indicados sobre el primer fotograma; así el salto
  sigue un arco suave y no "parpadea".
- Ancho: se alinea por la boca del arma, que va fija al cuerpo; así el torso no tiembla de lado
  mientras las piernas se mueven, y las balas salen del cañón.

Uso: python tools/sprites/chatgpt_frames.py eduardo run [columnas filas]
"""
import os
import statistics
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from heroes_sheets import ANIMS, FEET, FH, FW, HEIGHT, SRC, alpha_mask, blobs, cells  # noqa: E402

HERE = os.path.dirname(__file__)

# torso fijo: {(heroe, anim): (fotograma del que sale la parte de arriba, píxeles del corte bajo el cañón)}
# (correr de Eduardo lo usó hasta la v11; desde la v12 el arma y el pelo se mueven y el torso va animado)
TORSO = {}

# parte de arriba prestada: {(heroe, anim): (corte en píxeles bajo lo alto de la cabeza, {fotograma: fotograma
# del que se toma la parte de arriba})}. Las piernas siguen siendo las de cada fotograma; el arma se copia entera
# (también lo que baja del corte). Sirve para suavizar un gesto exagerado sin redibujar (v16: el arma ya no
# apunta hacia atrás en 5 y 6; hace un arco frente -> diagonal -> vertical -> diagonal -> frente).
UPPER = {
	# v16 (desde eduardo_run_v15.png); desde la v18 el arco del arma ya viene dibujado y no hace falta:
	# ("eduardo", "run"): (26, {1: 1, 2: 2, 3: 7, 4: 4, 5: 3, 6: 8, 7: 4, 8: 7, 9: 9, 10: 10}),
}

# retoques a mano tras montar los fotogramas: {(heroe, anim): {fotograma: [(x0, y0, x1, y1), ...]}} zonas que se
# borran (x1 e y1 excluidos). Para restos que los filtros no detectan.
ERASE = {
	# v16: punta del arma vieja (apuntaba hacia atrás) pegada a la bota trasera; la v18 ya no la tiene:
	# ("eduardo", "run"): {5: [(6, 39, 13, 44), (14, 40, 16, 41)]},
}

# poses alineadas por la cabeza en lugar de por la boca del arma: para animaciones en las que el arma
# se balancea (alinear por el arma anularía el balanceo)
ALIGN_HEAD = {("eduardo", "run")}

# poses en el aire: {(heroe, anim): {número de fotograma (desde 1): píxeles que sube el torso sobre el fotograma 1}}
# las que no aparecen tienen un pie en el suelo (el fotograma 1 tiene que ser una de ellas)
LIFT = {
	# (correr de Eduardo, v13: sin entrada; usa las alturas que dibujó ChatGPT, como la v3)
}


def poses(path, cols, rows):
	"""Recorta las poses de la hoja en orden de lectura: lista de (imagen, fila, caja).
	Las cajas de poses vecinas pueden solaparse, así que cada pose se separa con un relleno (bote de pintura)
	desde su centro: solo se queda con los píxeles unidos a ella, nunca con trozos de la vecina."""
	im = Image.open(path).convert("RGBA")
	big = sorted([b for b in blobs(alpha_mask(im)) if b[4] > 400], key=lambda b: -b[4])[:cols * rows]
	if len(big) != cols * rows:
		raise SystemExit("%s: se esperaban %d poses y hay %d" % (path, cols * rows, len(big)))
	labels = alpha_mask(im)
	for n, p in enumerate(big):
		seed = _seed(labels, p)
		if seed is None or labels.getpixel(seed) != 255:
			raise SystemExit("%s: no se pudo separar la pose de la caja %s" % (path, p[:4]))
		ImageDraw.floodfill(labels, seed, n + 1)
	out = []
	for n, p in enumerate(big):
		box = (max(p[0] - 2, 0), max(p[1] - 2, 0), p[2] + 2, p[3] + 2)
		own = labels.crop(box)
		# lo suyo y los restos sueltos (mechones, chispas) de dentro de su caja
		keep = own.point(lambda v, k=n + 1: 255 if v in (k, 255) else 0)
		cell = Image.new("RGBA", own.size, (0, 0, 0, 0))
		cell.paste(im.crop(box), (0, 0), keep)
		r = min(rows - 1, int((p[1] + p[3]) / 2 / (im.height / rows)))
		c = min(cols - 1, int((p[0] + p[2]) / 2 / (im.width / cols)))
		out.append((r, c, cell, p))
	out.sort(key=lambda t: (t[0], t[1]))
	return [(img, r, p) for r, _, img, p in out]


def _seed(mask, p):
	"""Un píxel opaco de la pose: el más cercano al centro de su caja, buscando en la columna central."""
	cx, cy = (p[0] + p[2]) // 2, (p[1] + p[3]) // 2
	for d in range(0, (p[3] - p[1]) // 2):
		for y in (cy - d, cy + d):
			for x in (cx, cx - 6, cx + 6):
				if mask.getpixel((x, y)) == 255:
					return (x, y)
	return None


def palette(imgs, colors=48):
	"""Paleta común a todas las poses: si cada pose tuviera la suya, los tonos variarían y la animación parpadearía."""
	w = sum(i.width for i in imgs)
	h = max(i.height for i in imgs)
	all_rgb = Image.new("RGB", (w, h), (0, 0, 0))
	x = 0
	for img in imgs:
		all_rgb.paste(img.convert("RGB"), (x, 0), alpha_mask(img))
		x += img.width
	return all_rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)


def shrink(img, scale, pal):
	"""Reduce la pose sin inventar colores: promedia por bloques y luego cada píxel toma el color más
	parecido de la paleta común (fuera los tonos intermedios "sucios" de los bordes)."""
	w, h = img.size
	size = (max(1, round(w * scale)), max(1, round(h * scale)))
	mask = alpha_mask(img)
	rgb = Image.new("RGB", img.size, (0, 0, 0))
	rgb.paste(img.convert("RGB"), (0, 0), mask)
	small_rgb = rgb.resize(size, Image.BOX).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
	small_a = mask.resize(size, Image.BOX).point(lambda v: 255 if v >= 128 else 0)
	out = small_rgb.convert("RGBA")
	out.putalpha(small_a)
	return out


def drop_specks(img, min_px=6):
	"""Borra las manchas sueltas de menos de `min_px` píxeles (restos del fondo o de la pose vecina)."""
	px = img.load()
	w, h = img.size
	seen = set()
	for y in range(h):
		for x in range(w):
			if (x, y) in seen or px[x, y][3] == 0:
				continue
			stack, comp = [(x, y)], []
			seen.add((x, y))
			while stack:
				cx, cy = stack.pop()
				comp.append((cx, cy))
				for nx in (cx - 1, cx, cx + 1):
					for ny in (cy - 1, cy, cy + 1):
						if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3]:
							seen.add((nx, ny))
							stack.append((nx, ny))
			if len(comp) < min_px:
				for p in comp:
					px[p] = (0, 0, 0, 0)
	return img


def head_x(img):
	"""Centro horizontal de la cabeza (franja entre el 4 % y el 16 % del alto de la pose)."""
	m = alpha_mask(img)
	b = m.getbbox()
	h = b[3] - b[1]
	head = m.crop((0, b[1] + int(h * 0.04), img.width, b[1] + int(h * 0.16))).getbbox()
	return (head[0] + head[2]) / 2.0


def muzzle_x(img):
	"""Columna más a la derecha de la franja del arma (entre el 20 % y el 55 % del alto de la pose)."""
	m = alpha_mask(img)
	b = m.getbbox()
	h = b[3] - b[1]
	band = m.crop((0, b[1] + int(h * 0.2), img.width, b[1] + int(h * 0.55)))
	return band.getbbox()[2]


def _is_gray(p):
	r, g, b, a = p
	return a and max(r, g, b) - min(r, g, b) < 12 and 40 <= max(r, g, b) <= 150


def rifle_pixels(img):
	"""Píxeles del arma: manchas grises grandes y conectadas (no sombras sueltas) y su contorno oscuro."""
	w, h = img.size
	px = img.load()
	gray = {(x, y) for y in range(h) for x in range(w) if _is_gray(px[x, y])}
	seen, keep = set(), set()
	for start in gray:
		if start in seen:
			continue
		stack, comp = [start], []
		seen.add(start)
		while stack:
			x, y = stack.pop()
			comp.append((x, y))
			for nx in (x - 1, x, x + 1):
				for ny in (y - 1, y, y + 1):
					if (nx, ny) in gray and (nx, ny) not in seen:
						seen.add((nx, ny))
						stack.append((nx, ny))
		if len(comp) >= 10:
			keep.update(comp)
	out = set(keep)
	for x, y in keep:
		for nx in (x - 1, x, x + 1):
			for ny in (y - 1, y, y + 1):
				if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and max(px[nx, ny][:3]) < 40:
					out.add((nx, ny))
	return out


def borrow_upper(frames, cut, mapping):
	"""Cada fotograma conserva sus piernas (bajo el corte, sin su arma) y toma la parte de arriba y el arma
	del fotograma indicado, alineada por lo alto de la cabeza."""
	out = []
	for i, base in enumerate(frames):
		src = frames[mapping.get(i + 1, i + 1) - 1]
		top = base.getchannel("A").getbbox()[1]
		y_cut = top + cut
		moved = Image.new("RGBA", base.size, (0, 0, 0, 0))
		moved.paste(src, (0, top - src.getchannel("A").getbbox()[1]), src)
		f = Image.new("RGBA", base.size, (0, 0, 0, 0))
		fp, bp, sp = f.load(), base.load(), moved.load()
		base_gun, src_gun = rifle_pixels(base), rifle_pixels(moved)
		for y in range(y_cut, FH):
			for x in range(FW):
				if bp[x, y][3] and (x, y) not in base_gun:
					fp[x, y] = bp[x, y]
		for y in range(FH):
			for x in range(FW):
				if sp[x, y][3] and (y < y_cut or (x, y) in src_gun):
					fp[x, y] = sp[x, y]
		out.append(drop_specks(f, 30))  # restos del arma vieja que quedan sueltos bajo el corte
	return out


def fixed_torso(frames, gun_x, src, cut):
	"""Torso fijo, como en Metal Slug: la parte de arriba (cabeza, mochila, brazos y arma) es la del fotograma
	`src` en todos los fotogramas, movida a la altura de cada uno; de cada fotograma solo se usan las piernas.
	El corte va `cut` píxeles por debajo de lo alto del cañón."""
	top = frames[src - 1]
	t_src = barrel_top(top, gun_x)
	upper = top.crop((0, 0, FW, t_src + cut))
	out = []
	for fr in frames:
		t = barrel_top(fr, gun_x)
		f = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		legs = fr.crop((0, t + cut, FW, FH))
		f.paste(legs, (0, t + cut), legs)
		f.alpha_composite(upper, (0, t - t_src))
		out.append(f)
	return out


def barrel_top(img, muzzle):
	"""Fila más alta del cañón (unos píxeles por detrás de la boca del arma)."""
	col = img.getchannel("A").crop((muzzle - 3, 0, muzzle - 2, img.height))
	return col.getbbox()[1]


def old_height(hero, anim):
	"""Altura media en el juego de la animación vieja (poses de sprites_<heroe>_1/2.png)."""
	sheets = {1: cells(os.path.join(SRC, "sprites_%s_1.png" % hero)),
		2: cells(os.path.join(SRC, "sprites_%s_2.png" % hero))}
	ib = alpha_mask(sheets[1][0][0]).getbbox()
	scale = HEIGHT / float(ib[3] - ib[1])
	hs = []
	for s, r, c in ANIMS[anim][0]:
		b = alpha_mask(sheets[s][r][c]).getbbox()
		hs.append((b[3] - b[1]) * scale)
	return statistics.median(hs)


def main(hero, anim, cols=4, rows=2):
	src = os.path.join(SRC, "%s_%s.png" % (hero, anim))
	ps = poses(src, cols, rows)
	scale = old_height(hero, anim) / statistics.median(p[3] - p[1] for _, _, p in ps)
	# línea de suelo de cada fila: la bota más baja
	ground = {}
	for _, r, p in ps:
		ground[r] = max(ground.get(r, 0), p[3])
	# boca del arma a la misma distancia de los pies que en el fotograma quieto (meta "muzzle")
	gun_x = FEET[0] + 29
	out_dir = os.path.join(HERE, "heroes", hero, anim)
	os.makedirs(out_dir, exist_ok=True)
	for f in os.listdir(out_dir):
		if f.endswith(".png"):
			os.remove(os.path.join(out_dir, f))
	lift = LIFT.get((hero, anim))
	pal = palette([img for img, _, _ in ps])
	frames = []
	for i, (img, r, p) in enumerate(ps):
		w, h = img.size
		small = drop_specks(shrink(img, scale, pal))
		mx = muzzle_x(small)
		ox = gun_x - mx
		oy = round(FEET[1] - (ground[r] - (p[1] - 2)) * scale)
		if lift is not None:
			if i + 1 in lift:
				oy = torso_y - lift[i + 1] - barrel_top(small, mx)
			else:
				oy = FEET[1] - small.getchannel("A").getbbox()[3]
				if i == 0:
					torso_y = oy + barrel_top(small, mx)
		if (hero, anim) in ALIGN_HEAD:
			if i == 0:
				head_ref = ox + head_x(small)
			ox = round(head_ref - head_x(small))
		frame = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
		frame.paste(small, (ox, oy), small)
		frames.append(frame)
	if (hero, anim) in TORSO:
		frames = fixed_torso(frames, gun_x, *TORSO[(hero, anim)])
	if (hero, anim) in UPPER:
		frames = borrow_upper(frames, *UPPER[(hero, anim)])
	for n, boxes in ERASE.get((hero, anim), {}).items():
		for box in boxes:
			frames[n - 1].paste((0, 0, 0, 0), box)
	for i, frame in enumerate(frames):
		frame.save(os.path.join(out_dir, "%s_%02d.png" % (anim, i + 1)))
	strip = Image.new("RGBA", (FW * len(frames), FH), (40, 40, 48, 255))
	for i, fr in enumerate(frames):
		strip.alpha_composite(fr, (i * FW, 0))
	strip.resize((strip.width * 4, strip.height * 4), Image.NEAREST).save(os.path.join(out_dir, "preview.png"))
	print("ok", hero, anim, "%d fotogramas" % len(frames), "escala %.4f" % scale, "->", out_dir)


if __name__ == "__main__":
	if len(sys.argv) < 3:
		raise SystemExit(__doc__)
	main(sys.argv[1], sys.argv[2], *[int(a) for a in sys.argv[3:5]])
