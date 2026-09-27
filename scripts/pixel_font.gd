extends RefCounted
## Fuente pixelada del juego (estilo Metal Slug) como FontFile de Godot, para Labels y draw_string.
## La imagen y los datos salen de tools/sprites/font.py (assets/sprites/font.png + font_meta.json).
##
## Estilos por jerarquía:
##   title - títulos y logos (grande, degradado amarillo -> rojo)
##   small - valores, opción elegida, énfasis (dorado)
##   white - texto normal
##   label - etiquetas, ayudas, texto secundario (azul claro)
##   metal - números grandes cromados (TIME)
## Todo se muestra en mayúsculas: las minúsculas y los acentos usan la letra base.
##
## Uso:  PixelFont.apply(label, "title", 2)   # estilo y escala entera
##       draw_string(PixelFont.font("white"), pos, texto, ..., PixelFont.size("white"))

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const MAP := {"Á": "A", "À": "A", "Ä": "A", "É": "E", "È": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U",
	"¡": "|", "¿": "^", "♥": "<", "∞": "~", "·": ".", "▶": "*", "◀": "*", "▷": "*", "◁": "*"}

static var _fonts := {}


static func _meta() -> Dictionary:
	return SpriteUtil.meta("res://assets/sprites/font_meta.json")


## Alto en píxeles de un estilo (tamaño de fuente a escala 1).
static func size(style: String) -> int:
	return int(_meta()["styles"][style]["h"])


static func font(style: String) -> FontFile:
	if _fonts.has(style):
		return _fonts[style]
	var meta := _meta()
	var st: Dictionary = meta["styles"][style]
	var chars: String = meta["chars"]
	var w: int = st["w"]
	var h: int = st["h"]
	var adv: int = st["advance"]
	var tex: Texture2D = load("res://assets/sprites/font.png")
	var f := FontFile.new()
	f.fixed_size = h
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	var sz := Vector2i(h, 0)
	f.set_cache_ascent(0, h, h - 2)
	f.set_cache_descent(0, h, 2)
	f.set_texture_image(0, sz, 0, tex.get_image())
	var add := func(code: int, idx: int) -> void:
		if idx < 0:
			return
		f.set_glyph_advance(0, h, code, Vector2(adv, 0))
		f.set_glyph_offset(0, sz, code, Vector2(0, -(h - 2)))
		f.set_glyph_size(0, sz, code, Vector2(w, h))
		f.set_glyph_uv_rect(0, sz, code, Rect2(idx * w, st["y"], w, h))
		f.set_glyph_texture_idx(0, sz, code, 0)
	for i in chars.length():
		add.call(chars.unicode_at(i), i)
	for c in "abcdefghijklmnopqrstuvwxyzñ":
		add.call(c.unicode_at(0), chars.find(c.to_upper()))
	for k in MAP:
		add.call(k.unicode_at(0), chars.find(MAP[k]))
		add.call(k.to_lower().unicode_at(0), chars.find(MAP[k]))
	_fonts[style] = f
	return f


## Aplica la fuente a un Label (o cualquier Control con texto) con escala entera.
static func apply(ctrl: Control, style: String, scale := 1) -> void:
	ctrl.add_theme_font_override("font", font(style))
	ctrl.add_theme_font_size_override("font_size", size(style) * scale)
	ctrl.add_theme_constant_override("outline_size", 0)
	ctrl.add_theme_color_override("font_color", Color.WHITE)
	ctrl.add_theme_constant_override("line_spacing", 2 * scale)


## Tema por defecto para todo el juego: texto normal en blanco pixelado.
static func default_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font("white")
	th.default_font_size = size("white")
	return th
