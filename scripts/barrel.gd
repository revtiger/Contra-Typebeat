extends StaticBody2D
## Barril explosivo: al dispararle estalla y daña todo lo cercano (también a otros barriles: reacción en cadena).

var hp := 2
var flash := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("prop")
	collision_layer = 16
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 16)
	cs.shape = r
	cs.position = Vector2(0, -8)
	add_child(cs)


func _physics_process(delta: float) -> void:
	if flash > 0.0:
		flash -= delta
		queue_redraw()
	if position.x < main.cam_left - 60:
		queue_free()


func take_damage(n: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= n
	flash = 0.06
	queue_redraw()
	if hp <= 0:
		main.add_score(50)
		main.blast(position + Vector2(0, -8), 38.0, true, 6)
		queue_free()


func _draw() -> void:
	var red := Color.WHITE if flash > 0.0 else Color(0.8, 0.15, 0.1)
	draw_rect(Rect2(-6, -16, 12, 16), red)
	draw_rect(Rect2(-6, -13, 12, 2), red.darkened(0.4))
	draw_rect(Rect2(-6, -5, 12, 2), red.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -11), Vector2(3, -6), Vector2(-3, -6)]), Color(1, 0.85, 0.1))
	draw_rect(Rect2(-5, -16, 10, 1), Color(1, 1, 1, 0.3))
