extends Area2D
## Bala del jugador o enemiga. Atraviesa los puentes, choca con el suelo sólido.

var vel := Vector2.ZERO
var from_player := true
var life := 1.6


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 | 4) if from_player else (1 | 2)
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 2.0 if from_player else 2.5
	cs.shape = c
	add_child(cs)
	z_index = 5
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_hit(other: Node) -> void:
	if is_queued_for_deletion():
		return
	if from_player:
		if other.has_method("take_damage"):
			other.take_damage(1)
	elif other.is_in_group("player"):
		other.hit()
	queue_free()


func _draw() -> void:
	if from_player:
		draw_circle(Vector2.ZERO, 2.5, Color(1, 0.3, 0.2))
		draw_circle(Vector2.ZERO, 1.5, Color(1, 1, 0.8))
	else:
		draw_circle(Vector2.ZERO, 2.5, Color(1, 0.55, 0.1))
		draw_circle(Vector2.ZERO, 1.2, Color(1, 1, 1))
