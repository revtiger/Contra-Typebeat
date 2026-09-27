extends CharacterBody2D
## Soldado enemigo estilo Metal Slug.
## - "run": corre en línea recta y salta escalones; si te ve cerca a veces se asusta (brazos arriba) y huye
## - "sniper": se queda quieto y dispara al jugador en 8 direcciones
## - "grenadier": se para a lanzar granadas en arco (con marca de aviso en el suelo)
## Al morir sale despedido hacia atrás girando, en vez de desaparecer.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")

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
var spr: AnimatedSprite2D


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1 | 8
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 28)
	cs.shape = r
	cs.position = Vector2(0, -14)
	add_child(cs)
	can_panic = randf() < 0.45
	_setup_sprite()
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
		_animate()
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
						b.position = position + Vector2(0, -22) + aim * 14
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
	_animate()


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


# ---------- sprites (assets/sprites/soldier_*.png, generados por tools/sprites/humans.py) ----------

func _setup_sprite() -> void:
	var meta := SpriteUtil.meta("res://assets/sprites/soldier_meta.json")
	var R: Dictionary = meta["rows"]
	var theme_name: String = "desert" if main.theme == "desert" else "jungle"
	spr = SpriteUtil.sprite(SpriteUtil.frames("res://assets/sprites/soldier_%s.png" % theme_name, 48, 48, {
		"idle": [R["idle"], 1, 1, true], "run": [R["run"], 8, 14, true], "panic": [R["panic"], 2, 6, true],
		"throw": [R["throw"], 2, 1, false], "aim": [R["aim"], 4, 1, false], "flee": [R["flee"], 8, 18, true]}),
		SpriteUtil.v(meta["feet"]))
	add_child(spr)


func _animate() -> void:
	spr.scale.x = dir
	spr.modulate = Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	match state:
		"panic":
			_play("panic")
		"flee":
			_play("flee")
		"dead":
			spr.animation = "panic"
			spr.frame = 1
		_:
			match mode:
				"run":
					_play("run" if is_on_floor() else "idle")
				"sniper":
					# fotogramas: adelante, diagonal arriba, arriba, diagonal abajo
					var ang := rad_to_deg(Vector2(absf(aim.x), aim.y).angle())
					var idx := 0
					if ang < -67.0:
						idx = 2
					elif ang < -22.0:
						idx = 1
					elif ang > 22.0:
						idx = 3
					spr.animation = "aim"
					spr.frame = idx
				"grenadier":
					if shoot_t < 0.5:
						spr.animation = "throw"
						spr.frame = 0
					elif shoot_t > 1.9:
						spr.animation = "throw"
						spr.frame = 1
					else:
						spr.animation = "idle"


func _play(anim: String) -> void:
	if spr.animation != anim or not spr.is_playing():
		spr.play(anim)
