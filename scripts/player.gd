extends CharacterBody2D
## Soldado del jugador con controles estilo Metal Slug:
## - dispara adelante, arriba, en diagonal hacia arriba (Arriba + adelante) y, solo en el aire,
##   abajo y en diagonal hacia abajo (Abajo + adelante)
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
## Ventajas de cada soldado (Gwyn, 17-10-2026):
## - hp: golpes que aguanta antes de perder una vida, con barra de vida en el HUD (Eduardo, como un tanque de Metal Slug)
## - bombs: granadas al empezar y al reaparecer (Eder)
## - dual: la pistola dispara dos balas paralelas (Eder, doble pistola)
const PERKS := {
	"eduardo": {"hp": 3},
	"eder": {"bombs": 20, "dual": true},
}
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
var max_hp := 1
var hp := 1
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
## Modo cuerpo entero (Eduardo, Eder): una sola hoja player_<id>_body.png en vez de piernas + torso
var body: AnimatedSprite2D
var body_meta: Dictionary
## Fogonazos de cuerpo entero (player_<id>_flash.png): fila por dirección, pequeño y grande
var flash_tex: Texture2D
## Tiempo cuerpo a tierra (los primeros GO_PRONE_T s se ve la pose de tirarse al suelo)
var prone_t := 0.0
const GO_PRONE_T := 0.1
## Alto del cuerpo tumbado (cuerpo entero): las balas a la altura del pecho le pasan por encima
const PRONE_H := 12.0
var shot_n := 0
var shoot_pose_t := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 8
	floor_snap_length = 8.0  # pega al suelo al bajar cuestas
	floor_constant_speed = true
	col.shape = shape
	add_child(col)
	hurt.collision_layer = 0
	hurt.collision_mask = 4
	hurt_col.shape = hurt_shape
	hurt.add_child(hurt_col)
	add_child(hurt)
	_set_height(STAND_H)
	_setup_sprites()
	max_hp = _perk("hp", 1)
	hp = max_hp
	bombs = _perk("bombs", START_BOMBS)


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
	var side := absf(dir) >= 0.3
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

	var low := PRONE_H if body else CROUCH_H
	_set_height(low if crouching else (STAND_H if on_floor else JUMP_H))

	if up:
		aim = Vector2(facing, -1).normalized() if side else Vector2.UP
	elif down and not on_floor:
		aim = Vector2(facing, 1).normalized() if side else Vector2.DOWN
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


## Nombre de la dirección de apuntado: fwd, up, down, diag_up o diag_down (filas del torso y bocas del cañón).
func _aim_key() -> String:
	if aim.x == 0.0:
		return "up" if aim.y < 0.0 else "down"
	if aim.y != 0.0:
		return "diag_up" if aim.y < 0.0 else "diag_down"
	return "fwd"


func _standing_on_bridge() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var o := c.get_collider() as CollisionObject2D
		if c.get_normal().y < -0.5 and o and (o.collision_layer & 8):
			return true
	return false


func _muzzle() -> Vector2:
	if body:
		return _body_muzzle()
	var key := _aim_key()
	if key == "fwd" and crouching:
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


func _bullet(v: Vector2, kind: String, damage: int, pierce := false, life := 1.6, offset := Vector2.ZERO) -> void:
	var b := Bullet.new()
	b.from_player = true
	b.vel = v
	b.kind = kind
	b.damage = damage
	b.pierce = pierce
	b.life = life
	b.position = position + _muzzle() + offset
	get_parent().add_child(b)


func _fire() -> void:
	shoot_cd = WEAPONS[weapon]["rate"]
	flash_t = 0.05
	shot_n += 1
	shoot_pose_t = 0.25
	match weapon:
		"P":
			if _perk("dual", false):
				# doble pistola: dos balas paralelas, a 3 px a cada lado de la línea de tiro
				var side := aim.orthogonal() * 3.0
				_bullet(aim * 320.0, "normal", 1, false, 1.6, side)
				_bullet(aim * 320.0, "normal", 1, false, 1.6, -side)
			else:
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
	# con barra de vida: los golpes restan vida (caer a un foso mata siempre)
	if hp > 1 and not force:
		hp -= 1
		invuln = 1.0
		Game.sfx("hit", -6.0)
		Juice.hitstop(0.06)
		Juice.shake(2.0)
		return
	hp = 0
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
	bombs = _perk("bombs", START_BOMBS)
	hp = max_hp
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


## Ventaja del soldado elegido (PERKS) o el valor por defecto.
func _perk(key: String, default: Variant) -> Variant:
	return PERKS.get(Game.hero, {}).get(key, default)


func add_bombs(n: int) -> void:
	bombs += n
	Game.sfx("pickup", -4.0, 0.8)


# ---------- sprites (assets/sprites/player_*.png, generados por tools/sprites/humans.py) ----------

func _setup_sprites() -> void:
	var body_path := "res://assets/sprites/player_%s_body.png" % Game.hero
	if ResourceLoader.exists(body_path):
		_setup_body(body_path)
		return
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


func _process(delta: float) -> void:
	if legs == null and body == null:
		return
	modulate.a = 0.35 if invuln > 0.0 and not Game.autoplay and int(anim_t * 20) % 2 == 0 else 1.0
	if body:
		_process_body(delta)
		return
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
		var key := _aim_key()
		torso.animation = prefix + "fwd" if key == "fwd" else key
		torso.frame = 1 if flash_t > 0.0 else 0
	fx.queue_redraw()


func _play(spr: AnimatedSprite2D, anim: String) -> void:
	if spr.animation != anim or not spr.is_playing():
		spr.play(anim)


## Fogonazo del disparo, por encima de los sprites (las poses de cuerpo entero ya no lo traen dibujado).
func _draw_fx() -> void:
	if flash_t > 0.0 and not dead:
		var m := _muzzle()
		if _draw_body_flash(m):
			return
		fx.draw_circle(m, 4, Color(1, 0.95, 0.5))
		fx.draw_circle(m, 2, Color.WHITE)


# ---------- modo cuerpo entero (hojas player_<id>_body.png de tools/sprites/heroes_sheets.py) ----------

func _setup_body(path: String) -> void:
	body_meta = SpriteUtil.meta(path.replace(".png", "_meta.json"))
	var anims := {}
	for n in body_meta["anims"]:
		var a: Dictionary = body_meta["anims"][n]
		anims[n] = [a["row"], a["frames"], a["fps"], a["loop"]]
		if a.has("durations"):
			anims[n].append(a["durations"])
	var fr: Array = body_meta["frame"]
	body = SpriteUtil.sprite(SpriteUtil.frames(path, fr[0], fr[1], anims), SpriteUtil.v(body_meta["feet"]))
	add_child(body)
	var flash_path := path.replace("_body.png", "_flash.png")
	if body_meta.has("flash") and ResourceLoader.exists(flash_path):
		flash_tex = load(flash_path)
	add_child(fx)
	fx.draw.connect(_draw_fx)


## Boca del arma: la punta del cañón del fotograma que se ve (tips de la hoja), así el fogonazo y la bala
## salen del arma aunque se mueva al correr. Sin punta para esa pose, la boca fija de cada dirección.
func _body_muzzle() -> Vector2:
	var m: Dictionary = body_meta["muzzle"]
	var key := _aim_key()
	if key == "down":
		return Vector2(2 * facing, -2)  # sin pose de disparar hacia abajo: sale de entre los pies
	var tips: Dictionary = body_meta.get("tips", {})
	var p := SpriteUtil.v(m["fwd"])
	if tips.has(body.animation) and body.frame < tips[body.animation].size():
		p = SpriteUtil.v(tips[body.animation][body.frame])
	elif crouching:
		p = SpriteUtil.v(m["prone"])
	elif m.has(key):
		p = SpriteUtil.v(m[key])
	return Vector2(p.x * facing, p.y)


## Elige la pose: muerte, victoria, cuchillo, granada, cuerpo a tierra, agachado, salto, correr, disparar o quieto.
func _process_body(delta: float) -> void:
	shoot_pose_t -= delta
	prone_t = prone_t + delta if crouching else 0.0
	body.scale.x = facing
	var lvl = get_tree().get_first_node_in_group("level")
	var on_floor := is_on_floor()
	var moving := absf(velocity.x) > 1.0
	if dead:
		_play(body, "die")
	elif lvl and lvl.state == "clear" and on_floor:
		_play(body, "win")
	elif knife_t > 0.0:
		body.animation = "knife"
		body.frame = clampi(int((1.0 - knife_t / 0.18) * 4.0), 0, 3)
	elif throw_t > 0.0:
		body.animation = "throw"
		body.frame = clampi(int((1.0 - throw_t / 0.2) * 4.0), 0, 3)
	elif crouching:
		# abajo: se tira al suelo (un instante) y queda cuerpo a tierra; moviéndose, se arrastra
		if prone_t < GO_PRONE_T and body.sprite_frames.has_animation("go_prone"):
			body.animation = "go_prone"
		elif moving and body.sprite_frames.has_animation("crawl"):
			_play(body, "crawl")
		else:
			body.animation = "prone"
			body.frame = 1 if flash_t > 0.0 else 0
	elif _aim_pose(on_floor, moving):
		pass
	elif not on_floor:
		body.animation = "jump"
		body.frame = 0 if velocity.y < 0.0 else 1
	elif moving:
		_play(body, "run")
	elif shoot_pose_t > 0.0:
		# disparando quieto: fogonazo pequeño y grande alternos, y la pose de retroceso entre tiros
		body.animation = "shoot"
		body.frame = (1 + shot_n % 2) if flash_t > 0.0 else 3
	else:
		_play(body, "idle")
	fx.queue_redraw()


## Fogonazo dibujado de cuerpo entero en la boca del arma (pequeño y grande alternos). false si no hay para esta dirección.
func _draw_body_flash(m: Vector2) -> bool:
	if flash_tex == null:
		return false
	var f: Dictionary = body_meta["flash"]
	var key := _aim_key()
	if not f["rows"].has(key):
		return false
	var size := SpriteUtil.v(f["frame"])
	var anchor := SpriteUtil.v(f["anchor"])
	var src := Rect2(Vector2((shot_n % 2) * size.x, f["rows"][key] * size.y), size)
	fx.draw_set_transform(m, 0.0, Vector2(facing, 1))
	fx.draw_texture_rect_region(flash_tex, Rect2(-anchor, size), src)
	fx.draw_set_transform(Vector2.ZERO)
	return true


## Poses de apuntar arriba, en diagonal hacia arriba o (en el aire) en diagonal hacia abajo, si la hoja las tiene.
## Quieto o en el aire: fotograma 0 en reposo y 1 con el retroceso del disparo. Corriendo: <pose>_run en bucle.
func _aim_pose(on_floor: bool, moving: bool) -> bool:
	var key := _aim_key()
	if key == "fwd" or key == "down" or not body.sprite_frames.has_animation(key):
		return false
	if moving and on_floor and body.sprite_frames.has_animation(key + "_run"):
		_play(body, key + "_run")
	else:
		body.animation = key
		body.frame = 1 if flash_t > 0.0 else 0
	return true
