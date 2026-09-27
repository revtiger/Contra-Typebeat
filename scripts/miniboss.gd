extends CharacterBody2D
## Mini jefe a mitad de misión. Al aparecer bloquea la cámara hasta que muere.
## comandante: soldado pesado con ametralladora (ráfaga a la altura del pecho: se esquiva tumbándose) y granadas.
## camion: camión lanzacohetes; los cohetes caen del cielo con aviso en el suelo y un artillero dispara desde atrás.

const Bullet = preload("res://scripts/bullet.gd")
const Bomb = preload("res://scripts/bomb.gd")
const TITLES := {"comandante": "COMANDANTE KRUGER", "camion": "CAMIÓN LANZACOHETES"}

var kind := "comandante"
var max_hp := 45
var hp := 45
var main
var t := 0.0
var attack_t := 2.0
var pattern := -1
var burst_left := 0
var burst_t := 0.0
var flash := 0.0
var dir := -1
var home_x := 0.0
var dead := false


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	var size := Vector2(18, 38) if kind == "comandante" else Vector2(64, 30)
	max_hp = 45 if kind == "comandante" else 60
	hp = max_hp
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(0, -size.y / 2)
	add_child(cs)
	home_x = position.x
	main.lock_camera(position.x - 400.0, TITLES[kind])


func _active() -> bool:
	return main.cam_left >= main.lock_left - 1.0


func _physics_process(delta: float) -> void:
	t += delta
	flash -= delta
	velocity.y += 900.0 * delta
	var p = main.player
	var dx: float = p.position.x - position.x
	if kind == "comandante":
		dir = 1 if dx > 0 else -1
		velocity.x = 0.0
		if _active() and burst_left == 0:
			if absf(dx) > 150.0 and position.x > home_x - 140.0:
				velocity.x = dir * 35.0
			elif absf(dx) < 90.0 and position.x < home_x:
				velocity.x = -dir * 35.0
	move_and_slide()
	if _active() and not p.dead:
		_attack(delta, p)
	queue_redraw()


func _attack(delta: float, p) -> void:
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_left -= 1
			if kind == "comandante":
				burst_t = 0.08
				_shoot(position + Vector2(dir * 16, -17), Vector2(dir, randf_range(-0.04, 0.04)).normalized() * 160.0)
			else:
				burst_t = 0.16
				var from := position + Vector2(-19, -44)
				_shoot(from, (p.position + Vector2(0, -12) - from).normalized() * 120.0)
		return
	attack_t -= delta
	if attack_t > 0.0:
		return
	pattern = (pattern + 1) % 3
	attack_t = lerpf(1.1, 1.9, float(hp) / max_hp)
	if kind == "comandante":
		match pattern:
			0:
				burst_left = 10
			1:
				for o in [0.0, -45.0]:
					_grenade(p.position.x + o)
			2:
				if is_on_floor():
					velocity.y = -300.0
				for a in [-0.25, 0.0, 0.25]:
					var from := position + Vector2(dir * 12, -22)
					_shoot(from, (p.position + Vector2(0, -12) - from).normalized().rotated(a) * 130.0)
	else:
		match pattern:
			0, 2:
				var offsets := [-50.0, 0.0, 50.0] if hp > max_hp / 2 else [-80.0, -40.0, 0.0, 40.0, 80.0]
				for o in offsets:
					var b := Bomb.new()
					b.target_x = p.position.x + o
					b.position = Vector2(p.position.x + o, -12)
					get_parent().add_child(b)
				main.explode(position + Vector2(8, -34), 8.0, false)
				Game.sfx("cannon", -4.0, 1.3)
			1:
				burst_left = 6


func _grenade(target_x: float) -> void:
	var from := position + Vector2(dir * 6, -34)
	var gy: float = main.ground_y_at(target_x)
	if gy > 900.0:
		gy = 262.0
	var vy := -230.0
	var g := 380.0
	var drop := gy - from.y
	var time := (-vy + sqrt(vy * vy + 2.0 * g * drop)) / g
	var b := Bomb.new()
	b.target_x = target_x
	b.vel = Vector2((target_x - from.x) / time, vy)
	b.position = from
	get_parent().add_child(b)


func _shoot(from: Vector2, v: Vector2) -> void:
	var b := Bullet.new()
	b.from_player = false
	b.life = 3.0
	b.vel = v
	b.position = from
	get_parent().add_child(b)
	Game.sfx("shot", -18.0, 0.6)


func take_damage(n: int) -> void:
	if dead or not _active():
		return
	hp -= n
	flash = 0.05
	Game.sfx("hit", -16.0, 0.8)
	if hp <= 0:
		dead = true
		main.add_score(5000)
		var h := 38.0 if kind == "comandante" else 30.0
		main.blast(position + Vector2(0, -h / 2), 40.0, false, 8)
		for i in 4:
			main.explode(position + Vector2(randf_range(-30, 30), randf_range(-h, 0)), randf_range(12, 22), i == 0)
		main.unlock_camera()
		queue_free()


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if dir > 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	var white := flash > 0.0
	if kind == "comandante":
		var green := Color.WHITE if white else Color(0.3, 0.38, 0.22)
		var skin := Color(0.85, 0.62, 0.48)
		_r(-8, -14, 7, 14, green.darkened(0.3))
		_r(1, -14, 7, 14, green.darkened(0.3))
		_r(-9, -30, 18, 17, green)
		_r(-9, -24, 18, 3, Color(0.2, 0.15, 0.1))
		_r(-5, -38, 10, 9, skin)
		_r(-6, -40, 12, 4, Color(0.7, 0.1, 0.1))
		_r(-5, -35, 9, 2, Color(0.05, 0.05, 0.05))
		_r(-12, -22, 6, 5, skin)
		# ametralladora
		_r(-30, -20, 22, 6, Color(0.25, 0.25, 0.28))
		var spin := int(t * 30.0) % 2
		_r(-34, -20 + spin, 5, 2, Color(0.4, 0.4, 0.45))
		_r(-34, -17 - spin, 5, 2, Color(0.4, 0.4, 0.45))
		if burst_left > 0 and int(t * 25.0) % 2 == 0:
			_r(-40, -20, 6, 6, Color(1, 0.8, 0.2))
	else:
		var body := Color.WHITE if white else Color(0.62, 0.52, 0.34)
		# cabina (izquierda) y plataforma
		_r(-32, -30, 20, 22, body)
		_r(-30, -27, 10, 8, Color(0.35, 0.55, 0.7))
		_r(-12, -18, 44, 10, body.darkened(0.15))
		_r(-34, -10, 68, 4, Color(0.2, 0.2, 0.2))
		# lanzacohetes inclinado
		var rack := PackedVector2Array([Vector2(-4, -18), Vector2(20, -18), Vector2(14, -36), Vector2(-10, -30)])
		draw_colored_polygon(rack, Color(0.35, 0.35, 0.3))
		for i in 3:
			draw_circle(Vector2(-6 + i * 7, -31 + i * 1.5), 2, Color(0.1, 0.1, 0.1))
		# artillero
		_r(-22, -44, 6, 8, Color(0.78, 0.66, 0.45))
		_r(-22, -48, 6, 4, Color(0.85, 0.62, 0.48))
		_r(-23, -50, 8, 2, Color(0.6, 0.2, 0.15))
		for x in [-24.0, 0.0, 22.0]:
			draw_circle(Vector2(x, -4), 5, Color(0.12, 0.12, 0.12))
			draw_circle(Vector2(x, -4), 2, Color(0.45, 0.45, 0.45))
	# vida
	var h := 46.0 if kind == "comandante" else 56.0
	draw_rect(Rect2(-24, -h - 4, 48, 3), Color(0.2, 0, 0))
	draw_rect(Rect2(-24, -h - 4, 48.0 * hp / max_hp, 3), Color(1, 0.3, 0.2))
