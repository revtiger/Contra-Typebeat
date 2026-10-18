"""Hoja de sprites de Sergio Massa (minijefe 1.1), 60 px de alto (×1,25 Eduardo).

Fuente: dos poses de Eduardo hechas con ChatGPT (tools/sprites/chatgpt/massa/traje.png y chaleco.png,
mirando a la izquierda), reducidas a bases de 128x128 (figura de 120 px, pies en y = 124) en
tools/sprites/pixellab/massa2/<traje|chaleco>_base.png y animadas con PixelLab (animate_image). Cada tira
<anim>.png es horizontal, fotogramas de 128x128; el 0 es la base:
  de traje:   idle (4), walk (8, se gira de perfil en el 4), talk (discurso), throw (saca un fajo del saco
              y lo lanza), thumbs (pulgar arriba), strip (se quita el saco y agarra el rifle; termina en
              la pose del chaleco)
  de chaleco: v_idle (4), v_walk (8), v_shoot (4, con fogonazo)
Los fotogramas se reducen a la mitad (64x64): Massa mide 60 px.

Salida: assets/sprites/boss_massa.png (una fila por animación), boss_massa_bundle.png (el fajo, de
tools/sprites/pixellab/massa/bundle.png) y boss_massa_meta.json (filas, fotogramas, pivote en los pies y
puntos útiles, mirando a la izquierda).

Uso: python tools/sprites/massa.py
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/sprites/pixellab/massa2"
OLD = ROOT / "tools/sprites/pixellab/massa"
OUT = ROOT / "assets/sprites"

BASE = 128
FW = FH = 64
# (animación, tira de origen, fotogramas usados)
ANIMS = [
	("idle", "idle", range(0, 5)),
	("walk", "walk", range(5, 9)),     # los primeros apenas se mueven: el ciclo útil es de perfil
	("talk", "talk", range(0, 9)),
	("throw", "throw", range(0, 9)),
	("thumbs", "thumbs", range(0, 9)),
	("strip", "strip", range(0, 9)),
	("v_idle", "v_idle", range(0, 5)),
	("v_walk", "v_walk", range(5, 9)),
	("v_shoot", "v_shoot", range(1, 5)),
]


def nitido(im):
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
	return im


def pies_x(im):
	a = im.getchannel("A")
	band = a.crop((0, int(im.height * 0.9), im.width, im.height)).getbbox()
	return (band[0] + band[2]) / 2


def main():
	strips = {n: Image.open(SRC / f"{n}.png").convert("RGBA") for n in {s for _, s, _ in ANIMS}}
	cols = max(len(r) for _, _, r in ANIMS)
	sheet = Image.new("RGBA", (FW * cols, FH * len(ANIMS)), (0, 0, 0, 0))
	meta = {"frame": [FW, FH], "anims": {}}
	for row, (name, src, rng) in enumerate(ANIMS):
		for col, i in enumerate(rng):
			fr = strips[src].crop((i * BASE, 0, (i + 1) * BASE, BASE))
			sheet.alpha_composite(nitido(fr.resize((FW, FH), Image.LANCZOS)), (col * FW, row * FH))
		meta["anims"][name] = {"row": row, "frames": len(rng)}
	idle = sheet.crop((0, 0, FW, FH))
	meta["pivot"] = [round(pies_x(idle)), 62]
	# puntos útiles en píxeles del fotograma (mirando a la izquierda)
	meta["mouth"] = [27, 16]       # de donde salen las promesas del discurso
	meta["hand_throw"] = [7, 18]   # mano con el fajo (últimos fotogramas de throw)
	v = sheet.crop((0, meta["anims"]["v_idle"]["row"] * FH, FW, (meta["anims"]["v_idle"]["row"] + 1) * FH))
	a = v.getchannel("A").load()
	# boca del rifle: el píxel opaco más a la izquierda entre la cintura y el pecho
	mx, my = min(((x, y) for y in range(30, 50) for x in range(FW) if a[x, y] > 128), key=lambda p: p[0])
	meta["muzzle"] = [mx, my]
	sheet.save(OUT / "boss_massa.png")
	b = Image.open(OLD / "bundle.png").convert("RGBA")
	b = b.crop(b.getbbox())
	b = nitido(b.resize((max(1, b.width * 2 // 3), max(1, b.height * 2 // 3)), Image.LANCZOS))
	b.save(OUT / "boss_massa_bundle.png")
	(OUT / "boss_massa_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8", newline="\n")
	print("boss_massa.png", sheet.size, "pivote", meta["pivot"], "boca", meta["muzzle"])


if __name__ == "__main__":
	main()
