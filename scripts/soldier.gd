extends CharacterBody2D
## Soldado enemigo estilo Metal Slug.
## - "run": corre en línea recta y salta escalones; si te ve cerca a veces se asusta (brazos arriba) y huye
## - "sniper": se queda quieto y dispara al jugador en 8 direcciones
## - "grenadier": se para a lanzar granadas en arco (con marca de aviso en el suelo)
## Al morir sale despedido hacia atrás girando, en vez de desaparecer.

const Bullet = preload("res://scripts/bullet.gd")

const PANIC_TIME := 0.7

var mode := "run"
var dir := -1
var speed := 70.0
var hp := 1
var shoot_t := 1.2
var anim_t := 0.0
var main
var aim := Vector2.LEFT
var knifeable := true
var state := "normal"  # normal | panic | flee | dead
var state_t := 0.0
var flash := 0.0
var can_panic := true


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1 | 8
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	add_child(cs)
	can_panic = randf() < 0.45
	match mode:
		"sniper":
			hp = 2
			shoot_t = randf_range(0.6, 1.6)
		"grenadier":
			shoot_t = randf_range(0.8, 1.5)


func _physics_process(delta: float) -> void:
	anim_t += delta
	flash -= delta
	velocity.y += 900.0 * delta
	if state == "dead":
		_dead_process(delta)
		return
	var p = main.player
	var dx: float = p.position.x - position.x
	var on_screen: bool = position.x > main.cam_left and position.x < main.cam_left + 480
	match state:
		"panic":
			velocity.x = 0.0
			state_t -= delta
			if state_t <= 0.0:
				state = "flee"
				dir = -1 if dx > 0 else 1
		"flee":
			velocity.x = dir * 100.0
		_:
			match mode:
				"run":
					velocity.x = dir * speed
					if can_panic and absf(dx) < 80.0 and absf(p.position.y - position.y) < 30.0 and signf(dx) == float(dir) and is_on_floor():
						can_panic = false
						state = "panic"
						state_t = PANIC_TIME
						Game.sfx("beep", -18.0, 0.6)
				"sniper":
					velocity.x = 0.0
					var to: Vector2 = (p.position + Vector2(0, -14)) - (position + Vector2(0, -17))
					dir = 1 if to.x > 0 else -1
					aim = Vector2.from_angle(roundf(to.angle() / (PI / 4)) * (PI / 4))
					shoot_t -= delta
					if shoot_t <= 0.0 and on_screen and not p.dead:
						shoot_t = randf_range(1.3, 2.2)
						var b := Bullet.new()
						b.from_player = false
						b.vel = aim * 120.0
						b.position = position + Vector2(0, -17) + aim * 10
						get_parent().add_child(b)
						Game.sfx("shot", -20.0, 0.7)
				"grenadier":
					dir = 1 if dx > 0 else -1
					velocity.x = 0.0
					shoot_t -= delta
					if shoot_t <= 0.0 and on_screen and not p.dead and absf(dx) < 260.0:
						shoot_t = randf_range(2.2, 3.2)
						main.throw_grenade(position + Vector2(dir * 6, -24), p.position.x + randf_range(-10, 10))
	move_and_slide()
	if state == "normal" and mode == "run" and is_on_wall() and is_on_floor():
		velocity.y = -300.0
	if position.y > 320 or position.x < main.cam_left - 60 or position.x > main.cam_left + 560:
		queue_free()
	queue_redraw()


func _dead_process(delta: float) -> void:
	position += velocity * delta
	rotation += dir * -7.0 * delta
	state_t -= delta
	modulate.a = clampf(state_t / 0.3, 0.0, 1.0)
	if state_t <= 0.0:
		queue_free()
	queue_redraw()


func take_damage(n: int) -> void:
	if state == "dead":
		return
	hp -= n
	flash = 0.06
	if hp <= 0:
		main.add_score(200 if mode != "run" else 100)
		state = "dead"
		state_t = 0.8
		knifeable = false
		remove_from_group("enemy")
		collision_layer = 0
		collision_mask = 0
		var from_x: float = main.player.position.x
		dir = 1 if position.x > from_x else -1
		velocity = Vector2(dir * 90.0, -170.0)
		Game.sfx("death", -14.0, randf_range(1.7, 2.2))
		Juice.hitstop(0.03)


const UNIFORM := Color(0.45, 0.5, 0.35)
const HELMET := Color(0.3, 0.35, 0.25)
const SKIN := Color(0.85, 0.65, 0.5)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if dir < 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	var desert: bool = main.theme == "desert"
	var uniform := Color(0.78, 0.66, 0.45) if desert else UNIFORM
	var helmet := Color(0.6, 0.2, 0.15) if desert else HELMET
	var skin := SKIN
	if flash > 0.0:
		uniform = Color.WHITE
		skin = Color.WHITE
	var running := state == "flee" or (state == "normal" and mode == "run")
	var ph := sin(anim_t * (22.0 if state == "flee" else 16.0)) * 3.0 if running and is_on_floor() else 0.0
	_r(-4 + ph, -10, 4, 10, uniform.darkened(0.3))
	_r(0 - ph, -10, 4, 10, uniform.darkened(0.3))
	_r(-4, -20, 8, 11, uniform)
	_r(-3, -25, 7, 5, skin)
	_r(-4, -27, 9, 3, helmet)
	if desert:
		_r(-6, -26, 3, 5, helmet)
	match state:
		"panic", "dead":
			# brazos arriba y cara de susto
			_r(-6, -31, 2, 12, skin)
			_r(4, -31, 2, 12, skin)
			_r(1, -23, 2, 2, Color(0.1, 0.1, 0.1))
			if state == "panic":
				draw_string(ThemeDB.fallback_font, Vector2(-3, -34), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.9, 0.2))
		"flee":
			_r(-7, -21, 4, 2, skin)
		_:
			if mode == "sniper":
				var sh := Vector2(0, -17)
				draw_line(sh, sh + aim * 11, Color(0.2, 0.2, 0.2), 2)
			elif mode == "grenadier":
				var k := clampf(1.0 - shoot_t, 0.0, 1.0)
				_r(-2, -22 - k * 6, 3, 8, skin)
				_r(-2, -24 - k * 6, 3, 3, Color(0.25, 0.32, 0.2))
			else:
				_r(3, -17, 5, 2, Color(0.2, 0.2, 0.2))
