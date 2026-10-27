extends CharacterBody2D
## Soldado enemigo estilo Metal Slug.
## - "run": corre en línea recta y salta escalones; si te ve cerca a veces se asusta (brazos arriba) y huye
## - "sniper": se queda quieto y dispara al jugador en 8 direcciones
## - "grenadier": se para a lanzar granadas en arco (con marca de aviso en el suelo)
## Al morir sale despedido hacia atrás girando, en vez de desaparecer. En Argentina (soldier_ar.png, de
## tools/sprites/soldados.py) recibe el disparo, cae de espaldas y queda tirado en el suelo un momento.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Sangre = preload("res://scripts/sangre.gd")

const PANIC_TIME := 0.7
const THROW_FPS := 14.0  # lanzamiento de granada del soldado de Argentina (prepara, lanza y vuelve)
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
## disparo del francotirador: fogonazo en la boca del fusil y culatazo (el sprite retrocede 1 px)
var fire_t := 0.0
var fx := Node2D.new()
## lanzamiento en curso (segundos desde que empezó; < 0 = ninguno) y si ya soltó la granada
var throw_t := -1.0
var thrown := false
var throw_target := 0.0


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
	fx.z_index = 1
	add_child(fx)
	fx.draw.connect(_draw_fx)
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
	fire_t -= delta
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
						fire_t = 0.07
						Game.sfx("shot", -20.0, 0.7)
				"grenadier":
					dir = 1 if dx > 0 else -1
					velocity.x = 0.0
					shoot_t -= delta
					if shoot_t <= 0.0 and on_screen and not p.dead and absf(dx) < 260.0:
						shoot_t = randf_range(2.2, 3.2)
						if ar:
							# saca la granada, echa el brazo atrás y la suelta con el brazo adelante
							throw_t = 0.0
							thrown = false
							throw_target = p.position.x + randf_range(-10, 10)
						else:
							main.throw_grenade(position + Vector2(dir * 6, -24), p.position.x + randf_range(-10, 10))
					if throw_t >= 0.0:
						throw_t += delta
						var f := int(throw_t * THROW_FPS)
						if not thrown and f >= int(ar_meta["throw_release"]):
							thrown = true
							main.throw_grenade(position + Vector2(ar_meta["hand"][0] * dir, ar_meta["hand"][1]), throw_target)
						if f >= int(ar_meta["counts"]["throw"]):
							throw_t = -1.0
	move_and_slide()
	if state == "normal" and mode == "run" and is_on_wall() and is_on_floor():
		velocity.y = -300.0
	if position.y > main.cam_y + 320 or position.x < main.cam_left - 60 or position.x > main.cam_left + 560:
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
	# sangre hacia el lado contrario al jugador (de donde viene el golpe)
	var away := Vector2(signf(position.x - main.player.position.x), 0)
	if away.x == 0.0:
		away.x = 1.0
	var gy: float = main.ground_y_at(position.x) if main.has_method("ground_y_at") else position.y
	Sangre.salpicar(get_parent(), position + Vector2(0, -24 if ar else -18), away, 14 if hp <= 0 else 6, gy)
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
		var n: Dictionary = ar_meta["counts"]
		spr = SpriteUtil.sprite(SpriteUtil.frames(hoja, fr[0], fr[1], {
			"idle": [A["idle"], n["idle"], 5, true], "run": [A["run"], 8, 14, true], "panic": [A["panic"], n["panic"], 9, true],
			"throw": [A["throw"], n["throw"], 1, false], "aim": [A["aim"], 4, 1, false], "flee": [A["flee"], 8, 18, true],
			"die": [A["die"], 3, 1, false]}),
			SpriteUtil.v(ar_meta["feet"]))
		# cada soldado respira a su ritmo (no todos a la vez)
		spr.speed_scale = randf_range(0.8, 1.15)
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
	# culatazo al disparar: 1 px hacia atrás
	spr.position.x = -dir if fire_t > 0.0 and state == "normal" else 0
	fx.queue_redraw()
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
					if ar:
						if throw_t >= 0.0:
							spr.animation = "throw"
							spr.frame = mini(int(throw_t * THROW_FPS), spr.sprite_frames.get_frame_count("throw") - 1)
						else:
							_play("idle")
					elif shoot_t < 0.5:
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


## Fogonazo del francotirador en la boca del fusil (las poses de apuntar no lo traen dibujado).
func _draw_fx() -> void:
	if fire_t <= 0.0 or state != "normal" or mode != "sniper":
		return
	var m := Vector2(0, -22) + aim * 14
	if ar:
		var mz: Array = ar_meta["muzzles"][_aim_idx()]
		m = Vector2(mz[0] * dir, mz[1])
	var big := fire_t > 0.035
	var d := Vector2(absf(aim.x) * dir, aim.y).normalized()
	fx.draw_circle(m + d * 2.0, 4.5 if big else 3.0, Color(1, 0.6, 0.15))
	fx.draw_circle(m + d * 3.0, 3.0 if big else 2.0, Color(1, 0.92, 0.45))
	fx.draw_circle(m + d * 3.0, 1.5, Color(1, 1, 0.9))
