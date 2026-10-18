extends CharacterBody2D
## Sergio Massa, minijefe de la fase 1.1 (caricatura). Mide 60 px (×1,25 Eduardo).
## Sprites: assets/sprites/boss_massa.png (tools/sprites/massa.py: dos poses de ChatGPT animadas con PixelLab).
##
## Dos fases:
##   De traje: entra caminando y encadena ataques
##     - Doble granada: como un lanzador de béisbol, lanza una granada con cada mano (una al jugador y otra
##       un poco por delante o por detrás, para que no baste con quedarse quieto)
##     - ¡Pulgar arriba!: guiña y llama a dos militantes (soldados). Durante el gesto está vendido
##   A media vida se quita el saco y lo tira, agarra el rifle (invulnerable mientras tanto) y pasa a
##   chaleco: ráfagas de rifle apuntadas al jugador, camina más rápido y sigue llamando militantes a gritos.
## Al perder sale volando dando vueltas (sin gore) y se le cae una lluvia de billetes de los bolsillos.
## No tiene variable "state" a propósito (la prueba automática lo trata como jefe de suelo).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Shot = preload("res://scripts/massa_shot.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Bullet = preload("res://scripts/bullet.gd")
const DIR := "res://assets/sprites/"
const MAX_HP := 70
const BOSS_NAME := "SERGIO MASSA"
const HEIGHT := 60.0
# fps de cada animación de boss_massa_meta.json y si se repite
const ANIM_FPS := {
	"idle": [6, true], "walk": [11, true], "grenade": [12, false], "thumbs": [9, false],
	"strip": [7, false], "v_idle": [6, true], "v_walk": [13, true], "v_shoot": [16, true],
}

var main
var meta: Dictionary
var body: AnimatedSprite2D
var mode := "wait"  # wait | enter | idle | walk | grenade | thumbs | strip | rifle | shout | dying
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
var armed := false  # ya se quitó el saco: chaleco y rifle
var last_frame := -1
var shots_left := 0
var shot_t := 0.0
var sweat: Array = []


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	meta = SpriteUtil.meta(DIR + "boss_massa_meta.json")
	var a: Dictionary = meta["anims"]
	var anims := {}
	for n in a:
		anims[n] = [a[n]["row"], a[n]["frames"], ANIM_FPS[n][0], ANIM_FPS[n][1]]
	var fr: Array = meta["frame"]
	body = SpriteUtil.sprite(SpriteUtil.frames(DIR + "boss_massa.png", fr[0], fr[1], anims), SpriteUtil.v(meta["pivot"]))
	body.show_behind_parent = true  # el sudor y la vida que dibuja _draw van encima del cuerpo
	add_child(body)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 54)
	cs.shape = r
	cs.position = Vector2(0, -27)
	add_child(cs)
	var arena: float = main.boss_arena
	home_x = arena + 370.0
	base_y = main.ground_y_at(main.level_end - 100)
	position = Vector2(arena + 540.0, base_y)
	_play("walk")


## Reproduce la animación de la fase actual ("idle" y "walk" pasan a "v_idle" y "v_walk" con el chaleco).
func _play(anim: String, speed := 1.0) -> void:
	if armed and anim in ["idle", "walk"]:
		anim = "v_" + anim
	body.speed_scale = speed
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
			var speed := 72.0 if armed else 50.0
			dir = 1 if target_x > position.x else -1
			position.x = move_toward(position.x, target_x, speed * delta)
			if absf(position.x - target_x) < 0.5:
				_idle(0.35)
		"grenade":
			_face(p)
			var f := body.frame
			if f != last_frame:
				last_frame = f
				var rel: Array = meta["grenade_release"]
				var k := rel.find(f)
				if k >= 0:
					# la primera al jugador; la segunda (con la otra mano) delante o detrás de él
					var off := randf_range(-10, 10) if k == 0 else (40.0 if randf() < 0.5 else -40.0)
					main.throw_grenade(_point("hand_r" if k == 0 else "hand_l"), p.position.x + off)
					Game.sfx("jump", -8.0, 1.1 + k * 0.2)
			if not body.is_playing():
				_idle(0.5)
		"thumbs":
			var f := body.frame
			if f != last_frame:
				last_frame = f
				if f == 4:
					_call_militants("¡VAMOS, MUCHACHOS!")
			if not body.is_playing():
				_idle(0.6)
		"strip":
			# se quita el saco: al soltarlo sale volando
			var f := body.frame
			if f != last_frame:
				last_frame = f
				if f == 5:
					_jacket()
			if not body.is_playing():
				armed = true
				_idle(0.4)
		"rifle":
			_rifle(delta, p)
		"shout":
			_face(p)
			if mode_t >= 0.5 and last_frame < 0:
				last_frame = 0
				_call_militants("¡A ELLOS!")
			if mode_t >= 1.1:
				_idle(0.4)
		"dying":
			_dying(delta)
			return
	body.flip_h = dir > 0
	var piv: Vector2 = SpriteUtil.v(meta["pivot"])
	body.offset.x = -(float(meta["frame"][0]) - piv.x) if dir > 0 else -piv.x
	# al recibir un tiro: tinte cálido breve (no blanco entero, que con la ametralladora sería constante)
	body.modulate = Color(1.6, 1.25, 1.2) if flash > 0.0 else Color.WHITE
	_sweat(delta)
	queue_redraw()


func _face(p) -> void:
	dir = 1 if p.position.x > position.x else -1


func _idle(time: float) -> void:
	_set_mode("idle")
	idle_for = time * (0.7 if armed else 1.0)
	_play("idle")


## Siguiente paso del ciclo de ataques (otro ciclo con el chaleco).
func _next_action(p) -> void:
	var cycle := ["walk", "grenade", "walk", "thumbs"]
	if armed:
		cycle = ["rifle", "walk", "rifle", "shout", "walk", "rifle"]
	step = (step + 1) % cycle.size()
	match cycle[step]:
		"walk":
			var arena: float = main.boss_arena
			var choices := [arena + 260.0, arena + 330.0, arena + 400.0]
			choices.erase(choices.reduce(func(a, b): return a if absf(a - position.x) < absf(b - position.x) else b))
			target_x = choices[randi() % choices.size()]
			_set_mode("walk")
			_play("walk")
		"grenade":
			_set_mode("grenade")
			_play("grenade")
		"thumbs":
			_set_mode("thumbs")
			_play("thumbs")
		"rifle":
			_set_mode("rifle")
			_play("idle")
			shots_left = 8
			shot_t = 0.45
		"shout":
			_set_mode("shout")
			_play("idle")


## Punto del fotograma (mirando a la izquierda) en coordenadas del mundo, según hacia dónde mira.
func _point(key: String) -> Vector2:
	var m: Vector2 = SpriteUtil.v(meta[key])
	var piv: Vector2 = SpriteUtil.v(meta["pivot"])
	var local := m - piv
	if dir > 0:
		local.x = -local.x
	return global_position + local


func _call_militants(text: String) -> void:
	Game.sfx("select", -4.0, 1.2)
	main.show_banner(text, 1.0)
	for i in 2:
		var s := Soldier.new()
		s.dir = -1
		s.position = Vector2(main.cam_left + 490.0 + i * 26.0, 90)
		main.add_child(s)


## El saco que tira al quitárselo: un trozo azul que sale girando hacia atrás y cae (solo decorado).
func _jacket() -> void:
	var j := Polygon2D.new()
	j.polygon = PackedVector2Array([Vector2(-7, -8), Vector2(6, -9), Vector2(8, 7), Vector2(0, 4), Vector2(-8, 8)])
	j.color = Color(0.13, 0.15, 0.32)
	j.position = global_position + Vector2(-dir * 6.0, -38.0)
	j.z_index = 4
	main.add_child(j)
	var land: float = base_y - 4.0
	var tw := j.create_tween().set_parallel()
	tw.tween_property(j, "position:x", j.position.x - dir * 70.0, 0.9)
	tw.tween_property(j, "rotation", -dir * 7.0, 0.9)
	tw.tween_property(j, "position:y", j.position.y - 30.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(j, "position:y", land, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(j, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tw.chain().tween_callback(j.queue_free)
	Game.sfx("jump", -6.0, 0.8)


## Ráfagas de rifle: apunta al jugador (con límite) y dispara balas sueltas con fogonazo.
func _rifle(delta: float, p) -> void:
	_face(p)
	shot_t -= delta
	if shots_left > 0:
		if shot_t <= 0.0:
			shots_left -= 1
			# ráfagas de 4 con una pausa entre ellas
			shot_t = 0.11 if shots_left % 4 != 0 else 0.6
			_play("v_shoot")
			var muzzle := _point("muzzle")
			var to: Vector2 = p.global_position + Vector2(0, -16) - muzzle
			var ang := clampf(Vector2(dir, 0).angle_to(to), -0.35, 0.35)
			var b := Bullet.new()
			b.from_player = false
			b.vel = Vector2(dir, 0).rotated(ang) * 150.0
			b.position = muzzle
			main.add_child(b)
			Game.sfx("shot", -12.0, 0.8)
		elif shot_t > 0.2:
			_play("idle")
	elif shot_t <= -0.3:
		_idle(0.4)


func take_damage(n: int) -> void:
	if mode in ["wait", "enter", "strip", "dying"]:
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
	if hp <= 0:
		_die()
	elif not armed and hp <= MAX_HP / 2 and mode != "strip":
		# fuera el saco: ahora va en serio
		_set_mode("strip")
		_play("strip")
		main.show_banner("¡SE SACÓ EL SACO!", 1.4)
		main.shake(3.0)
		Game.sfx("boom", -8.0, 1.3)


func _die() -> void:
	_set_mode("dying")
	collision_layer = 0
	remove_from_group("enemy")
	main.add_score(5000)
	Juice.hitstop(0.12)
	main.shake(5.0)
	main.explode(global_position + Vector2(0, -HEIGHT / 2.0), 20.0)
	Game.sfx("death", -4.0, 0.7)
	body.stop()
	velocity = Vector2(-dir * 140.0, -320.0)
	main.show_banner("¡RECIBIÓ SU MERECIDO!\n" + BOSS_NAME, 1.6)
	# al recibir el golpe final le revientan los bolsillos: un puñado de billetes de golpe
	for i in 14:
		_bill(Vector2(randf_range(-110, 110), randf_range(-260, -120)))


func _dying(delta: float) -> void:
	body.rotation += delta * 9.0 * -dir
	velocity.y += 500.0 * delta
	position += velocity * delta
	if int(mode_t * 6.0) != int((mode_t - delta) * 6.0):
		main.explode(global_position + Vector2(randf_range(-14, 14), randf_range(-HEIGHT, -10)), randf_range(6, 12), false)
		# y mientras vuela se le siguen cayendo
		for i in 3:
			_bill(Vector2(randf_range(-70, 70), randf_range(-140, -40)))
	if mode_t > 1.6:
		main.stage_clear()
		queue_free()


## Billete que se le cae de los bolsillos (solo decorado, no hace daño).
func _bill(vel: Vector2) -> void:
	var s := Shot.new()
	s.kind = "flutter"
	s.harmless = true
	s.position = global_position + Vector2(randf_range(-8, 8), -HEIGHT / 2.0 + randf_range(-8, 8))
	s.vel = vel
	# diferido: _die() llega desde la colisión de una bala, cuando Godot no deja crear áreas
	main.add_child.call_deferred(s)


## Gotas de sudor cuando ya va de chaleco.
func _sweat(delta: float) -> void:
	if armed and randf() < delta * 4.0:
		sweat.append([Vector2(randf_range(-6, 4) * -dir, -HEIGHT + 6.0), randf_range(-15, 15), 0.0])
	for s in sweat:
		s[2] += delta
		s[0] += Vector2(s[1], 35.0) * delta
	sweat = sweat.filter(func(s): return s[2] < 0.5)


func _draw() -> void:
	for s in sweat:
		draw_rect(Rect2(s[0], Vector2(1, 2)), Color(0.6, 0.85, 1.0, 1.0 - s[2] / 0.5))
	if mode in ["wait", "enter", "dying"]:
		return
	var y := -HEIGHT - 6.0
	draw_rect(Rect2(-24, y, 48, 3), Color(0.2, 0, 0))
	draw_rect(Rect2(-24, y, 48.0 * maxf(hp, 0) / MAX_HP, 3), Color(1, 0.25, 0.2))
