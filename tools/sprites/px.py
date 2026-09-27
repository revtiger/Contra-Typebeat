"""Utilidades de pixel art para los generadores de sprites.

Todo se dibuja sin suavizado (píxel duro) y al final se añade el contorno oscuro de 1 px
que da el aspecto Metal Slug. Los PNG resultantes se pueden abrir y retocar en Aseprite.
"""
import math
from PIL import Image, ImageDraw

OUTLINE = (12, 10, 16, 255)


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def c(rgb, a=255):
    return (rgb[0], rgb[1], rgb[2], a)


class Pen:
    """Pincel sobre una imagen. Las coordenadas son en píxeles del sprite."""

    def __init__(self, img, flip_w=None):
        self.img = img
        self.d = ImageDraw.Draw(img)
        self.flip_w = flip_w  # si se da, espeja en x

    def _x(self, x):
        return x if self.flip_w is None else self.flip_w - 1 - x

    def rect(self, x, y, w, h, col):
        if w <= 0 or h <= 0:
            return
        x0, x1 = self._x(x), self._x(x + w - 1)
        self.d.rectangle([min(x0, x1), y, max(x0, x1), y + h - 1], fill=c(col))

    def px(self, x, y, col):
        xi, yi = int(round(self._x(x))), int(round(y))
        if 0 <= xi < self.img.width and 0 <= yi < self.img.height:
            self.img.putpixel((xi, yi), c(col))

    def poly(self, pts, col):
        self.d.polygon([(self._x(x), y) for x, y in pts], fill=c(col))

    def line(self, a, b, col, w=1):
        self.d.line([(self._x(a[0]), a[1]), (self._x(b[0]), b[1])], fill=c(col), width=w)
        if w > 2:
            r = (w - 1) / 2
            for p in (a, b):
                x, y = self._x(p[0]), p[1]
                self.d.ellipse([x - r, y - r, x + r, y + r], fill=c(col))

    def circle(self, x, y, r, col):
        x = self._x(x)
        self.d.ellipse([x - r, y - r, x + r, y + r], fill=c(col))


def limb(pen, a, b, col, w, shade=None):
    """Segmento grueso (brazo, pierna) con una línea de sombra opcional por debajo."""
    pen.line(a, b, col, w)
    if shade is not None and w >= 3:
        pen.line((a[0], a[1] + (w // 2)), (b[0], b[1] + (w // 2)), shade, 1)


def polar(origin, length, deg):
    """Punto a `length` px desde origin; 0 grados = hacia abajo, positivo = hacia delante (+x)."""
    r = math.radians(deg)
    return (origin[0] + math.sin(r) * length, origin[1] + math.cos(r) * length)


def outline(img, col=OUTLINE):
    """Añade un contorno de 1 px alrededor de todo lo opaco."""
    src = img.load()
    w, h = img.size
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                    dst[x, y] = col
                    break
    return out


def sheet(frames_by_row, fw, fh):
    """Monta una hoja: una fila por animación, un fotograma por columna."""
    cols = max(len(r) for r in frames_by_row)
    out = canvas(fw * cols, fh * len(frames_by_row))
    for ry, row in enumerate(frames_by_row):
        for cx, fr in enumerate(row):
            out.paste(fr, (cx * fw, ry * fh), fr)
    return out


def preview(img, scale, path, bg=(90, 110, 140)):
    """Copia ampliada con fondo para revisar a ojo."""
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    base = Image.new("RGBA", big.size, bg + (255,))
    base.alpha_composite(big)
    base.convert("RGB").save(path)
