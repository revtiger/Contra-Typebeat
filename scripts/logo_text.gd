extends Node2D
## Texto con las letras cinceladas del logo (assets/sprites/logo_font.png, tools/sprites/logo.py).
## Las letras pueden caer de una en una como en la intro de Metal Slug 2.
## La posición del nodo es el centro superior del texto.

signal letter_landed(index: int, pos: Vector2)

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const DROP := 0.14  # lo que tarda cada letra en caer

var text := ""
var style := "big_gold"
## Momento (en segundos desde que el nodo existe) en que empieza a caer la primera letra; < 0 = todo visible
var reveal_at := -1.0
var interval := 0.22
var t := 0.0
var _tex: Texture2D
var _meta: Dictionary
var _landed := 0


func _ready() -> void:
	_tex = load("res://assets/sprites/logo_font.png")
	_meta = SpriteUtil.meta("res://assets/sprites/logo_font_meta.json")


func width() -> float:
	var st: Dictionary = _meta["styles"][style]
	var w := 0.0
	for ch in text.to_upper():
		w += st["space"] if ch == " " else st["advance"]
	return w


func all_visible() -> bool:
	return reveal_at < 0.0 or t >= reveal_at + (text.length() - 1) * interval + DROP


func _process(delta: float) -> void:
	t += delta
	if reveal_at >= 0.0:
		while _landed < text.length() and t >= reveal_at + _landed * interval + DROP:
			if text[_landed] != " ":
				letter_landed.emit(_landed, global_position + Vector2(_letter_x(_landed) + 12, 30) * scale)
			_landed += 1
	queue_redraw()


func _letter_x(i: int) -> float:
	var st: Dictionary = _meta["styles"][style]
	var x := -width() / 2.0
	var up := text.to_upper()
	for j in i:
		x += st["space"] if up[j] == " " else st["advance"]
	return x


func _draw() -> void:
	if _meta.is_empty():
		return
	var st: Dictionary = _meta["styles"][style]
	var chars: String = _meta["chars"]
	var up := text.to_upper()
	var x := -width() / 2.0
	for i in up.length():
		var ch := up[i]
		var adv: float = st["space"] if ch == " " else st["advance"]
		var k := 1.0
		if reveal_at >= 0.0:
			k = clampf((t - (reveal_at + i * interval)) / DROP, 0.0, 1.0)
		if k > 0.0 and ch != " ":
			var idx := chars.find(ch)
			if idx >= 0:
				var drop := (1.0 - k) * (1.0 - k) * -70.0
				var sc := 1.0 + (1.0 - k) * 0.6
				var w: float = st["w"]
				var h: float = st["h"]
				var dst := Rect2(x + w / 2.0 - w * sc / 2.0, drop + h / 2.0 - h * sc / 2.0, w * sc, h * sc)
				var src := Rect2(idx * w, st["y"], w, h)
				draw_texture_rect_region(_tex, dst, src, Color(1, 1, 1, k))
		x += adv
