extends Node2D
## Dibujo de un bloque de terreno según el tema: suelo (jungla o arena) o puente/saliente.

var size := Vector2.ZERO
var one_way := false
var theme := "jungle"

const PUEBLO_GROUND := preload("res://assets/sprites/ground_pueblo.png")


func _draw() -> void:
	var desert := theme == "desert"
	if theme == "city":
		_draw_city()
		return
	if theme == "base":
		_draw_base()
		return
	if theme == "snow":
		_draw_snow()
		return
	if theme == "pueblo":
		_draw_pueblo()
		return
	if one_way:
		if desert:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.42, 0.34))
			draw_rect(Rect2(0, 0, size.x, 2), Color(0.75, 0.62, 0.5))
			draw_rect(Rect2(0, size.y - 2, size.x, 2), Color(0.38, 0.28, 0.22))
			for x in range(4, int(size.x), 11):
				draw_rect(Rect2(x, 3, 3, 2), Color(0.45, 0.33, 0.27))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.33, 0.17))
			for x in range(0, int(size.x), 8):
				draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.2, 0.1))
			draw_rect(Rect2(0, 0, size.x, 2), Color(0.68, 0.5, 0.28))
		return
	var body := Color(0.72, 0.45, 0.28) if desert else Color(0.36, 0.25, 0.16)
	var spot := Color(0.62, 0.36, 0.22) if desert else Color(0.28, 0.19, 0.12)
	var top := Color(0.93, 0.78, 0.5) if desert else Color(0.2, 0.62, 0.2)
	var edge := body.darkened(0.3)
	draw_rect(Rect2(Vector2.ZERO, size), body)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x)
	if desert:
		for y in range(14, int(size.y), 12):
			draw_line(Vector2(0, y), Vector2(size.x, y + rng.randf_range(-2, 2)), spot, 2)
	for i in int(size.x * size.y / 400.0):
		var p := Vector2(rng.randf() * size.x, 8 + rng.randf() * (size.y - 8))
		draw_rect(Rect2(p, Vector2(4, 3)), spot)
	draw_rect(Rect2(0, 0, size.x, 5), top)
	if desert:
		for x in range(0, int(size.x), 9):
			draw_rect(Rect2(x + rng.randf() * 4, 5, 3, 1), top.darkened(0.15))
	else:
		for x in range(0, int(size.x), 6):
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 3, -4), Vector2(x + 6, 0)]), Color(0.25, 0.72, 0.25))
	# caras laterales para que se note el borde en fosos y escalones
	draw_rect(Rect2(0, 0, 2, size.y), edge)
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), edge)


## Pueblo de la pampa: calle de adoquines con tierra y pasto (tira de ground_pueblo.png, sacada de
## las ilustraciones); los puentes son tablones de madera vieja.
func _draw_pueblo() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.27, 0.15))
		for x in range(0, int(size.x), 10):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.24, 0.15, 0.09))
			draw_rect(Rect2(x + 2, 3, 1, 1), Color(0.2, 0.12, 0.08))
		draw_rect(Rect2(0, 0, size.x, 2), Color(0.66, 0.46, 0.26))
		draw_rect(Rect2(0, size.y - 1, size.x, 1), Color(0.2, 0.12, 0.08))
		return
	var tw := float(PUEBLO_GROUND.get_width())
	var th := float(PUEBLO_GROUND.get_height())
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.17, 0.11, 0.07))
	# la tira se alinea con la x del mundo para que no se note el corte entre bloques
	var x := -fposmod(global_position.x, tw)
	while x < size.x:
		var sx := maxf(0.0, -x)
		var w := minf(tw - sx, size.x - maxf(x, 0.0))
		draw_texture_rect_region(PUEBLO_GROUND, Rect2(maxf(x, 0.0), -3, w, th), Rect2(sx, 0, w, th))
		x += tw
	draw_rect(Rect2(0, th - 3, size.x, 2), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.12, 0.08, 0.05))


## Ciudad: asfalto con bordillo y hormigón agrietado; los puentes son vigas de acero.
func _draw_city() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.2, 0.12))
		draw_rect(Rect2(0, 0, size.x, 2), Color(0.75, 0.32, 0.2))
		draw_rect(Rect2(0, size.y - 2, size.x, 2), Color(0.35, 0.12, 0.08))
		for x in range(6, int(size.x) - 4, 12):
			draw_circle(Vector2(x, size.y / 2.0), 1.2, Color(0.3, 0.1, 0.06))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x) + 7
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.33, 0.32))
	for i in int(size.x * size.y / 300.0):
		var p := Vector2(rng.randf() * size.x, 10 + rng.randf() * (size.y - 10))
		draw_rect(Rect2(p, Vector2(3, 2)), Color(0.28, 0.26, 0.26))
	for i in int(size.x / 60.0):
		var cx := rng.randf() * size.x
		draw_line(Vector2(cx, 8), Vector2(cx + rng.randf_range(-8, 8), 8 + rng.randf_range(10, 30)), Color(0.2, 0.18, 0.18), 1)
	draw_rect(Rect2(0, 0, size.x, 6), Color(0.18, 0.18, 0.2))
	draw_rect(Rect2(0, 0, size.x, 1), Color(0.45, 0.45, 0.48))
	for x in range(10, int(size.x) - 12, 40):
		draw_rect(Rect2(x, 2, 16, 1), Color(0.9, 0.75, 0.2))
	# escombros sobre el asfalto
	for i in int(size.x / 90.0):
		var rx := rng.randf() * size.x
		draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 3, -4), Vector2(rx + 7, -2), Vector2(rx + 9, 0)]), Color(0.3, 0.27, 0.26))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.22, 0.2, 0.2))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.22, 0.2, 0.2))


## Nieve (Alemania): roca oscura con una capa de nieve; los puentes son tablones nevados.
func _draw_snow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x) + 3
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.32, 0.22))
		for x in range(0, int(size.x), 8):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.2, 0.14))
		draw_rect(Rect2(0, -2, size.x, 3), Color(0.95, 0.97, 1.0))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.36))
	for i in int(size.x * size.y / 400.0):
		draw_rect(Rect2(Vector2(rng.randf() * size.x, 10 + rng.randf() * (size.y - 10)), Vector2(4, 3)), Color(0.24, 0.24, 0.3))
	draw_rect(Rect2(0, 0, size.x, 7), Color(0.95, 0.97, 1.0))
	for x in range(0, int(size.x), 7):
		draw_rect(Rect2(x, 7, 4, 2 + rng.randi() % 3), Color(0.95, 0.97, 1.0))
	draw_rect(Rect2(0, 0, size.x, 1), Color(1, 1, 1))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.2, 0.2, 0.25))


## Base secreta (ONU): suelo de placas de acero con franjas de peligro; los puentes son rejillas.
func _draw_base() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.28, 0.34))
		for x in range(2, int(size.x) - 2, 4):
			draw_line(Vector2(x, 1), Vector2(x, size.y - 1), Color(0.12, 0.13, 0.16), 1)
		draw_rect(Rect2(0, 0, size.x, 1), Color(0.5, 0.55, 0.62))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.22, 0.27))
	for x in range(0, int(size.x), 32):
		draw_rect(Rect2(x, 0, 31, 8), Color(0.34, 0.37, 0.43))
		draw_rect(Rect2(x, 0, 31, 1), Color(0.5, 0.54, 0.6))
		draw_circle(Vector2(x + 3, 4), 1, Color(0.2, 0.22, 0.27))
		draw_circle(Vector2(x + 28, 4), 1, Color(0.2, 0.22, 0.27))
	for x in range(0, int(size.x), 12):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 8), Vector2(x + 6, 8), Vector2(x + 2, 13), Vector2(x - 4, 13)]), Color(0.9, 0.7, 0.1))
	for y in range(24, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.15, 0.16, 0.2), 1)
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.12, 0.13, 0.16))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.12, 0.13, 0.16))
