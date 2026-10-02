extends CharacterBody2D
## Soldado del jugador con controles estilo Metal Slug:
## - dispara adelante, arriba y (solo en el aire) abajo; sin diagonales
## - se agacha y avanza agachado; baja de los puentes con Abajo + Saltar
## - granadas con botón propio (10 por vida); cuchillo automático si hay un soldado pegado
## - armas especiales con munición limitada: al acabarse vuelve la pistola

signal died

const Bullet = preload("res://scripts/bullet.gd")
const Grenade = preload("res://scripts/grenade.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const META_PATH := "res://assets/sprites/player_meta.json"

const SPEED := 90.0
const CROUCH_SPEED := 38.0
const JUMP_V := -360.0
const GRAVITY := 900.0
const W := 12.0
const STAND_H := 30.0
const CROUCH_H := 18.0
const JUMP_H := 24.0
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
var meta: Dictionary
var legs: AnimatedSprite2D
var torso: AnimatedSprite2D
var death_spr: AnimatedSprite2D
var fx := Node2D.new()


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
	_setup_sprites()


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
	var key := "fwd"
	if aim == Vector2.UP:
		key = "up"
	elif aim == Vector2.DOWN:
		key = "down"
	elif crouching:
		key = "crouch_fwd"
	var m := SpriteUtil.v(meta["muzzle"][key])
	return Vector2(m.x * facing, m.y + torso.position.y)


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


# ---------- sprites (assets/sprites/player_*.png, generados por tools/sprites/humans.py) ----------

func _setup_sprites() -> void:
	meta = SpriteUtil.meta(META_PATH)
	var fw: int = meta["frame"][0]
	var fh: int = meta["frame"][1]
	var feet := SpriteUtil.v(meta["feet"])
	var L: Dictionary = meta["legs"]
	var T: Dictionary = meta["torso"]
	legs = SpriteUtil.sprite(SpriteUtil.frames("res://assets/sprites/player_%s_legs.png" % Game.hero, fw, fh, {
		"idle": [L["idle"], 1, 1, true], "run": [L["run"], 8, 14, true], "jump": [L["jump"], 2, 1, false],
		"crouch": [L["crouch"], 1, 1, true], "crawl": [L["crawl"], 4, 8, true]}), feet)
	var tanims := {}
	for n in T:
		tanims[n] = [T[n], 3 if n.ends_with("knife") else 2, 1, false]
	torso = SpriteUtil.sprite(SpriteUtil.frames("res://assets/sprites/player_%s_torso.png" % Game.hero, fw, fh, tanims), feet)
	var df: Array = meta["death_frame"]
	death_spr = SpriteUtil.sprite(SpriteUtil.frames("res://assets/sprites/player_%s_death.png" % Game.hero, df[0], df[1],
		{"die": [0, 4, 8, false]}), SpriteUtil.v(meta["death_feet"]))
	death_spr.visible = false
	for n in [legs, torso, death_spr]:
		add_child(n)
	add_child(fx)
	fx.draw.connect(_draw_fx)


func _process(_delta: float) -> void:
	if legs == null:
		return
	modulate.a = 0.35 if invuln > 0.0 and not Game.autoplay and int(anim_t * 20) % 2 == 0 else 1.0
	for n in [legs, torso, death_spr]:
		n.scale.x = facing
	if dead:
		legs.visible = false
		torso.visible = false
		if not death_spr.visible:
			death_spr.visible = true
			death_spr.play("die")
		fx.queue_redraw()
		return
	legs.visible = true
	torso.visible = true
	death_spr.visible = false
	var on_floor := is_on_floor()
	var moving := absf(velocity.x) > 1.0
	var bob := 0
	if crouching:
		_play(legs, "crawl" if moving else "crouch")
	elif not on_floor:
		legs.animation = "jump"
		legs.frame = 0 if velocity.y < 0.0 else 1
	elif moving:
		_play(legs, "run")
		bob = meta["bob"]["run"][legs.frame]
	else:
		_play(legs, "idle")
	torso.position.y = bob
	var prefix := "crouch_" if crouching else ""
	if knife_t > 0.0:
		torso.animation = prefix + "knife"
		torso.frame = clampi(int((1.0 - knife_t / 0.18) * 3.0), 0, 2)
	elif throw_t > 0.0:
		torso.animation = prefix + "throw"
		torso.frame = 0 if throw_t > 0.1 else 1
	else:
		if aim == Vector2.UP:
			torso.animation = "up"
		elif aim == Vector2.DOWN:
			torso.animation = "down"
		else:
			torso.animation = prefix + "fwd"
		torso.frame = 1 if flash_t > 0.0 else 0
	fx.queue_redraw()


func _play(spr: AnimatedSprite2D, anim: String) -> void:
	if spr.animation != anim or not spr.is_playing():
		spr.play(anim)


## Fogonazo del disparo, por encima de los sprites.
func _draw_fx() -> void:
	if flash_t > 0.0 and not dead:
		var m := _muzzle()
		fx.draw_circle(m, 4, Color(1, 0.95, 0.5))
		fx.draw_circle(m, 2, Color.WHITE)
