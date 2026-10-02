extends Node2D
## HUD estilo Metal Slug, dibujado con la fuente pixelada de assets/sprites/font.png (tools/sprites/font.py).
## - Arriba a la izquierda: puntuación, 1UP=vidas y el recuadro metálico ARMS / BOMB, más el icono del arma
## - Arriba al centro: TIME con números cromados (parpadea en rojo al final)
## - Arriba a la derecha: récord
## - Cartel central: la primera línea en letra grande (MISSION START, MISSION COMPLETE...), el resto pequeña
## Va dentro de un CanvasLayer; `level` es la escena de la misión.

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const ACCENTS := {"Á": "A", "À": "A", "Ä": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U",
	"¡": "|", "¿": "^", "♥": "<", "∞": "~"}

var level
var font: Texture2D
var meta: Dictionary
var banner_text := "":
	set(v):
		if v != banner_text:
			banner_text = v
			_pop = 0.0
var _pop := 1.0
var t := 0.0


func _ready() -> void:
	font = load("res://assets/sprites/font.png")
	meta = SpriteUtil.meta("res://assets/sprites/font_meta.json")


func _process(delta: float) -> void:
	t += delta
	_pop = minf(_pop + delta * 7.0, 1.0)
	queue_redraw()


## Ancho en píxeles de un texto en un estilo.
func text_width(text: String, style: String) -> int:
	return _clean(text).length() * int(meta["styles"][style]["advance"])


func _clean(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		out += ACCENTS.get(ch, ch)
	return out


## Dibuja texto con la fuente pixelada. align: 0 izquierda, 1 centro, 2 derecha.
func draw_text(text: String, pos: Vector2, style := "small", align := 0, tint := Color.WHITE) -> void:
	var st: Dictionary = meta["styles"][style]
	var chars: String = meta["chars"]
	var clean := _clean(text)
	var adv: int = st["advance"]
	var offsets: Array[float] = [0.0, clean.length() * adv / 2.0, float(clean.length() * adv)]
	var x: float = pos.x - offsets[align]
	for ch in clean:
		var i := chars.find(ch)
		if i < 0:
			i = chars.find(" ")
		var src := Rect2(i * st["w"], st["y"], st["w"], st["h"])
		draw_texture_rect_region(font, Rect2(roundf(x), pos.y, st["w"], st["h"]), src, tint)
		x += adv


func _frame(r: Rect2) -> void:
	# recuadro metálico con remaches
	draw_rect(r, Color(0.04, 0.05, 0.1, 0.8))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(0.78, 0.8, 0.86))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(0.66, 0.68, 0.74))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), Color(0.28, 0.3, 0.36))
	draw_rect(Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y)), Color(0.34, 0.36, 0.42))
	draw_rect(r.grow(1), Color(0.05, 0.04, 0.08), false, 1)
	for c in [r.position + Vector2(3, 3), r.position + Vector2(r.size.x - 4, 3),
			r.position + Vector2(3, r.size.y - 4), r.position + Vector2(r.size.x - 4, r.size.y - 4)]:
		draw_rect(Rect2(c, Vector2(1, 1)), Color(1, 1, 1, 0.8))


func _draw() -> void:
	if level == null or meta.is_empty():
		return
	var p = level.player
	# puntuación y vidas
	draw_text(str(Game.score), Vector2(112, 4), "small", 2)
	draw_text("1UP=" , Vector2(6, 20), "label")
	draw_text(str(maxi(Game.lives, 0)), Vector2(30, 20), "small")
	# recuadro ARMS / BOMB
	var box := Rect2(46, 15, 68, 23)
	_frame(box)
	draw_rect(Rect2(box.position.x + 34, box.position.y + 3, 1, box.size.y - 6), Color(0.4, 0.42, 0.5))
	draw_text("ARMS", Vector2(box.position.x + 17, box.position.y + 3), "label", 1)
	draw_text("BOMB", Vector2(box.position.x + 51, box.position.y + 3), "label", 1)
	var ammo_text := "~" if p.ammo < 0 else str(p.ammo)
	draw_text(ammo_text, Vector2(box.position.x + 17, box.position.y + 12), "small", 1)
	var bomb_tint := Color.WHITE if p.bombs > 0 or int(t * 4.0) % 2 == 0 else Color(1, 0.3, 0.3)
	draw_text(str(p.bombs), Vector2(box.position.x + 51, box.position.y + 12), "small", 1, bomb_tint)
	# icono del arma especial
	if p.weapon != "P":
		var ib := Rect2(118, 15, 23, 23)
		_frame(ib)
		draw_text(p.weapon, Vector2(ib.position.x + 12, ib.position.y + 4), "title", 1)
	# TIME
	var time_tint := Color.WHITE
	if level.time_left <= 10 and int(t * 4.0) % 2 == 0:
		time_tint = Color(1, 0.35, 0.3)
	draw_text("%02d" % level.time_left, Vector2(240, 3), "metal", 1, time_tint)
	# récord
	draw_text("HI", Vector2(390, 4), "label")
	draw_text(str(Game.record), Vector2(474, 4), "small", 2)
	# cartel central
	if banner_text != "":
		var lines := banner_text.split("\n")
		var y := 130.0 - lines.size() * 9.0
		var k := 1.0 + (1.0 - _pop) * 0.6
		for i in lines.size():
			var style := "title" if i == 0 else "small"
			if lines[i] == "":
				y += 8
				continue
			if i == 0:
				draw_set_transform(Vector2(240, y + 8) * (1.0 - k), 0.0, Vector2(k, k))
			draw_text(lines[i], Vector2(240, y), style, 1)
			draw_set_transform(Vector2.ZERO)
			y += 26.0 if i == 0 else 12.0
