extends Area2D
## Bala del jugador o enemiga. Atraviesa los puentes y choca con el suelo sólido.
## kind: normal | laser (atraviesa enemigos) | fire (avanza en espiral) | shell (obús de tanque)

var vel := Vector2.ZERO
var from_player := true
var kind := "normal"
var damage := 1
var pierce := false
var life := 1.6
var t := 0.0
var base := Vector2.ZERO
var _hit := []


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 | 4 | 16) if from_player else (1 | 2)
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = {"laser": 3.0, "fire": 4.0, "shell": 3.0}.get(kind, 2.0 if from_player else 2.5)
	cs.shape = c
	add_child(cs)
	z_index = 5
	base = position
	if kind == "laser":
		rotation = vel.angle()
	if kind == "shell":
		life = 4.0
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	t += delta
	base += vel * delta
	position = base
	if kind == "fire":
		position += vel.orthogonal().normalized() * sin(t * 22.0) * 7.0
	life -= delta
	if life <= 0.0:
		queue_free()
	if kind == "fire":
		queue_redraw()


func _on_hit(other: Node) -> void:
	if is_queued_for_deletion() or other in _hit:
		return
	if from_player:
		if other.has_method("take_damage"):
			other.take_damage(damage)
			if pierce:
				_hit.append(other)
				return
	elif other.is_in_group("player"):
		other.hit()
	queue_free()


func _draw() -> void:
	match kind:
		"laser":
			draw_line(Vector2(-14, 0), Vector2(4, 0), Color(0.3, 0.9, 1.0), 4)
			draw_line(Vector2(-12, 0), Vector2(3, 0), Color(1, 1, 1), 2)
		"fire":
			var k := 0.5 + 0.5 * sin(t * 30.0)
			draw_circle(Vector2.ZERO, 4.5, Color(1, 0.35, 0.05))
			draw_circle(Vector2.ZERO, 2.5 + k, Color(1, 0.85, 0.2))
		"shell":
			draw_circle(Vector2.ZERO, 3.5, Color(0.25, 0.22, 0.2))
			draw_circle(Vector2(-signf(vel.x) * 3, 0), 2.0, Color(1, 0.6, 0.1))
		_:
			if from_player:
				draw_circle(Vector2.ZERO, 2.5, Color(1, 0.3, 0.2))
				draw_circle(Vector2.ZERO, 1.5, Color(1, 1, 0.8))
			else:
				draw_circle(Vector2.ZERO, 2.5, Color(1, 0.55, 0.1))
				draw_circle(Vector2.ZERO, 1.2, Color(1, 1, 1))
