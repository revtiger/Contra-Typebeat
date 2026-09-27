extends CharacterBody2D
## Soldado del jugador con controles estilo Metal Slug:
## - dispara adelante, arriba y (solo en el aire) abajo; sin diagonales
## - se agacha y avanza agachado; baja de los puentes con Abajo + Saltar
## - granadas con botón propio (10 por vida); cuchillo automático si hay un soldado pegado
## - armas especiales con munición limitada: al acabarse vuelve la pistola

signal died

const Bullet = preload("res://scripts/bullet.gd")
const Grenade = preload("res://scripts/grenade.gd")

const SPEED := 90.0
const CROUCH_SPEED := 38.0
const JUMP_V := -360.0
const GRAVITY := 900.0
const W := 12.0
const STAND_H := 26.0
const CROUCH_H := 15.0
const JUMP_H := 22.0
const START_BOMBS := 10
const KNIFE_RANGE := 24.0

## Armas: cadencia en segundos y munición al recogerlas (-1 = infinita).
const WEAPONS := {
	"P": {"rate": 0.16, "ammo": -1},
	"H": {"rate": 0.065, "ammo": 200},
	"R": {"rate": 0.4, "ammo": 30},
	"F": {"rate": 0.3, "ammo": 30},
	"L": {"rate": 0.1, "ammo": 200},
	"S": {"rate": 0.45, "ammo": 30},
}

var facing := 1
var aim := Vector2.RIGHT
var crouching := false
var shoot_cd := 0.0
var grenade_cd := 0.0
var invuln := 1.5
var dead := false
var death_t := 0.0
var drop_t := 0.0
var weapon := "P"
var ammo := -1
var bombs := START_BOMBS
var knife_t := 0.0
var throw_t := 0.0
var flash_t := 0.0
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
	grenade_cd -= delta
	knife_t -= delta
	throw_t -= delta
	flash_t -= delta
	invuln = maxf(invuln - delta, 0.0)
	drop_t -= delta
	collision_mask = 1 if drop_t > 0.0 else 1 | 8

	var dir := Input.get_axis("left", "right")
	var up := Input.is_action_pressed("up")
	var down := Input.is_action_pressed("down")
	var on_floor := is_on_floor()

	crouching = on_floor and down and not up
	if absf(dir) >= 0.3:
		facing = 1 if dir > 0 else -1
		dir = facing
	else:
		dir = 0.0

	velocity.x = dir * (CROUCH_SPEED if crouching else SPEED)
	if not on_floor:
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and on_floor:
		if down and _standing_on_bridge():
			drop_t = 0.35
			collision_mask = 1
		else:
			velocity.y = JUMP_V
			Game.sfx("jump", -14.0)
	if Input.is_action_just_released("jump") and velocity.y < -140.0:
		velocity.y = -140.0

	_set_height(CROUCH_H if crouching else (STAND_H if on_floor else JUMP_H))

	if up:
		aim = Vector2.UP
	elif down and not on_floor:
		aim = Vector2.DOWN
	else:
		aim = Vector2(facing, 0)

	move_and_slide()
	position.x = clampf(position.x, cam_left + 6, cam_left + 480 - 6)

	if Input.is_action_pressed("shoot") and shoot_cd <= 0.0:
		if not _try_knife():
			_fire()
	if Input.is_action_just_pressed("grenade") and grenade_cd <= 0.0 and bombs > 0:
		_throw_grenade()

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
	if aim == Vector2.UP:
		return Vector2(facing * 3, -34)
	if aim == Vector2.DOWN:
		return Vector2(0, 0)
	if crouching:
		return Vector2(facing * 15, -9)
	return Vector2(facing * 15, -17)


## Cuchillo: si hay un soldado pegado delante, se le apuñala en vez de disparar.
func _try_knife() -> bool:
	if aim.y != 0.0:
		return false
	for n in get_tree().get_nodes_in_group("enemy"):
		if n.get("knifeable") != true:
			continue
		var dx: float = (n.position.x - position.x) * facing
		if dx > -4.0 and dx < KNIFE_RANGE and absf(n.position.y - position.y) < 20.0:
			n.take_damage(3)
			knife_t = 0.18
			shoot_cd = 0.25
			Game.sfx("knife", -6.0)
			return true
	return false


func _bullet(v: Vector2, kind: String, damage: int, pierce := false, life := 1.6) -> void:
	var b := Bullet.new()
	b.from_player = true
	b.vel = v
	b.kind = kind
	b.damage = damage
	b.pierce = pierce
	b.life = life
	b.position = position + _muzzle()
	get_parent().add_child(b)


func _fire() -> void:
	shoot_cd = WEAPONS[weapon]["rate"]
	flash_t = 0.05
	match weapon:
		"P":
			_bullet(aim * 320.0, "normal", 1)
			Game.sfx("shot", -16.0)
		"H":
			_bullet(aim.rotated(randf_range(-0.05, 0.05)) * 380.0, "heavy", 1)
			Game.sfx("shot", -18.0, 1.35)
		"R":
			_bullet(aim * 150.0, "rocket", 0, false, 2.5)
			Game.sfx("fire", -10.0, 1.6)
		"F":
			_bullet(aim * 210.0, "flame", 3, true, 0.6)
			Game.sfx("fire", -8.0)
		"L":
			_bullet(aim * 520.0, "laser", 2, true)
			Game.sfx("laser", -16.0, 1.3)
		"S":
			for a in [-0.3, -0.15, 0.0, 0.15, 0.3]:
				_bullet(aim.rotated(a) * 300.0, "shotgun", 3, true, 0.22)
			Game.sfx("cannon", -6.0, 1.5)
			Juice.shake(1.5)
	if ammo > 0:
		ammo -= 1
		if ammo == 0:
			weapon = "P"
			ammo = -1
			Game.sfx("move", -6.0, 0.6)


func _throw_grenade() -> void:
	bombs -= 1
	grenade_cd = 0.35
	throw_t = 0.2
	var g := Grenade.new()
	g.position = position + Vector2(facing * 6, -10 if crouching else -20)
	g.vel = Vector2(facing * 140.0 + velocity.x * 0.4, -230.0)
	get_parent().add_child(g)
	Game.sfx("jump", -10.0, 0.7)


func hit(force := false) -> void:
	if dead or (invuln > 0.0 and not force):
		return
	dead = true
	death_t = 1.2
	Game.sfx("death", -6.0)
	Juice.hitstop(0.15)
	velocity = Vector2(-facing * 60, -220)
	weapon = "P"
	ammo = -1
	col.set_deferred("disabled", true)
	hurt.set_deferred("monitoring", false)


func respawn(pos: Vector2) -> void:
	dead = false
	position = pos
	velocity = Vector2.ZERO
	invuln = 2.0
	bombs = START_BOMBS
	col.set_deferred("disabled", false)
	hurt.set_deferred("monitoring", true)


## Recoger un arma: si es la misma, suma munición.
func set_weapon(w: String) -> void:
	if w == weapon and ammo > 0:
		ammo += WEAPONS[w]["ammo"]
	else:
		weapon = w
		ammo = WEAPONS[w]["ammo"]
	Game.sfx("pickup", -4.0)


func add_bombs(n: int) -> void:
	bombs += n
	Game.sfx("pickup", -4.0, 0.8)


# ---------- dibujo con formas simples (origen en los pies) ----------
# Proporciones exageradas estilo Metal Slug: cabeza grande, chaleco, piernas cortas.

const SKIN := Color(0.96, 0.74, 0.55)
const PANTS := Color(0.25, 0.3, 0.55)
const VEST := Color(0.45, 0.52, 0.3)
const BANDANA := Color(0.9, 0.15, 0.15)
const HAIR := Color(0.95, 0.8, 0.35)
const GUN := Color(0.3, 0.3, 0.33)
const BOOT := Color(0.25, 0.18, 0.12)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if facing < 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), c)


func _head(y: float) -> void:
	_r(-4, y, 9, 8, SKIN)
	_r(-5, y - 1, 10, 3, HAIR)
	_r(-5, y + 2, 10, 1, BANDANA)
	_r(-8, y + 2, 3, 1, BANDANA)
	_r(3, y + 3, 1, 2, Color(0.1, 0.1, 0.1))


func _draw() -> void:
	if invuln > 0.0 and not Game.autoplay and int(anim_t * 20) % 2 == 0:
		return
	if dead:
		_r(-12, -6, 12, 5, PANTS)
		_r(0, -7, 8, 6, VEST)
		_r(8, -8, 7, 7, SKIN)
		_r(8, -9, 7, 2, HAIR)
		return
	var on_floor := is_on_floor()
	var moving := absf(velocity.x) > 1.0
	var ph := sin(anim_t * (9.0 if crouching else 15.0)) * 3.0 if moving and on_floor else 0.0
	var top := -30.0
	if crouching:
		# agachado: piernas dobladas, torso bajo
		_r(-6 + ph, -4, 6, 4, PANTS)
		_r(1 - ph, -4, 6, 4, PANTS)
		_r(-7, -1, 5, 1, BOOT)
		_r(3, -1, 5, 1, BOOT)
		_r(-5, -12, 10, 8, VEST)
		top = -21.0
	elif not on_floor:
		# salto: piernas recogidas
		_r(-5, -10, 5, 6, PANTS)
		_r(1, -8, 5, 5, PANTS)
		_r(-5, -18, 10, 9, VEST)
	else:
		_r(-4 + ph, -10, 4, 9, PANTS)
		_r(1 - ph, -10, 4, 9, PANTS)
		_r(-5 + ph, -2, 6, 2, BOOT)
		_r(0 - ph, -2, 6, 2, BOOT)
		_r(-5, -20, 10, 11, VEST)
		_r(-5, -12, 10, 2, Color(0.3, 0.22, 0.12))
	_head(top)
	# brazos y arma
	var sh := Vector2(facing * 2, top + 12)
	var gun_len := 12.0 if weapon == "P" else 16.0
	if knife_t > 0.0:
		var k := 1.0 - knife_t / 0.18
		draw_arc(sh, 16, -1.2 * facing + (0.0 if facing > 0 else PI), (1.2 - 2.4 * k) * facing + (0.0 if facing > 0 else PI), 8, Color(1, 1, 1, 0.8), 2)
		draw_line(sh, sh + Vector2(facing * 10, -4 + 8 * k), Color(0.85, 0.85, 0.9), 2)
	elif throw_t > 0.0:
		draw_line(sh, sh + Vector2(-facing * 4, -10), SKIN, 3)
	else:
		draw_line(sh, sh + aim * 6, SKIN, 3)
		draw_line(sh + aim * 3, sh + aim * gun_len, GUN, 3 if weapon != "P" else 2)
	if flash_t > 0.0:
		var m := position + _muzzle() - position
		draw_circle(m, 4, Color(1, 0.95, 0.5))
		draw_circle(m, 2, Color.WHITE)
