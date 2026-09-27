extends Area2D
## Bala del jugador o enemiga. Atraviesa los puentes y choca con el suelo sólido.
## Tipos del jugador: normal (pistola), heavy (ametralladora H), rocket (R: busca al enemigo más cercano
## y explota), flame (F: llamarada que crece y atraviesa), laser (L: atraviesa), shotgun (S: abanico corto).
## Tipos enemigos: normal y shell (obús de tanque).

var vel := Vector2.ZERO
var from_player := true
var kind := "normal"
var damage := 1
var pierce := false
var life := 1.6
var t := 0.0
var base := Vector2.ZERO
var main
var _hit := []

const RADIUS := {"laser": 3.0, "fire": 4.0, "shell": 3.0, "flame": 7.0, "shotgun": 5.0, "rocket": 3.0, "heavy": 2.5}


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	collision_layer = 0
	collision_mask = (1 | 4 | 16) if from_player else (1 | 2)
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS.get(kind, 2.0 if from_player else 2.5)
	cs.shape = c
	add_child(cs)
	z_index = 5
	base = position
	rotation = vel.angle() if kind in ["laser", "heavy", "rocket"] else 0.0
	if kind == "shell":
		life = 4.0
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	t += delta
	if kind == "rocket":
		_steer(delta)
	base += vel * delta
	position = base
	if kind == "fire":
		position += vel.orthogonal().normalized() * sin(t * 22.0) * 7.0
	life -= delta
	if life <= 0.0:
		queue_free()
	if kind in ["fire", "flame", "shotgun", "rocket"]:
		queue_redraw()


## El cohete gira hacia el enemigo más cercano que tenga delante y acelera.
func _steer(delta: float) -> void:
	var best = null
	var best_d := 220.0
	for n in get_tree().get_nodes_in_group("enemy"):
		var target: Vector2 = n.global_position + Vector2(0, -10)
		var d := position.distance_to(target)
		if d < best_d and vel.dot(target - position) > 0.0:
			best = target
			best_d = d
	if best != null:
		var ang := vel.angle_to(best - position)
		vel = vel.rotated(clampf(ang, -4.0 * delta, 4.0 * delta))
	vel = vel.normalized() * minf(vel.length() + 400.0 * delta, 330.0)
	rotation = vel.angle()


func _on_hit(other: Node) -> void:
	if is_queued_for_deletion() or other in _hit:
		return
	if kind == "rocket":
		# daño directo al blanco (los jefes grandes quedan fuera del radio) y explosión alrededor
		if other.has_method("take_damage"):
			other.take_damage(4)
		main.blast(position, 20.0, false, 3)
		queue_free()
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
		"heavy":
			draw_line(Vector2(-7, 0), Vector2(3, 0), Color(1, 0.75, 0.2), 3)
			draw_line(Vector2(-4, 0), Vector2(3, 0), Color(1, 1, 0.8), 1)
		"rocket":
			draw_rect(Rect2(-5, -2, 9, 4), Color(0.4, 0.45, 0.35))
			draw_colored_polygon(PackedVector2Array([Vector2(4, -2), Vector2(7, 0), Vector2(4, 2)]), Color(0.8, 0.2, 0.15))
			var f := 4.0 + sin(t * 60.0) * 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(-5, -2), Vector2(-5 - f, 0), Vector2(-5, 2)]), Color(1, 0.7, 0.2))
			for i in 3:
				var k := fmod(t * 3.0 + i / 3.0, 1.0)
				draw_circle(Vector2(-8 - k * 18, 0), 1.5 + k * 3.0, Color(0.7, 0.7, 0.7, 0.5 * (1.0 - k)))
		"flame":
			var g := 1.0 + t * 2.5
			draw_circle(Vector2.ZERO, 6.0 * g, Color(1, 0.3, 0.05, 0.8))
			draw_circle(Vector2(1, -1), 4.0 * g, Color(1, 0.7, 0.15, 0.9))
			draw_circle(Vector2(1, -1), 2.0 * g, Color(1, 1, 0.7))
		"shotgun":
			var a := 1.0 - t / 0.22
			draw_circle(Vector2.ZERO, 4.0, Color(1, 0.9, 0.5, a))
			draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, a))
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
