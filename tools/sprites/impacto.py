"""Impacto de bala hecho con PixelLab (create_vfx, efecto 'impacto_bala').

Entrada: tools/sprites/pixellab/impacto/impacto-bala.png (hoja 3x2 de fotogramas de 24x24, origen en el centro)
Salida:  assets/sprites/impact.png (los 6 fotogramas en una fila, como los usa scripts/impact.gd)

Uso: python tools/sprites/impacto.py
"""
import json
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "impacto")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites", "impact.png")

if __name__ == "__main__":
	sheet = Image.open(os.path.join(SRC, "impacto-bala.png")).convert("RGBA")
	frames = json.load(open(os.path.join(SRC, "impacto-bala.json"), encoding="utf-8"))["frames"]
	w, h = frames[0]["frame"]["w"], frames[0]["frame"]["h"]
	strip = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
	for i, f in enumerate(frames):
		r = f["frame"]
		strip.alpha_composite(sheet.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])), (i * w, 0))
	strip.save(OUT)
	print("ok impact", len(frames), "fotogramas")
