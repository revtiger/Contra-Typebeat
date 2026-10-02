extends Area2D
## Granada del jugador: sale en arco, rebota una vez en el suelo y explota al segundo toque
## o al chocar con un enemigo. No daña al jugador.

var vel := Vector2.ZERO
var bounced := false
var t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	collision_layer = 0
	collision_mask = 4 | 16
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 4.0
	cs.shape = c
	add_child(cs)
	z_index = 5
	body_entered.connect(func(_b): _explode())
	area_entered.connect(func(_a): _explode())


func _physics_process(delta: float) -> void:
	t += delta
	vel.y += 600.0 * delta
	position += vel * delta
	rotation += vel.x * 0.05 * delta
	var gy: float = main.ground_y_at(position.x)
	if position.y >= gy - 3.0:
		if bounced:
			_explode()
			return
		bounced = true
		position.y = gy - 3.0
		vel = Vector2(vel.x * 0.55, -absf(vel.y) * 0.4)
		Game.sfx("hit", -14.0, 0.5)
	if position.y > 300.0:
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
