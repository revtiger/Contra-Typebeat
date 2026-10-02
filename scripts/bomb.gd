extends Node2D
## Bomba que cae (del caza o del helicóptero). Mientras tanto dibuja una marca de aviso en el suelo.
## Si jet es null, cae desde su posición inicial en cuanto aparece.

var main
var jet = null
var target_x := 0.0
var falling := false
var vel := Vector2.ZERO
var ground_y := 262.0
var t := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 6
	var gy: float = main.ground_y_at(target_x)
	ground_y = gy if gy < 900.0 else 262.0
	if jet == null:
		_start_fall(position)


func _start_fall(from: Vector2) -> void:
	falling = true
	position = from
	Game.sfx("whistle", -12.0, randf_range(0.9, 1.1))


func _physics_process(delta: float) -> void:
	t += delta
	if not falling:
		if not is_instance_valid(jet):
			queue_free()
			return
		if jet.position.x <= target_x:
			_start_fall(Vector2(target_x, jet.position.y + 6))
	else:
		vel.y += 380.0 * delta
		position += vel * delta
		if position.y >= ground_y - 3.0:
			main.blast(Vector2(position.x, ground_y - 4.0), 26.0, true)
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	if int(t * 8.0) % 2 == 0:
		var m := to_local(Vector2(target_x, ground_y - 2.0))
		draw_colored_polygon(PackedVector2Array([m + Vector2(-6, 0), m + Vector2(6, 0), m + Vector2(0, -10)]), Color(1, 0.15, 0.1))
		draw_rect(Rect2(m + Vector2(-0.5, -7), Vector2(1.5, 4)), Color.WHITE)
		draw_rect(Rect2(m + Vector2(-0.5, -2), Vector2(1.5, 1)), Color.WHITE)
	if falling:
		draw_circle(Vector2.ZERO, 3.5, Color(0.2, 0.22, 0.2))
		draw_rect(Rect2(-3, -8, 6, 5), Color(0.2, 0.22, 0.2))
		draw_line(Vector2(-3, -8), Vector2(3, -8), Color(0.6, 0.1, 0.1), 1)
