"""Poses extra de los héroes hechas con PixelLab sobre sus fotogramas del juego (las hojas de ChatGPT no las traen).

  air_down   en el aire, apuntando recto hacia abajo (edit_image sobre el fotograma 0 de "jump")

Fuente: tools/sprites/pixellab/heroes/<id>/<pose>.png, al doble del tamaño del juego (192x160; la base,
<anim><n>_base.png, es el fotograma del juego ampliado sin suavizar). Cada pose se reduce a la mitad, se limpia
(sin chispas sueltas), se pasa a la paleta del soldado (la de su hoja ya montada) y se coloca con la cabeza a la
misma altura y centrada como el fotograma de partida. Sale como fotograma suelto en
tools/sprites/heroes/<id>/<pose>/<pose>_00.png, que heroes_sheets.py monta en la hoja.

Uso: python tools/sprites/heroes_extra.py   (y después python tools/sprites/heroes_sheets.py)
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import heroes_sheets as H  # noqa: E402

PL = os.path.join(os.path.dirname(__file__), "pixellab", "heroes")
# pose: (animación y fotograma de partida)
POSES = {"air_down": ("jump", 0)}


def palette(hero):
	sheet = Image.open(os.path.join(H.OUT, "player_%s_body.png" % hero)).convert("RGBA")
	opaque = [p[:3] for p in sheet.get_flattened_data() if p[3]]
	sample = Image.new("RGB", (len(opaque), 1))
	sample.putdata(opaque)
	return sample.quantize(colors=H.PALETTE, method=Image.Quantize.MEDIANCUT, kmeans=3)


def frame_of(hero, anim, col):
	with open(os.path.join(H.OUT, "player_%s_body_meta.json" % hero), encoding="utf-8") as f:
		meta = json.load(f)
	sheet = Image.open(os.path.join(H.OUT, "player_%s_body.png" % hero)).convert("RGBA")
	row = meta["anims"][anim]["row"]
	return sheet.crop((col * H.FW, row * H.FH, (col + 1) * H.FW, (row + 1) * H.FH))


def main():
	for hero in H.HEROES:
		pal = palette(hero)
		for pose, (anim, col) in POSES.items():
			src = os.path.join(PL, hero, "%s.png" % pose)
			if not os.path.exists(src):
				continue
			big = Image.open(src).convert("RGBA")
			fr = H.clean(big.resize((big.width // 2, big.height // 2), Image.BOX))
			fr = H.keep_largest(fr)
			fr = H.to_palette(fr, pal, outline=False)
			# misma altura de la cabeza y mismo centro que el fotograma de partida
			ref = H.alpha_mask(frame_of(hero, anim, col)).getbbox()
			b = H.alpha_mask(fr).getbbox()
			out = Image.new("RGBA", (H.FW, H.FH), (0, 0, 0, 0))
			# (si el arma no cabe por abajo, se sube lo justo)
			y = min(ref[1], H.FH - 1 - (b[3] - b[1]))
			out.alpha_composite(fr.crop(b), (round((ref[0] + ref[2]) / 2 - (b[2] - b[0]) / 2), y))
			d = os.path.join(H.FRAMES, hero, pose)
			os.makedirs(d, exist_ok=True)
			out.save(os.path.join(d, "%s_00.png" % pose))
			print(hero, pose, out.getbbox())


if __name__ == "__main__":
	main()
