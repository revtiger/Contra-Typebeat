extends Area2D
## Proyectiles de Sergio Massa (massa.gd). Hacen daño al jugador al tocarlo.
##   bundle:  fajo de billetes lanzado en arco; al tocar el suelo se abre en billetes (flutter)
##   flutter: billete que salta y cae revoloteando
## (las granadas de Massa usan level.throw_grenade, como las de los soldados)

var kind := "bundle"
var vel := Vector2.ZERO
var harmless := false
var main
var t := 0.0
var life := 5.0
var spin := 0.0
var bundle_tex: Texture2D


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 5
	collision_layer = 0
	collision_mask = 0 if harmless else 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = {"bundle": 7.0, "flutter": 3.0}[kind]
	cs.shape = c
	add_child(cs)
	match kind:
		"bundle":
			bundle_tex = load("res://assets/sprites/boss_massa_bundle.png")
			spin = randf_range(6.0, 9.0) * signf(vel.x)
		"flutter":
			life = 3.0
			spin = randf_range(-6.0, 6.0)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	match kind:
		"bundle":
			vel.y += 420.0 * delta
			position += vel * delta
			rotation += spin * delta
			var gy: float = main.ground_y_at(position.x)
			if gy < 900.0 and position.y >= gy - 4.0 and vel.y > 0.0:
				_burst()
			elif position.y > 300.0:
				queue_free()
		"flutter":
			vel.y = minf(vel.y + 260.0 * delta, 45.0)
			vel.x = lerpf(vel.x, sin(t * 6.0) * 30.0, 2.0 * delta)
			position += vel * delta
			rotation = sin(t * 8.0) * 0.6
			var gy: float = main.ground_y_at(position.x)
			if gy < 900.0 and position.y >= gy - 2.0:
				queue_free()


## El fajo se abre en billetes que saltan y caen revoloteando.
func _burst() -> void:
	main.explode(position + Vector2(0, -4), 8.0, false)
	Game.sfx("small_boom", -10.0, 1.4)
	for i in 5:
		var s = get_script().new()
		s.kind = "flutter"
		s.position = position + Vector2(0, -6)
		s.vel = Vector2(randf_range(-70, 70), randf_range(-200, -120))
		# diferido: puede llamarse desde una señal de colisión, cuando Godot no deja crear áreas
		main.add_child.call_deferred(s)
	queue_free()


func _on_hit(other: Node) -> void:
	if harmless or is_queued_for_deletion():
		return
	if other.is_in_group("player"):
		other.hit()
		if kind == "bundle":
			_burst()
		else:
			queue_free()


func _draw() -> void:
	match kind:
		"bundle":
			if bundle_tex:
				draw_texture(bundle_tex, -bundle_tex.get_size() / 2.0)
		"flutter":
			var col := Color(0.95, 0.7, 0.8)
			draw_rect(Rect2(-5, -2.5, 10, 5), Color(0.1, 0.15, 0.1))
			draw_rect(Rect2(-4, -1.5, 8, 3), col)
			draw_rect(Rect2(-1, -1, 2, 2), col.darkened(0.4))
