extends Node2D
## Puerta blindada al final de las fases 5.1 y 5.2 del nivel secreto (sin minijefes).
## Al llegar el jugador se abre y la fase termina. El origen está en el suelo, en el centro de la puerta.

const W := 56.0
const H := 90.0

var main
var number := 1
var open_t := -1.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("door")
	z_index = -1


func _physics_process(delta: float) -> void:
	if open_t < 0.0:
		if not main.player.dead and main.player.position.x > position.x - W:
			open_t = 0.0
			Game.sfx("cannon", -6.0, 0.5)
			main.shake(2.0)
	else:
		open_t += delta
		if open_t > 1.0 and main.state == "play":
			main.stage_clear()
	queue_redraw()


func _draw() -> void:
	var frame := Color(0.25, 0.27, 0.32)
	draw_rect(Rect2(-W / 2 - 8, -H - 10, W + 16, H + 10), frame)
	draw_rect(Rect2(-W / 2 - 8, -H - 10, W + 16, 4), Color(0.45, 0.48, 0.55))
	var k := clampf(open_t, 0.0, 1.0) if open_t >= 0.0 else 0.0
	draw_rect(Rect2(-W / 2, -H, W, H), Color(0.02, 0.02, 0.04))
	# dos hojas que se abren hacia los lados
	var leaf := W / 2.0 * (1.0 - k)
	var steel := Color(0.4, 0.43, 0.5)
	draw_rect(Rect2(-W / 2, -H, leaf, H), steel)
	draw_rect(Rect2(W / 2 - leaf, -H, leaf, H), steel)
	for y in range(int(-H) + 8, 0, 14):
		draw_line(Vector2(-W / 2, y), Vector2(-W / 2 + leaf, y), steel.darkened(0.3), 1)
		draw_line(Vector2(W / 2 - leaf, y), Vector2(W / 2, y), steel.darkened(0.3), 1)
	# franjas de peligro abajo
	for i in 7:
		draw_colored_polygon(PackedVector2Array([Vector2(-W / 2 - 8 + i * 10, 0), Vector2(-W / 2 - 2 + i * 10, 0),
			Vector2(-W / 2 + 4 + i * 10, -6), Vector2(-W / 2 - 2 + i * 10, -6)]), Color(0.95, 0.75, 0.1))
	# luz: roja cerrada, verde abierta
	var lit := Color(0.2, 1, 0.3) if open_t >= 0.0 else Color(1, 0.15, 0.1)
	draw_circle(Vector2(0, -H - 16), 4, lit)
	var font := preload("res://scripts/pixel_font.gd")
	var label := "PUERTA %d" % number
	draw_string(font.font("small"), Vector2(-W / 2, -H - 24), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font.size("small"))
