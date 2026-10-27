"""Caja de madera de la 1.1 (pueblo de la pampa): escalón para subir a los toldos y a los techos.

Fuente: tools/sprites/pixellab/pueblo_extra/caja.png (PixelLab, create_image_pixen, 64x64).
Salida: assets/sprites/caja.png reducida a CAJA px (scripts/caja.gd).

Uso: python tools/sprites/caja.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CAJA = 24


def main():
	src = Image.open(ROOT / "tools/sprites/pixellab/pueblo_extra/caja.png").convert("RGBA")
	src = src.crop(src.getbbox())
	im = src.resize((CAJA, CAJA), Image.LANCZOS)
	im.putalpha(im.getchannel("A").point(lambda v: 255 if v >= 110 else 0))
	im.save(ROOT / "assets/sprites/caja.png")
	print("caja.png", im.size)


if __name__ == "__main__":
	main()
