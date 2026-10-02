extends CharacterBody2D
## Soldado del jugador: corre, salta (en bola), se tumba, baja de puentes y dispara en 8 direcciones.

signal died

const Bullet = preload("res://scripts/bullet.gd")

const SPEED := 90.0
const JUMP_V := -360.0
const GRAVITY := 900.0
const W := 12.0
const STAND_H := 26.0
const PRONE_H := 10.0
const BALL_H := 16.0
const BULLET_SPEED := 300.0
const FIRE_RATE := {"N": 0.16, "M": 0.07, "S": 0.24, "L": 0.38, "F": 0.2}

var facing := 1
var aim := Vector2.RIGHT
var prone := false
var jumping := false
var shoot_cd := 0.0
var invuln := 1.5
var dead := false
var death_t := 0.0
var drop_t := 0.0
var weapon := "N"
var anim_t := 0.0
var cam_left := 0.0

var shape := RectangleShape2D.new()
var col := CollisionShape2D.new()
var hurt := Area2D.new()
var hurt_shape := RectangleShape2D.new()
var hurt_col := CollisionShape2D.new()


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 8
	floor_snap_length = 4.0
	col.shape = shape
	add_child(col)
	hurt.collision_layer = 0
	hurt.collision_mask = 4
	hurt_col.shape = hurt_shape
	hurt.add_child(hurt_col)
	add_child(hurt)
	_set_height(STAND_H)


func _set_height(h: float) -> void:
	if shape.size.y == h:
		return
	shape.size = Vector2(W, h)
	col.position = Vector2(0, -h / 2)
	hurt_shape.size = Vector2(W - 4, h - 4)
	hurt_col.position = col.position


func _physics_process(delta: float) -> void:
	anim_t += delta
	if dead:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		if death_t > 0.0:
			death_t -= delta
			if death_t <= 0.0:
				died.emit()
		queue_redraw()
		return

	shoot_cd -= delta
	invuln = maxf(invuln - delta, 0.0)
	drop_t -= delta
	collision_mask = 1 if drop_t > 0.0 else 1 | 8

	var dir := Input.get_axis("left", "right")
	var up := Input.is_action_pressed("up")
	var down := Input.is_action_pressed("down")
	var on_floor := is_on_floor()
	if on_floor and velocity.y >= 0.0:
		jumping = false

	prone = on_floor and down and absf(dir) < 0.3 and not up
	if absf(dir) >= 0.3:
		facing = 1 if dir > 0 else -1
		dir = facing
	else:
		dir = 0.0

	velocity.x = 0.0 if prone else dir * SPEED
	if not on_floor:
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and on_floor:
		if down and _standing_on_bridge():
			drop_t = 0.35
			collision_mask = 1
		else:
			velocity.y = JUMP_V
			jumping = true
			Game.sfx("jump", -14.0)
	if Input.is_action_just_released("jump") and velocity.y < -140.0:
		velocity.y = -140.0

	_set_height(PRONE_H if prone else (BALL_H if jumping else STAND_H))

	if up:
		aim = Vector2(dir, -1).normalized() if dir != 0 else Vector2.UP
	elif down and dir != 0:
		aim = Vector2(dir, 1).normalized()
	elif down and not on_floor:
		aim = Vector2.DOWN
	else:
		aim = Vector2(facing, 0)

	move_and_slide()
	position.x = clampf(position.x, cam_left + 6, cam_left + 480 - 6)

	if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
		_fire()

	if invuln <= 0.0:
		for b in hurt.get_overlapping_bodies():
			if b.is_in_group("enemy"):
				hit()
				break
	if position.y > 300:
		hit(true)
	queue_redraw()


func _standing_on_bridge() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var o := c.get_collider() as CollisionObject2D
		if c.get_normal().y < -0.5 and o and (o.collision_layer & 8):
			return true
	return false


func _muzzle() -> Vector2:
	if prone:
		return Vector2(8 * facing, -5) + aim * 6
	if jumping:
		return Vector2(0, -8) + aim * 9
	return Vector2(0, -17) + aim * 12


func _fire() -> void:
	shoot_cd = FIRE_RATE[weapon]
	var dirs := [aim]
	if weapon == "S":
		dirs = [aim.rotated(-0.26), aim.rotated(-0.13), aim, aim.rotated(0.13), aim.rotated(0.26)]
	for d in dirs:
		var b := Bullet.new()
		b.from_player = true
		b.vel = d * BULLET_SPEED
		match weapon:
			"L":
				b.kind = "laser"
				b.vel = d * 440.0
				b.damage = 3
				b.pierce = true
			"F":
				b.kind = "fire"
				b.vel = d * 190.0
				b.damage = 2
		b.position = position + _muzzle()
		get_parent().add_child(b)
	match weapon:
		"L": Game.sfx("laser", -12.0)
		"F": Game.sfx("fire", -10.0)
		_: Game.sfx("shot", -16.0, {"N": 1.0, "M": 1.25, "S": 0.8}[weapon])


func hit(force := false) -> void:
	if dead or (invuln > 0.0 and not force):
		return
	dead = true
	death_t = 1.2
	Game.sfx("death", -6.0)
	velocity = Vector2(-facing * 60, -220)
	weapon = "N"
	col.set_deferred("disabled", true)
	hurt.set_deferred("monitoring", false)


func respawn(pos: Vector2) -> void:
	dead = false
	jumping = false
	position = pos
	velocity = Vector2.ZERO
	invuln = 2.0
	col.set_deferred("disabled", false)
	hurt.set_deferred("monitoring", true)


func set_weapon(w: String) -> void:
	weapon = w
	Game.sfx("pickup", -4.0)


# ---------- dibujo con formas simples (origen en los pies) ----------

const SKIN := Color(0.96, 0.74, 0.55)
const PANTS := Color(0.2, 0.32, 0.85)
const BANDANA := Color(0.9, 0.15, 0.15)
const HAIR := Color(0.2, 0.12, 0.08)
const GUN := Color(0.55, 0.55, 0.6)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if facing < 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	if invuln > 0.0 and not Game.autoplay and int(anim_t * 20) % 2 == 0:
		return
	if dead:
		_r(-12, -6, 12, 5, PANTS)
		_r(0, -7, 7, 6, SKIN)
		_r(7, -8, 6, 6, SKIN)
		_r(7, -8, 6, 2, BANDANA)
		return
	if prone:
		_r(-12, -5, 12, 5, PANTS)
		_r(0, -6, 7, 5, SKIN)
		_r(6, -8, 6, 6, SKIN)
		_r(6, -8, 6, 2, HAIR)
		_r(6, -6, 6, 1, BANDANA)
		var m := Vector2(8 * facing, -5)
		draw_line(m, m + aim * 7, GUN, 2)
		return
	if jumping:
		var c := Vector2(0, -8)
		draw_circle(c, 7, PANTS)
		var a := anim_t * 18.0 * facing
		draw_circle(c + Vector2.from_angle(a) * 4, 3, SKIN)
		draw_circle(c + Vector2.from_angle(a + PI) * 4, 3, BANDANA)
		return
	var moving := absf(velocity.x) > 1.0
	var ph := sin(anim_t * 14.0) * 3.0 if moving else 0.0
	_r(-4 + ph, -10, 4, 10, PANTS)
	_r(0 - ph, -10, 4, 10, PANTS)
	_r(-4, -12, 8, 3, PANTS)
	_r(-4, -20, 8, 8, SKIN)
	_r(-3, -26, 7, 6, SKIN)
	_r(-3, -27, 7, 2, HAIR)
	_r(-3, -25, 7, 1, BANDANA)
	_r(-7, -25, 4, 1, BANDANA)
	var sh := Vector2(0, -17)
	draw_line(sh, sh + aim * 5, SKIN, 3)
	draw_line(sh + aim * 3, sh + aim * 12, GUN, 2)
