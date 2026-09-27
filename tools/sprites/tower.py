"""Rascacielos en llamas del menú, hecho con PixelLab (imagen + animación de 8 fotogramas).

PixelLab anima todo el dibujo y las ventanas cambian en cada fotograma, así que aquí se fija
el edificio (sacado del fotograma 0) y solo se anima la parte de arriba (fuego y azotea).

Entrada: tools/sprites/pixellab/tower/frame_0..8.png (96x192)
Uso:     python tools/sprites/tower.py  ->  assets/sprites/city_tower.png (9 fotogramas en fila)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image  # noqa: E402
from px import preview  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "sprites")
SRC = os.path.join(os.path.dirname(__file__), "pixellab", "tower")
PREV = os.path.join(os.path.dirname(__file__), "preview")
W, H = 96, 192
FIRE_Y = 70  # por encima se anima (fuego); por debajo, edificio fijo
FRAMES = 9

if __name__ == "__main__":
    frames = [Image.open(os.path.join(SRC, "frame_%d.png" % i)).convert("RGBA") for i in range(FRAMES)]
    base = frames[0]
    sheet = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        im = base.copy()
        im.paste(f.crop((0, 0, W, FIRE_Y)), (0, 0))
        sheet.paste(im, (i * W, 0))
    os.makedirs(PREV, exist_ok=True)
    sheet.save(os.path.join(OUT, "city_tower.png"))
    preview(sheet, 2, os.path.join(PREV, "city_tower.png"), bg=(20, 20, 50))
    print("ok city_tower", FRAMES, "fotogramas")
