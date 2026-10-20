"""Arte de la cinemática de llegada a la 1.1 (scripts/cinematica_llegada.gd), dibujado por Eduardo con ChatGPT.

Fuente (tools/sprites/chatgpt/cinematica/):
  cielo_aereo.png          toma aérea del atardecer por donde llega el helicóptero
  helicoptero_anim_1/2.png 4 + 4 fotogramas del helicóptero con el rotor girando (fondo transparente,
                           mirando a la izquierda)
  helicoptero.png          el helicóptero quieto, de referencia

Salida (assets/sprites/):
  cine_cielo.png           el cielo a la altura de la pantalla (270 px), más ancho para el paneo
  cine_heli.png            los 8 fotogramas del helicóptero, mirando a la derecha (hacia donde vuela), alineados
                           por el cuerpo (patín de abajo y morro) para que no tiemble entre fotogramas
  cine_heli_meta.json      tamaño de fotograma y la puerta por donde salta el soldado

Uso: python tools/sprites/cinematica.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/chatgpt/cinematica"
OUT = ROOT / "assets/sprites"

SKY_H = 270
HELI_W = 170          # ancho del cuerpo del helicóptero en el juego (sin las palas)
HFW, HFH = 220, 96    # fotograma del helicóptero


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def tiras(path, n=4):
	"""Corta una tira de n helicópteros repartidos a lo ancho: cada corte va por la columna más vacía cerca de
	su división (el borrón del rotor de uno puede tocar al de al lado). Lista de recortes, de izquierda a derecha."""
	im = Image.open(path).convert("RGBA")
	a = im.getchannel("A").point(lambda v: 255 if v > 60 else 0)
	col = [sum(1 for y in range(0, im.height, 2) if a.getpixel((x, y))) for x in range(im.width)]
	cuts = [0]
	for k in range(1, n):
		c = k * im.width // n
		cuts.append(min(range(c - 90, c + 90), key=lambda x: col[x]))
	cuts.append(im.width)
	out = []
	for x0, x1 in zip(cuts, cuts[1:]):
		c = im.crop((x0, 0, x1, im.height))
		out.append(c.crop(c.getbbox()))
	return out


def cuerpo(f):
	"""(x del morro, y del patín) del helicóptero: lo más a la izquierda en la mitad de abajo y lo más bajo."""
	a = f.getchannel("A").point(lambda v: 255 if v > 100 else 0)
	b = a.getbbox()
	low = a.crop((0, b[1] + (b[3] - b[1]) // 2, f.width, b[3])).getbbox()
	return low[0], b[3]


def main():
	sky = Image.open(SRC / "cielo_aereo.png").convert("RGB")
	s = SKY_H / sky.height
	sky = sky.resize((round(sky.width * s), SKY_H), Image.LANCZOS)
	sky.save(OUT / "cine_cielo.png")

	frames = tiras(SRC / "helicoptero_anim_1.png") + tiras(SRC / "helicoptero_anim_2.png")
	assert len(frames) == 8, len(frames)
	# escala por el cuerpo (del morro a la cola) del primer fotograma
	nose0, _ = cuerpo(frames[0])
	scale = HELI_W / (frames[0].width - nose0)
	sheet = Image.new("RGBA", (HFW * len(frames), HFH), (0, 0, 0, 0))
	nose_x = 20
	skid_y = HFH - 4
	for i, f in enumerate(frames):
		nose, skid = cuerpo(f)
		small = nitido(f.resize((round(f.width * scale), round(f.height * scale)), Image.LANCZOS))
		# mirando a la derecha: el morro va a la derecha del fotograma
		small = small.transpose(Image.FLIP_LEFT_RIGHT)
		nx = small.width - round(nose * scale)  # x del morro tras voltear
		sheet.alpha_composite(small, (i * HFW + (HFW - nose_x) - nx, skid_y - round(skid * scale)))
	sheet.save(OUT / "cine_heli.png")
	# puerta (la de la ventana grande): a ~40 % del cuerpo desde el morro; el soldado sale por debajo, a la altura del patín
	door = [HFW - nose_x - round(HELI_W * 0.40), skid_y - 6]
	meta = {"frame": [HFW, HFH], "frames": len(frames), "door": door}
	(OUT / "cine_heli_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("cine_cielo.png", sky.size, "cine_heli.png", sheet.size, "puerta", door)


if __name__ == "__main__":
	main()
