"""Retratos de ELIGE TU SOLDADO a partir de los diseños de Eduardo hechos con ChatGPT.

Entrada: tools/sprites/chatgpt/heroe_<id>.png (cuerpo entero, fondo transparente, "píxel" de ~11 px).
Salida:  tools/sprites/chatgpt/portrait_<id>.png (72x96, cabeza y hombros sobre fondo oscuro).
portraits.py usa estos retratos igual que los de PixelLab.

Uso: python tools/sprites/chatgpt_heroes.py
"""
import os

from PIL import Image

HERE = os.path.join(os.path.dirname(__file__), "chatgpt")
W, H = 72, 96
BG = (6, 3, 2, 255)
# recorte de la cabeza y los hombros en el diseño original (x, y, ancho); el alto sale de la proporción 72x96
CROPS = {
	"comando": (538, 84, 324),
	"hawaiano": (528, 70, 324),
}


def portrait(pid):
	src = Image.open(os.path.join(HERE, "heroe_%s.png" % pid)).convert("RGBA")
	x, y, w = CROPS[pid]
	h = w * H // W
	crop = src.crop((x, y, x + w, y + h))
	# muestreo en el centro de cada píxel de destino: conserva los bloques del pixel art
	small = crop.resize((W, H), Image.NEAREST, reducing_gap=None)
	out = Image.new("RGBA", (W, H), BG)
	out.alpha_composite(small)
	return out


def main():
	for pid in CROPS:
		portrait(pid).save(os.path.join(HERE, "portrait_%s.png" % pid))
	print("ok retratos", list(CROPS))


if __name__ == "__main__":
	main()
