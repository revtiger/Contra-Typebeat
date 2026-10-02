extends Node2D
## Bombardeo aéreo: un caza cruza la pantalla de derecha a izquierda y suelta bombas
## sobre la zona del jugador. Las marcas rojas del suelo avisan de dónde caerán.

const Bomb = preload("res://scripts/bomb.gd")
const SPEED := 230.0
const OFFSETS := [70.0, 25.0, -20.0, -65.0]

var main
var t := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 3
	Game.sfx("jet", -2.0)
	var px: float = main.player.position.x
	for o in OFFSETS:
		var b := Bomb.new()
		b.jet = self
		b.target_x = px + o
		b.position = Vector2(px + o, 0)
		get_parent().add_child.call_deferred(b)


func _physics_process(delta: float) -> void:
	t += delta
	position.x -= SPEED * delta
	if position.x < main.cam_left - 80:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var body := Color(0.45, 0.48, 0.52)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, 0), Vector2(-12, -4), Vector2(18, -4), Vector2(24, -12), Vector2(28, -12),
		Vector2(26, 0), Vector2(18, 3), Vector2(-14, 3)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 0), Vector2(12, 0), Vector2(18, 10), Vector2(10, 10)]), body.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -3), Vector2(-6, -7), Vector2(0, -4)]), Color(0.4, 0.7, 0.9))
	var f := 4.0 + sin(t * 60.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(27, -3), Vector2(27 + f * 2, -1), Vector2(27, 1)]), Color(1, 0.6, 0.1))
