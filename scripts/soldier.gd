extends CharacterBody2D
## Soldado enemigo estilo Metal Slug.
## - "run": corre en línea recta y salta escalones; si te ve cerca a veces se asusta (brazos arriba) y huye
## - "sniper": se queda quieto y dispara al jugador en 8 direcciones
## - "grenadier": se para a lanzar granadas en arco (con marca de aviso en el suelo)
## - "asalto": emboscada de azotea (level._emboscada): marca en el techo con "!" (aviso), cae desde arriba de la
##   pantalla junto al héroe, se pone rojo un instante (WINDUP) y se lanza con un cuchillazo rápido. No daña al
##   tocarlo, solo con el cuchillazo.
## Al morir sale despedido hacia atrás girando, en vez de desaparecer. En Argentina (soldier_ar.png, de
## tools/sprites/soldados.py) recibe el disparo, cae de espaldas y queda tirado en el suelo un momento.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Sangre = preload("res://scripts/sangre.gd")

const PANIC_TIME := 0.7
const THROW_FPS := 14.0  # lanzamiento de granada del soldado de Argentina (prepara, lanza y vuelve)
const AR_CARAS := 4  # variantes de cara de soldier_ar.png
## asalto: aviso antes de caer, preparación del cuchillazo, y el cuchillazo (duración y velocidad)
const ASALTO_AVISO := 0.6
const WINDUP := 0.4
const LUNGE_T := 0.18
const LUNGE_V := 260.0

var mode := "run"
var dir := -1
var speed := 70.0
var hp := 1
var shoot_t := 1.2
var anim_t := 0.0
var main
var aim := Vector2.LEFT
var knifeable := true
var state := "normal"  # aviso | enter | normal | panic | flee | dead
var touch_damage := true  # tocarlo daña al héroe (el asaltante no: solo su cuchillazo)
var windup_t := 0.0
var lunge_t := 0.0
var lunge_hit := false
## enter: entra corriendo hasta plant_x y ahí se planta a atacar (francotiradores y granaderos de F2, modo test)
var plant_x := 0.0
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
	collision_layer = 4  # EnemyHurtbox
	collision_mask = 1  # Terreno (plataformas incluidas)
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
		"asalto":
			hp = 2
			touch_damage = false
			state = "aviso"
			state_t = ASALTO_AVISO
			collision_layer = 0
			spr.visible = false


func _physics_process(delta: float) -> void:
	anim_t += delta
	flash -= delta
	fire_t -= delta
	if state == "aviso":
		# asalto: la marca está en el techo donde va a caer; al acabar el aviso cae desde encima de la pantalla
		state_t -= delta
		if state_t <= 0.0:
			state = "normal"
			spr.visible = true
			collision_layer = 4
			position.y = main.cam_y - 30.0
			velocity = Vector2(0, 120)
			shoot_t = 0.0
		fx.queue_redraw()
		return
	velocity.y += 900.0 * delta
	if state == "dead":
		_dead_process(delta)
		_animate()
		return
	var p = main.player
	var dx: float = p.position.x - position.x
	# en pantalla también en vertical: con la cámara arriba (azoteas) los de la calle no disparan sin verse
	var on_screen: bool = position.x > main.cam_left and position.x < main.cam_left + 480 \
		and position.y > main.cam_y and position.y - 20.0 < main.cam_y + 270.0
	match state:
		"enter":
			velocity.x = dir * speed
			if (position.x - plant_x) * dir >= 0.0:
				state = "normal"
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
						b.vel = aim * 180.0  # 25-10-2026: +60 px/s (antes 120)
						b.position = position + Vector2(0, -22) + aim * 14
						if ar:
							var m: Array = ar_meta["muzzles"][_aim_idx()]
							b.position = position + Vector2(m[0] * dir, m[1])
						get_parent().add_child(b)
						fire_t = 0.07
						Game.sfx("shot", -20.0, 0.7)
				"asalto":
					if not is_on_floor():
						velocity.x = 0.0
					elif windup_t > 0.0:
						velocity.x = 0.0
						windup_t -= delta
						if windup_t <= 0.0:
							lunge_t = LUNGE_T
							lunge_hit = false
							Game.sfx("knife", -6.0, 0.8)
					elif lunge_t > 0.0:
						lunge_t -= delta
						velocity.x = dir * LUNGE_V
						if not lunge_hit and absf(dx) < 22.0 and absf(p.position.y - position.y) < 30.0:
							lunge_hit = true
							p.hit()
					else:
						velocity.x = 0.0
						dir = 1 if dx > 0 else -1
						shoot_t -= delta
						if shoot_t <= 0.0 and not p.dead:
							shoot_t = 1.1
							windup_t = WINDUP
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
	spr.modulate = Color(4, 4, 4) if flash > 0.0 else (Color(1.8, 0.6, 0.6) if windup_t > 0.0 else Color.WHITE)
	# culatazo al disparar: 1 px hacia atrás
	spr.position.x = -dir if fire_t > 0.0 and state == "normal" else 0
	fx.queue_redraw()
	match state:
		"enter":
			_play("run")
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
				"asalto":
					if lunge_t > 0.0:
						_play("run")
					elif windup_t > 0.0:
						spr.animation = "aim"
						spr.frame = 0
					else:
						_play("idle")
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
	if state == "aviso":
		# asalto: marca de aviso donde va a caer
		if int(state_t * 12.0) % 2 == 0:
			fx.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(0, -10)]), Color(1, 0.15, 0.1))
			fx.draw_rect(Rect2(-0.5, -7, 1.5, 4), Color.WHITE)
			fx.draw_rect(Rect2(-0.5, -2, 1.5, 1), Color.WHITE)
		return
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
