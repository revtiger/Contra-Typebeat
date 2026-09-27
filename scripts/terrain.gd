extends Node2D
## Dibujo de un bloque de terreno: suelo de jungla o puente de madera.

var size := Vector2.ZERO
var one_way := false


func _draw() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.33, 0.17))
		for x in range(0, int(size.x), 8):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.2, 0.1))
		draw_rect(Rect2(0, 0, size.x, 2), Color(0.68, 0.5, 0.28))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.25, 0.16))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x)
	for i in int(size.x * size.y / 400.0):
		var p := Vector2(rng.randf() * size.x, 8 + rng.randf() * (size.y - 8))
		draw_rect(Rect2(p, Vector2(4, 3)), Color(0.28, 0.19, 0.12))
	draw_rect(Rect2(0, 0, size.x, 5), Color(0.2, 0.62, 0.2))
	for x in range(0, int(size.x), 6):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 3, -4), Vector2(x + 6, 0)]), Color(0.25, 0.72, 0.25))
	# cara lateral para que se note el borde en fosos y escalones
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.25, 0.17, 0.1))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.25, 0.17, 0.1))
