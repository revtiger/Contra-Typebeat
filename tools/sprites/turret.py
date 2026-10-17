"""Torreta enemiga hecha con PixelLab: búnker de sacos terreros (base) y ametralladora que gira encima.

Entrada: tools/sprites/pixellab/torreta/nido.png (48x32) y arma.png (32x32, apuntando a la derecha)
Salida:  assets/sprites/turret_base.png y turret_gun.png, recortadas a lo que se ve.
         turret.gd dibuja la base con el borde de abajo en el suelo y el arma girando sobre su pivote.

Uso: python tools/sprites/turret.py
"""
import os

from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "pixellab", "torreta")
OUT = os.path.join(HERE, "..", "..", "assets", "sprites")

if __name__ == "__main__":
	for src, dst in (("nido.png", "turret_base.png"), ("arma.png", "turret_gun.png")):
		im = Image.open(os.path.join(SRC, src)).convert("RGBA")
		im = im.crop(im.getbbox())
		im.save(os.path.join(OUT, dst))
		print("ok", dst, im.size)
