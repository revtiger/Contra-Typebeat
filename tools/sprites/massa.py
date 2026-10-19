"""Hoja de sprites de Sergio Massa (minijefe 1.1), 60 px de alto (×1,25 Eduardo).

Fuente: dos poses de Eduardo hechas con ChatGPT (tools/sprites/chatgpt/massa/traje.png y chaleco.png,
mirando a la izquierda), reducidas a bases de 128x128 (figura de 120 px, pies en y = 124) en
tools/sprites/pixellab/massa2/<traje|chaleco>_base.png y animadas con PixelLab (animate_image). Cada tira
<anim>.png es horizontal, fotogramas de 128x128; el 0 es la base:
  de traje:   idle (4), walk (8, se gira de perfil en el 4), thumbs (pulgar arriba), strip (se quita el
              saco y agarra el rifle; termina en la pose del chaleco)
              pitch1: lanza una granada con la derecha como un lanzador de béisbol. La segunda, con la
              izquierda, va por tramos alrededor de una pose clave (pitch2_clave.png, edit_image: brazo
              izquierdo atrás con la granada): pitch2_prepara (del final de pitch1 a la clave), pitch2_latigo
              (desde la clave: látigo hacia delante; en su fotograma 4 suelta la granada) y pitch2_vuelta
              (desde ese fotograma sin la granada, pitch2_suelta.png, hasta la base). Juntas forman
              "grenade" (23 fotogramas)
  de chaleco: v_idle (4), v_walk (8), v_shoot (4, con fogonazo)
  walk2 / v_walk2: ciclos de caminar de 8 pasos animados desde el último fotograma (de perfil) de walk y
              v_walk (<anim>_perfil_base.png); son los que usa el juego
Los fotogramas se reducen a la mitad (64x64): Massa mide 60 px.

Salida: assets/sprites/boss_massa.png (una fila por animación) y boss_massa_meta.json (filas, fotogramas, pivote en los pies y
puntos útiles, mirando a la izquierda).

Uso: python tools/sprites/massa.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/pixellab/massa2"
OUT = ROOT / "assets/sprites"

BASE = 128
FW = FH = 64
# (animación, [(tira de origen, fotogramas usados), ...])
ANIMS = [
	("idle", [("idle", range(0, 5))]),
	("walk", [("walk2", range(1, 9))]),
	("grenade", [("pitch1", range(0, 9)), ("pitch2_prepara", range(1, 4)), ("pitch2_latigo", [0, 2, 3, 4]),
		("pitch2_vuelta", range(1, 7))]),
	("thumbs", [("thumbs", range(0, 9))]),
	("strip", [("strip", range(0, 9))]),
	("v_idle", [("v_idle", range(0, 5))]),
	("v_walk", [("v_walk2", range(1, 9))]),
	("v_shoot", [("v_shoot", range(1, 5))]),
]
# fotogramas de "grenade" en los que sale cada granada (derecha, izquierda): con el brazo ya estirado y la mano
# vacía, para que no se vea la granada dos veces
GRENADE_RELEASE = [8, 16]
# duración relativa de cada fotograma de "grenade": rápido en las transiciones, más largo al cargar el brazo
# (anticipación) y al soltar (impacto), como un lanzador de béisbol
GRENADE_DURATIONS = [0.5, 0.5, 0.9, 0.9, 0.9, 1, 1, 1.7, 1.4, 1, 0.7, 0.9, 1.1, 0.6, 1.5, 1.2, 1.4, 1, 0.7, 0.7, 0.7, 0.8]


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def pies_x(im):
	a = im.getchannel("A")
	band = a.crop((0, im.height - 8, im.width, im.height)).getbbox()
	return (band[0] + band[2]) / 2


def sin_fogonazo(fr):
	"""El fotograma sin los píxeles del fogonazo (amarillos y blancos cálidos)."""
	fr = fr.copy()
	px = fr.load()
	for y in range(fr.height):
		for x in range(fr.width):
			r, g, b, a = px[x, y]
			if a and r > 200 and g > 170 and b < 160:
				px[x, y] = (0, 0, 0, 0)
	return fr


def izquierda(fr, y0, y1):
	"""Píxel opaco más a la izquierda entre las filas y0 y y1."""
	a = fr.getchannel("A").load()
	return list(min(((x, y) for y in range(y0, y1) for x in range(FW) if a[x, y] > 128), key=lambda p: p[0]))


def main():
	strips = {s: Image.open(SRC / f"{s}.png").convert("RGBA") for _, segs in ANIMS for s, _ in segs}
	cols = max(sum(len(r) for _, r in segs) for _, segs in ANIMS)
	sheet = Image.new("RGBA", (FW * cols, FH * len(ANIMS)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "anims": {}}
	ref = None
	cuadros = {}
	for row, (name, segs) in enumerate(ANIMS):
		frs = [nitido(strips[src].crop((i * BASE, 0, (i + 1) * BASE, BASE)).resize((FW, FH), Image.LANCZOS))
			for src, rng in segs for i in rng]
		# cada animación se corre en x para que sus pies (de media) caigan donde los de idle: así no da un
		# salto al pasar de estar quieto a caminar
		medio = sum(pies_x(f) for f in frs) / len(frs)
		ref = medio if ref is None else ref
		dx = round(ref - medio)
		for col, fr in enumerate(frs):
			sheet.alpha_composite(fr, (col * FW + dx, row * FH))
		cuadros[name] = [sheet.crop((c * FW, row * FH, (c + 1) * FW, (row + 1) * FH)) for c in range(len(frs))]
		meta["anims"][name] = {"row": row, "frames": len(frs)}
	idle = sheet.crop((0, 0, FW, FH))
	meta["pivot"] = [round(pies_x(idle)), 62]
	# puntos útiles en píxeles del fotograma (mirando a la izquierda)
	# boca del rifle en cada fotograma de disparo: el píxel opaco más a la izquierda entre la cintura y el pecho,
	# sin contar el fogonazo dibujado (amarillo)
	meta["muzzle"] = izquierda(cuadros["v_idle"][0], 30, 50)
	meta["muzzles_shoot"] = [izquierda(sin_fogonazo(f), 30, 50) for f in cuadros["v_shoot"]]
	meta["grenade_durations"] = GRENADE_DURATIONS
	# manos al soltar cada granada: lo más adelantado (a la izquierda) por encima de la cintura
	meta["grenade_release"] = GRENADE_RELEASE
	meta["hand_r"] = izquierda(cuadros["grenade"][GRENADE_RELEASE[0]], 0, 45)
	meta["hand_l"] = izquierda(cuadros["grenade"][GRENADE_RELEASE[1]], 0, 45)
	sheet.save(OUT / "boss_massa.png")
	(OUT / "boss_massa_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("boss_massa.png", sheet.size, "pivote", meta["pivot"], "boca", meta["muzzle"], "manos", meta["hand_r"], meta["hand_l"])


if __name__ == "__main__":
	main()
