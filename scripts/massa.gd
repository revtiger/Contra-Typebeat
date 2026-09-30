extends CharacterBody2D
## Sergio Massa, minijefe de la fase 1.1 (caricatura). Primer jefe con animaciones completas.
## Sprites: assets/sprites/boss_massa*.png (tools/sprites/massa.py, animaciones de PixelLab).
##
## Ciclo: entra caminando, respira, se recoloca caminando y encadena ataques:
##   - Discurso: saca el micrófono y lanza "promesas" (bocadillos lentos que ondulan; se pueden reventar a tiros)
##   - Plan Platita: saca un fajo del saco y lo lanza en arco; al caer se abre en billetes que revolotean
##   - ¡Pulgar arriba!: guiña y llama a dos militantes (soldados). Durante el gesto está vendido
##   - La Maquinita (a media vida): se echa al hombro un cañón de imprimir billetes y dispara 3 ráfagas
## A media vida se enfada: suda, va más rápido y añade La Maquinita.
## Al perder, pone cara de disgusto y sale volando dando vueltas (sin gore).
## No tiene variable "state" a propósito (la prueba automática lo trata como jefe de suelo).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Shot = preload("res://scripts/massa_shot.gd")
const Soldier = preload("res://scripts/soldier.gd")
const DIR := "res://assets/sprites/"
const MAX_HP := 70
const BOSS_NAME := "SERGIO MASSA"

var main
var meta: Dictionary
var body: AnimatedSprite2D
var weapon := Sprite2D.new()
var mode := "wait"  # wait | enter | idle | walk | speech | throw | thumbs | maquinita | dying
var hp := MAX_HP
var t := 0.0
var mode_t := 0.0
var idle_for := 0.6
var dir := -1
var home_x := 0.0
var base_y := 0.0
var target_x := 0.0
var step := -1
var flash := 0.0
var hurt_acc := 0
var angry := false
var last_frame := -1
var shots_left := 0
var shot_t := 0.0
var aim := 0.0
var recoil := 0.0
var sweat: Array = []


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	meta = SpriteUtil.meta(DIR + "boss_massa_meta.json")
	var a: Dictionary = meta["anims"]
	var sf := SpriteUtil.frames(DIR + "boss_massa.png", 96, 128, {
		"idle": [a["idle"]["row"], a["idle"]["frames"], 6, true],
		"walk": [a["walk"]["row"], a["walk"]["frames"], 11, true],
		"talk": [a["talk"]["row"], a["talk"]["frames"], 10, false],
		"throw": [a["throw"]["row"], a["throw"]["frames"], 12, false],
		"thumbs": [a["thumbs"]["row"], a["thumbs"]["frames"], 9, false],
	})
	body = SpriteUtil.sprite(sf, SpriteUtil.v(meta["pivot"]))
	body.show_behind_parent = true  # lo que dibuja _draw (brazo, sudor, vida) va encima del cuerpo
	add_child(body)
	weapon.texture = load(DIR + "boss_massa_weapon.png")
	weapon.visible = false
	weapon.show_behind_parent = true  # encima del cuerpo, pero debajo de la mano que dibuja _draw
	add_child(weapon)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 100)
	cs.shape = r
	cs.position = Vector2(0, -50)
	add_child(cs)
	var arena: float = main.boss_arena
	home_x = arena + 370.0
	base_y = main.ground_y_at(main.level_end - 100)
	position = Vector2(arena + 540.0, base_y)
	_play("walk")


func _play(anim: String, speed := 1.0) -> void:
	body.speed_scale = speed * (1.25 if angry else 1.0)
	if body.animation != anim or not body.is_playing():
		body.play(anim)
	last_frame = -1


func _set_mode(m: String) -> void:
	mode = m
	mode_t = 0.0
	last_frame = -1


func _physics_process(delta: float) -> void:
	t += delta
	mode_t += delta
	flash -= delta
	recoil = move_toward(recoil, 0.0, 30.0 * delta)
	var p = main.player
	match mode:
		"wait":
			if main.cam_left >= main.boss_arena - 1.0:
				_set_mode("enter")
		"enter":
			dir = -1
			position.x = move_toward(position.x, home_x, 60.0 * delta)
			if position.x <= home_x + 0.5:
				_idle(0.8)
		"idle":
			_face(p)
			if mode_t >= idle_for and not p.dead:
				_next_action(p)
		"walk":
			var speed := 70.0 if angry else 52.0
			dir = 1 if target_x > position.x else -1
			position.x = move_toward(position.x, target_x, speed * delta)
			body.speed_scale = speed / 52.0
			if absf(position.x - target_x) < 0.5:
				_idle(0.35)
		"speech":
			_face(p)
			var f := body.frame
			if f != last_frame:
				last_frame = f
				if f in [3, 5, 7]:
					_promise(p)
			if not body.is_playing():
				_idle(0.5)
		"throw":
			_face(p)
			var f := body.frame
			if f != last_frame:
				last_frame = f
				if f == 6 or (angry and f == 7):
					_bundle(p, 0.0 if f == 6 else 70.0)
			if not body.is_playing():
				_idle(0.5)
		"thumbs":
			var f := body.frame
			if f != last_frame:
				last_frame = f
				if f == 4:
					_call_militants()
			if not body.is_playing():
				_idle(0.6)
		"maquinita":
			_maquinita(delta, p)
		"dying":
			_dying(delta)
			return
	# balanceo suave al respirar y al caminar
	var bob := 0.0
	if mode == "walk":
		bob = -absf(sin(t * 11.0)) * 1.5
	body.position = Vector2(0, bob)
	body.flip_h = dir > 0
	var piv: Vector2 = SpriteUtil.v(meta["pivot"])
	body.offset.x = -(96.0 - piv.x) if dir > 0 else -piv.x
	# al recibir un tiro: tinte cálido breve (no blanco entero, que con la ametralladora sería constante)
	body.modulate = Color(1.6, 1.25, 1.2) if flash > 0.0 else Color.WHITE
	_sweat(delta)
	queue_redraw()


func _face(p) -> void:
	dir = 1 if p.position.x > position.x else -1


func _idle(time: float) -> void:
	_set_mode("idle")
	idle_for = time * (0.7 if angry else 1.0)
	_play("idle")


## Siguiente paso del ciclo de ataques (más largo y variado a media vida).
func _next_action(p) -> void:
	var cycle := ["walk", "speech", "walk", "throw", "thumbs"]
	if angry:
		cycle = ["maquinita", "walk", "speech", "throw", "walk", "maquinita", "thumbs"]
	step = (step + 1) % cycle.size()
	match cycle[step]:
		"walk":
			var arena: float = main.boss_arena
			var choices := [arena + 260.0, arena + 330.0, arena + 400.0]
			choices.erase(choices.reduce(func(a, b): return a if absf(a - position.x) < absf(b - position.x) else b))
			target_x = choices[randi() % choices.size()]
			_set_mode("walk")
			_play("walk")
		"speech":
			_set_mode("speech")
			_play("talk")
			Game.sfx("beep", -10.0, 0.6)
		"throw":
			_set_mode("throw")
			_play("throw")
		"thumbs":
			_set_mode("thumbs")
			_play("thumbs")
		"maquinita":
			_set_mode("maquinita")
			_play("idle", 0.0)
			body.frame = 0
			shots_left = 3
			shot_t = 0.7
			weapon.visible = true
			Game.sfx("cannon", -8.0, 0.5)


## Punto del fotograma (mirando a la izquierda) en coordenadas del mundo, según hacia dónde mira.
func _point(key: String) -> Vector2:
	var m: Vector2 = SpriteUtil.v(meta[key])
	var piv: Vector2 = SpriteUtil.v(meta["pivot"])
	var local := m - piv
	if dir > 0:
		local.x = -local.x
	return global_position + local


func _promise(p) -> void:
	var s := Shot.new()
	s.kind = "bubble"
	s.position = _point("mic")
	s.vel = Vector2(dir * (60.0 if not angry else 80.0), 0.0)
	s.target_y = p.position.y - 16.0 + randf_range(-18, 10)
	main.add_child(s)
	Game.sfx("type", -6.0, 0.7)


func _bundle(p, extra: float) -> void:
	var s := Shot.new()
	s.kind = "bundle"
	var from := _point("hand_throw")
	s.position = from
	var tx: float = p.position.x + randf_range(-20, 20) - extra * dir
	var vy := -210.0
	var g := 420.0
	var drop: float = base_y - from.y
	var time := (-vy + sqrt(vy * vy + 2.0 * g * drop)) / g
	s.vel = Vector2((tx - from.x) / time, vy)
	main.add_child(s)
	Game.sfx("jump", -8.0, 1.4)


func _call_militants() -> void:
	Game.sfx("select", -4.0, 1.2)
	main.show_banner("¡VAMOS, MUCHACHOS!", 1.0)
	for i in 2:
		var s := Soldier.new()
		s.dir = -1
		s.position = Vector2(main.cam_left + 490.0 + i * 26.0, 90)
		main.add_child(s)


## La Maquinita: sube el cañón, apunta al jugador, dispara 3 ráfagas de billetes con retroceso y lo baja.
func _maquinita(delta: float, p) -> void:
	_face(p)
	var forward := Vector2(dir, 0)
	var shoulder := _point("shoulder") - global_position
	# el cañón sube desde la cadera en 0,45 s y luego sigue al jugador (limitado)
	var raise := clampf(mode_t / 0.45, 0.0, 1.0)
	var to: Vector2 = p.global_position + Vector2(0, -16) - (global_position + shoulder)
	aim = lerpf(aim, clampf(forward.angle_to(to), -0.4, 0.4), 8.0 * delta)
	var lowered := (1.0 - raise) * 0.9 * dir  # apuntando al suelo mientras sube
	weapon.flip_h = dir > 0
	weapon.rotation = aim + lowered
	weapon.position = shoulder - forward * recoil + Vector2(0, -4.0 + (1.0 - raise) * 18.0)
	if raise < 1.0:
		return
	if shots_left > 0:
		shot_t -= delta
		if shot_t <= 0.0:
			shots_left -= 1
			shot_t = 0.45
			recoil = 7.0
			var d := forward.rotated(aim)
			var muzzle: Vector2 = global_position + weapon.position + d * weapon.texture.get_width() * 0.5
			main.explode(muzzle, 8.0, false)
			main.shake(2.5)
			Game.sfx("cannon", -4.0, 1.1)
			for a in [-0.12, 0.0, 0.12]:
				var s := Shot.new()
				s.kind = "bill"
				s.position = muzzle
				s.vel = d.rotated(a) * 190.0
				main.add_child(s)
	elif shot_t <= -0.5 or mode_t > 3.5:
		weapon.visible = false
		_idle(0.5)
	else:
		shot_t -= delta


func take_damage(n: int) -> void:
	if mode in ["wait", "enter", "dying"]:
		return
	hp -= n
	flash = 0.05
	hurt_acc += n
	Game.sfx("hit", -16.0, 0.8)
	if hurt_acc >= 10 and mode in ["idle", "walk"]:
		# retrocede un paso al acumular daño
		hurt_acc = 0
		var tw := create_tween()
		tw.tween_property(body, "rotation", 0.1 * -dir, 0.06)
		tw.tween_property(body, "rotation", 0.0, 0.15)
	if not angry and hp <= MAX_HP / 2:
		angry = true
		main.show_banner("¡PLAN PLATITA!", 1.4)
		main.shake(3.0)
		Game.sfx("boom", -8.0, 1.3)
		body.speed_scale = 1.25
	if hp <= 0:
		_die()


func _die() -> void:
	_set_mode("dying")
	collision_layer = 0
	remove_from_group("enemy")
	weapon.visible = false
	main.add_score(5000)
	Juice.hitstop(0.12)
	main.shake(5.0)
	main.explode(global_position + Vector2(0, -60), 26.0)
	Game.sfx("death", -4.0, 0.7)
	# cara de disgusto (último fotograma del discurso) y a volar
	body.play("talk")
	body.stop()
	body.frame = meta["anims"]["talk"]["frames"] - 1
	velocity = Vector2(-dir * 140.0, -320.0)
	main.show_banner("¡RECIBIÓ SU MERECIDO!\n" + BOSS_NAME, 1.6)


func _dying(delta: float) -> void:
	body.rotation += delta * 9.0 * -dir
	velocity.y += 500.0 * delta
	position += velocity * delta
	if int(mode_t * 6.0) != int((mode_t - delta) * 6.0):
		main.explode(global_position + Vector2(randf_range(-20, 20), randf_range(-80, -20)), randf_range(8, 16), false)
		# billetes que se le caen de los bolsillos
		var s := Shot.new()
		s.kind = "flutter"
		s.harmless = true
		s.position = global_position + Vector2(0, -60)
		s.vel = Vector2(randf_range(-60, 60), randf_range(-120, -40))
		main.add_child(s)
	if mode_t > 1.6:
		main.stage_clear()
		queue_free()


## Gotas de sudor cuando está enfadado.
func _sweat(delta: float) -> void:
	if angry and randf() < delta * 5.0:
		sweat.append([Vector2(randf_range(-12, 8) * -dir, -112), randf_range(-20, 20), 0.0])
	for s in sweat:
		s[2] += delta
		s[0] += Vector2(s[1], 40.0) * delta
	sweat = sweat.filter(func(s): return s[2] < 0.6)


func _draw() -> void:
	for s in sweat:
		draw_rect(Rect2(s[0], Vector2(2, 3)), Color(0.6, 0.85, 1.0, 1.0 - s[2] / 0.6))
	if weapon.visible:
		# mano que sujeta la empuñadura de La Maquinita (manga oscura y mano)
		var grip := weapon.position + Vector2(dir * 6.0, 6.0).rotated(weapon.rotation)
		draw_line(grip + Vector2(-dir * 4.0, 16.0), grip, Color(0.1, 0.12, 0.22), 5)
		draw_rect(Rect2(grip - Vector2(3, 2), Vector2(6, 5)), Color(0.1, 0.05, 0.05))
		draw_rect(Rect2(grip - Vector2(2, 1), Vector2(4, 3)), Color(0.96, 0.72, 0.6))
	if mode in ["wait", "enter", "dying"]:
		return
	var y := -124.0
	draw_rect(Rect2(-30, y, 60, 4), Color(0.2, 0, 0))
	draw_rect(Rect2(-30, y, 60.0 * maxf(hp, 0) / MAX_HP, 4), Color(1, 0.25, 0.2))
