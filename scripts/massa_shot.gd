extends Area2D
## Billete que se le cae a Sergio Massa (massa.gd) de los bolsillos al perder: salta y cae revoloteando.
## Es decorado (harmless = true); si no, haría daño al jugador al tocarlo.
## (las granadas de Massa usan level.throw_grenade, como las de los soldados)

var kind := "flutter"
var vel := Vector2.ZERO
var harmless := false
var main
var t := 0.0
var life := 3.0
var spin := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 5
	collision_layer = 0
	collision_mask = 0 if harmless else 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	cs.shape = c
	add_child(cs)
	spin = randf_range(-6.0, 6.0)
	# billetes de distintos colores
	modulate = [Color.WHITE, Color(0.75, 1.0, 0.8), Color(1.0, 0.95, 0.7)][randi() % 3]
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	vel.y = minf(vel.y + 260.0 * delta, 45.0)
	vel.x = lerpf(vel.x, sin(t * 6.0 + spin) * 30.0, 2.0 * delta)
	position += vel * delta
	rotation = sin(t * 8.0 + spin) * 0.6
	var gy: float = main.ground_y_at(position.x)
	if gy < 900.0 and position.y >= gy - 2.0:
		queue_free()


func _on_hit(other: Node) -> void:
	if harmless or is_queued_for_deletion():
		return
	if other.is_in_group("player"):
		other.hit()
		queue_free()


func _draw() -> void:
	var col := Color(0.95, 0.7, 0.8)
	draw_rect(Rect2(-5, -2.5, 10, 5), Color(0.1, 0.15, 0.1))
	draw_rect(Rect2(-4, -1.5, 8, 3), col)
	draw_rect(Rect2(-1, -1, 2, 2), col.darkened(0.4))
