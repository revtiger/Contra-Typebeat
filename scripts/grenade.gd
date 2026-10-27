extends Area2D
## Granada del jugador: sale en arco y explota solo al tocar el Terreno (25-10-2026: sin rebote y sin explotar al
## chocar con enemigos; la explosión daña lo que haya cerca). No daña al jugador.

var vel := Vector2.ZERO
var t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	collision_layer = 8  # HitboxJugador
	collision_mask = 0  # no choca con nada: el Terreno lo consulta level.touches_terrain()
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 4.0
	cs.shape = c
	add_child(cs)
	z_index = 5


func _physics_process(delta: float) -> void:
	t += delta
	vel.y += 938.0 * delta  # 600 × 1,25² (granada más rápida con el mismo arco)
	position += vel * delta
	rotation += vel.x * 0.05 * delta
	if main.touches_terrain(position + Vector2(0, 3), vel.y < 0.0):
		_explode()
		return
	if position.y > main.cam_y + 300.0:
		queue_free()
	queue_redraw()


func _explode() -> void:
	if is_queued_for_deletion():
		return
	main.blast(position, 32.0, false, 6)
	Juice.hitstop(0.04)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.5, Color(0.25, 0.32, 0.2))
	draw_rect(Rect2(-1.5, -5.5, 3, 2), Color(0.5, 0.5, 0.5))
	if int(t * 10.0) % 2 == 0:
		draw_circle(Vector2(0, -6), 1.2, Color(1, 0.7, 0.2))
