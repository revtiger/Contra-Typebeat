extends CharacterBody2D
## Soldado enemigo estilo Metal Slug.
## - "run": corre en línea recta y salta escalones; si te ve cerca a veces se asusta (brazos arriba) y huye
## - "sniper": se queda quieto y dispara al jugador en 8 direcciones
## - "grenadier": se para a lanzar granadas en arco (con marca de aviso en el suelo)
## Al morir sale despedido hacia atrás girando, en vez de desaparecer. En Argentina (soldier_ar.png, de
## tools/sprites/soldados.py) recibe el disparo, cae de espaldas y queda tirado en el suelo un momento.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")

const PANIC_TIME := 0.7
const AR_CARAS := 4  # variantes de cara de soldier_ar.png

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
## hoja nueva de Argentina: tiene la muerte en 3 poses ("die") y la boca del fusil de cada pose de apuntar
var ar := false
var ar_meta := {}


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
	if ar:
		# el soldado de Argentina mide como el héroe: caja más alta para que las balas le den en la cabeza
		r.size = Vector2(14, 40)
		cs.position = Vector2(0, -20)
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
						if ar:
							var m: Array = ar_meta["muzzles"][_aim_idx()]
							b.position = position + Vector2(m[0] * dir, m[1])
						get_parent().add_child(b)
						Game.sfx("shot", -20.0, 0.7)
				"grenadier":
					dir = 1 if dx > 0 else -1
					velocity.x = 0.0
					shoot_t -= delta
					if shoot_t <= 0.0 and on_screen and not p.dead and absf(dx) < 260.0:
						shoot_t = randf_range(2.2, 3.2)
						var hand := Vector2(dir * 6, -24)
						if ar:
							hand = Vector2(ar_meta["hand"][0] * dir, ar_meta["hand"][1])
						main.throw_grenade(position + hand, p.position.x + randf_range(-10, 10))
	move_and_slide()
	if state == "normal" and mode == "run" and is_on_wall() and is_on_floor():
		velocity.y = -300.0
	if position.y > 320 or position.x < main.cam_left - 60 or position.x > main.cam_left + 560:
		queue_free()
	_animate()


func _dead_process(delta: float) -> void:
	if ar:
		# cae de espaldas y queda tirado; al final se desvanece
		velocity.x = move_toward(velocity.x, 0.0, 160.0 * delta)
		position += velocity * delta
		var gy: float = main.ground_y_at(position.x) if main.has_method("ground_y_at") else 230.0
		if position.y >= gy:
			position.y = gy
			velocity = Vector2.ZERO
		state_t -= delta
		modulate.a = clampf(state_t / 0.4, 0.0, 1.0)
		if state_t <= 0.0:
			queue_free()
		return
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
		if ar:
			velocity = Vector2(dir * 70.0, -110.0)
			state_t = 1.6
		Game.sfx("death", -14.0, randf_range(1.7, 2.2))
		Juice.hitstop(0.03)


# ---------- sprites (assets/sprites/soldier_*.png, generados por tools/sprites/humans.py) ----------

func _setup_sprite() -> void:
	if main.get("country") == "ar" and ResourceLoader.exists("res://assets/sprites/soldier_ar.png"):
		ar = true
		ar_meta = SpriteUtil.meta("res://assets/sprites/soldier_ar_meta.json")
		var A: Dictionary = ar_meta["rows"]
		var fr: Array = ar_meta["frame"]
		# cara al azar: el soldado joven (soldier_ar.png) o una de sus variantes (soldier_ar_1..4.png: bigote,
		# moreno, canoso con barba, pelirrojo), pintadas por tools/sprites/soldados.py caras
		var cara := randi() % (AR_CARAS + 1)
		var hoja := "res://assets/sprites/soldier_ar.png" if cara == 0 else "res://assets/sprites/soldier_ar_%d.png" % cara
		spr = SpriteUtil.sprite(SpriteUtil.frames(hoja, fr[0], fr[1], {
			"idle": [A["idle"], 1, 1, true], "run": [A["run"], 8, 14, true], "panic": [A["panic"], 2, 6, true],
			"throw": [A["throw"], 2, 1, false], "aim": [A["aim"], 4, 1, false], "flee": [A["flee"], 8, 18, true],
			"die": [A["die"], 3, 1, false]}),
			SpriteUtil.v(ar_meta["feet"]))
		add_child(spr)
		return
	var meta := SpriteUtil.meta("res://assets/sprites/soldier_meta.json")
	var R: Dictionary = meta["rows"]
	var theme_name: String = "desert" if main.theme in ["desert", "quebrada"] else "jungle"
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
			if ar:
				# mira al jugador y cae de espaldas: recibe el disparo, cae y queda tirado
				spr.scale.x = -dir
				spr.animation = "die"
				spr.frame = 0 if state_t > 1.45 else (1 if velocity.y != 0.0 else 2)
			else:
				spr.animation = "panic"
				spr.frame = 1
		_:
			match mode:
				"run":
					_play("run" if is_on_floor() else "idle")
				"sniper":
					spr.animation = "aim"
					spr.frame = _aim_idx()
				"grenadier":
					if shoot_t < 0.5:
						spr.animation = "throw"
						spr.frame = 0
					elif shoot_t > 1.9:
						spr.animation = "throw"
						spr.frame = 1
					else:
						spr.animation = "idle"


## Fotograma de apuntar: 0 adelante, 1 diagonal arriba, 2 arriba, 3 diagonal abajo.
func _aim_idx() -> int:
	var ang := rad_to_deg(Vector2(absf(aim.x), aim.y).angle())
	if ang < -67.0:
		return 2
	if ang < -22.0:
		return 1
	if ang > 22.0:
		return 3
	return 0


func _play(anim: String) -> void:
	if spr.animation != anim or not spr.is_playing():
		spr.play(anim)
