"""Animaciones de Junnie hechas con PixelLab a partir de sus poses de ChatGPT (sprites_junnie_N.png).

Las hojas de ChatGPT traen 4 poses por movimiento; para que corra tan fluido como Eduardo (10 fotogramas) y
para que el pelo se mueva, estas animaciones se generan con PixelLab (animate_image):
  run          corre (de la pose de correr, hoja 1 fila 1)
  up_run       corre apuntando arriba (hoja 3 fila 1)
  diag_up_run  corre apuntando en diagonal arriba (hoja 4 fila 1)
  idle         quieta, con el pelo meciéndose (de la pose quieta, hoja 1 fila 0)

Paso 1 (base): cada pose se coloca en su fotograma del juego (FWxFH, pies en FEET, paleta de Junnie, como en
heroes_sheets.py) y se amplía al doble sin suavizar: tools/sprites/pixellab/junnie/<anim>_base.png. Esa base
se anima con PixelLab y la tira (fotograma 0 = base) se guarda como <anim>.png.
Paso 2 (juego): cada tira se reduce a la mitad, se pasa a la paleta de Junnie con contorno (to_palette) y se guarda como
fotogramas sueltos en tools/sprites/heroes/junnie/<anim>/<anim>_NN.png, que heroes_sheets.py usa en lugar de
las poses de las hojas.

Uso: python tools/sprites/junnie_pixellab.py base | juego   (y después python tools/sprites/heroes_sheets.py)
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import heroes_sheets as H  # noqa: E402

HERO = "junnie"
PL = os.path.join(os.path.dirname(__file__), "pixellab", HERO)
OUT = os.path.join(H.FRAMES, HERO)
# animación: (hoja, fila, columna) de la pose de partida, y fotogramas de la tira que se usan
POSES = {
	"run": ((1, 1, 0), None),
	"up_run": ((3, 1, 3), None),
	"diag_up_run": ((4, 1, 3), None),
	"idle": ((1, 0, 0), None),
}


def palette():
	"""Paleta de Junnie: la de su hoja ya montada (player_junnie_body.png)."""
	sheet = Image.open(os.path.join(H.OUT, "player_%s_body.png" % HERO)).convert("RGBA")
	opaque = [p[:3] for p in sheet.get_flattened_data() if p[3]]
	sample = Image.new("RGB", (len(opaque), 1))
	sample.putdata(opaque)
	return sample.quantize(colors=H.PALETTE, method=Image.Quantize.MEDIANCUT, kmeans=3)


def place(cell, scale, anim):
	"""Pose de la hoja -> fotograma FWxFH como lo coloca heroes_sheets.py."""
	cell, _, _, _ = H.strip_flash(cell)
	b = H.alpha_mask(cell).getbbox()
	small = H.clean(cell.resize((max(1, round(cell.width * scale)), max(1, round(cell.height * scale))), Image.LANCZOS))
	small = H.keep_largest(small)
	if anim in H.TORSO_ALIGN:
		ox = round(H.FEET[0] - H.torso_x(cell) * scale)
	else:
		ox = round(H.FEET[0] - H.feet_x(cell) * scale)
	oy = round(H.FEET[1] - b[3] * scale) - 1
	frame = Image.new("RGBA", (H.FW, H.FH), (0, 0, 0, 0))
	frame.paste(small, (ox, oy), small)
	return frame


def base():
	os.makedirs(PL, exist_ok=True)
	sheets = {}
	pal = palette()
	idle = None
	for (s, r, c), _ in POSES.values():
		if s not in sheets:
			sheets[s] = H.cells(os.path.join(H.SRC, "sprites_%s_%d.png" % (HERO, s)))
	idle = sheets[1][0][0]
	ib = H.alpha_mask(idle).getbbox()
	scale = H.HEIGHT / float(ib[3] - ib[1])
	for anim, ((s, r, c), _) in POSES.items():
		fr = H.to_palette(place(sheets[s][r][c], scale, anim), pal)
		fr.resize((H.FW * 2, H.FH * 2), Image.NEAREST).save(os.path.join(PL, "%s_base.png" % anim))
		print(anim, "base", fr.getbbox())



def juego():
	pal = palette()
	for anim, (_, use) in POSES.items():
		path = os.path.join(PL, "%s.png" % anim)
		if not os.path.exists(path):
			continue
		strip = Image.open(path).convert("RGBA")
		w, h = H.FW * 2, H.FH * 2
		n = strip.width // w
		idx = use if use is not None else list(range(1, n))
		d = os.path.join(OUT, anim)
		os.makedirs(d, exist_ok=True)
		for f in os.listdir(d):
			os.remove(os.path.join(d, f))
		for k, i in enumerate(idx):
			fr = H.lift_hair(H.lift_blacks(strip.crop((i * w, 0, (i + 1) * w, h)))).resize((H.FW, H.FH), Image.BOX)
			fr = H.clean(fr)
			# fuera los fogonazos y chispas que PixelLab pinta a veces (el juego dibuja los suyos)
			px = fr.load()
			for y in range(fr.height):
				for x in range(fr.width):
					r, g, b_, a = px[x, y]
					if a and r > 200 and g > 170 and b_ < 140 or a and min(r, g, b_) > 215:
						px[x, y] = (0, 0, 0, 0)
			fr = H.keep_largest(fr)
			# en la paleta de Junnie; sin contorno extra: PixelLab ya dibuja el suyo
			fr = H.to_palette(fr, pal, outline=False)
			fr.save(os.path.join(d, "%s_%02d.png" % (anim, k)))
		print(anim, len(idx), "fotogramas")


if __name__ == "__main__":
	{"base": base, "juego": juego}[sys.argv[1] if len(sys.argv) > 1 else "juego"]()
