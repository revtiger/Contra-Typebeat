extends Node2D
## Retrato pixelado de un personaje con traje (estilo póster de película de acción).
## Se dibuja en una cuadrícula de 20x24 "píxeles" de tamaño PX. El origen es la esquina superior izquierda.

const PX := 3.0
const W := 20
const H := 24

var skin := Color(0.93, 0.72, 0.56)
var hair := Color(0.3, 0.2, 0.12)
var hair_style := "short"  # short | slick | bald | long | mohawk
var beard := false
var stubble := false
var sunglasses := false
var scar := false
var suit := Color(0.12, 0.12, 0.15)
var tie := Color(0.7, 0.1, 0.1)
var rim := Color(1.0, 0.55, 0.15)  # luz de la explosión por la izquierda
var appear := 1.0  # 0..1 para animar la entrada


func _p(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


func _draw() -> void:
	if appear <= 0.0:
		return
	var shade := skin.darkened(0.25)
	# marco
	draw_rect(Rect2(-2, -2, W * PX + 4, H * PX + 4), Color(0.9, 0.75, 0.3))
	draw_rect(Rect2(0, 0, W * PX, H * PX), Color(0.06, 0.05, 0.1))
	for i in 6:
		_p(0, 16 + i, W, 1, Color(0.5, 0.15, 0.05, 0.08 * i))
	# pelo largo por detrás
	if hair_style == "long":
		_p(4, 4, 12, 14, hair)
	# traje, camisa y corbata
	_p(1, 19, 18, 5, suit)
	_p(0, 21, 20, 3, suit)
	_p(7, 18, 6, 6, Color(0.92, 0.92, 0.9))
	_p(6, 18, 2, 3, suit.lightened(0.15))
	_p(12, 18, 2, 3, suit.lightened(0.15))
	_p(9, 19, 2, 5, tie)
	_p(9, 19, 2, 1, tie.darkened(0.3))
	# cuello y cabeza
	_p(8, 16, 4, 3, shade)
	_p(5, 5, 10, 11, skin)
	_p(6, 16, 8, 1, skin)
	_p(5, 5, 1, 1, Color(0.06, 0.05, 0.1))
	_p(14, 5, 1, 1, Color(0.06, 0.05, 0.1))
	_p(4, 9, 1, 3, skin)
	_p(15, 9, 1, 3, shade)
	_p(13, 6, 2, 10, shade)
	_p(5, 7, 1, 9, skin.lerp(rim, 0.45))
	# pelo
	match hair_style:
		"short":
			_p(5, 3, 10, 3, hair)
			_p(5, 6, 1, 2, hair)
			_p(14, 6, 1, 2, hair)
		"slick":
			_p(5, 3, 10, 2, hair)
			_p(4, 4, 2, 5, hair)
			_p(6, 3, 8, 1, hair.lightened(0.25))
		"long":
			_p(4, 3, 12, 3, hair)
			_p(4, 6, 2, 9, hair)
			_p(14, 6, 2, 9, hair)
		"mohawk":
			_p(8, 1, 4, 5, hair)
		"bald":
			_p(6, 4, 7, 1, skin.lightened(0.15))
	# cejas, ojos, nariz, boca
	var brow := hair.darkened(0.2) if hair_style != "bald" else shade.darkened(0.3)
	_p(6, 8, 3, 1, brow)
	_p(11, 8, 3, 1, brow)
	if sunglasses:
		_p(6, 9, 8, 2, Color(0.05, 0.05, 0.05))
		_p(6, 9, 3, 1, Color(0.35, 0.35, 0.45))
		_p(11, 9, 1, 1, Color(0.35, 0.35, 0.45))
	else:
		_p(6, 10, 3, 1, Color(0.95, 0.95, 0.95))
		_p(11, 10, 3, 1, Color(0.95, 0.95, 0.95))
		_p(7, 10, 1, 1, Color(0.1, 0.1, 0.1))
		_p(12, 10, 1, 1, Color(0.1, 0.1, 0.1))
	_p(9, 11, 2, 2, shade)
	_p(10, 12, 1, 1, shade.darkened(0.2))
	if beard:
		_p(6, 13, 8, 4, hair)
		_p(8, 13, 4, 1, hair.darkened(0.2))
	elif stubble:
		_p(6, 14, 8, 3, skin.lerp(hair, 0.35))
	_p(8, 14, 4, 1, Color(0.45, 0.12, 0.1))
	if scar:
		_p(12, 6, 1, 5, Color(0.75, 0.25, 0.25))
