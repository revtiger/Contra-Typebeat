extends Node2D
## Escena de una misión: construye el nivel desde levels.gd, cámara, HUD, explosiones y estado de la partida.

const Levels = preload("res://scripts/levels.gd")
const Player = preload("res://scripts/player.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Turret = preload("res://scripts/turret.gd")
const Boss = preload("res://scripts/boss.gd")
const Heli = preload("res://scripts/heli.gd")
const Tank = preload("res://scripts/tank.gd")
const Barrel = preload("res://scripts/barrel.gd")
const Mine = preload("res://scripts/mine.gd")
const Jet = preload("res://scripts/jet.gd")
const Miniboss = preload("res://scripts/miniboss.gd")
const Pickup = preload("res://scripts/pickup.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Background = preload("res://scripts/background.gd")
const Explosion = preload("res://scripts/explosion.gd")

const SCREEN_W := 480.0
const SCREEN_H := 270.0

var data: Dictionary
var theme := "jungle"
var ground: Array
var level_end := 0.0
var boss_arena := 0.0
var entities: Array
var player
var boss
var camera := Camera2D.new()
var cam_left := 0.0
var shake_amt := 0.0
var lock_left := INF
var boss_announced := false
var state := "play"  # play | over | clear
var spawn_t := 2.5
var next_entity := 0
var hud := Label.new()
var banner := Label.new()
var banner_t := 2.5


func _ready() -> void:
	add_to_group("level")
	add_to_group("main")
	data = Levels.LIST[Game.level]
	theme = data["theme"]
	ground = data["ground"]
	level_end = data["end"]
	boss_arena = level_end - SCREEN_W
	entities = data["entities"].duplicate()
	entities.sort_custom(func(a, b): return a[1] < b[1])
	RenderingServer.set_default_clear_color(Color.BLACK)

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := Background.new()
	sky.kind = "sky"
	sky.theme = theme
	sky.main = self
	sky_layer.add_child(sky)
	add_child(sky_layer)
	var layers := [["mountains", 0.85, -9], ["jungle", 0.55, -8], ["water", 0.0, -5]]
	if theme == "desert":
		layers = [["mesas", 0.85, -9], ["dunes", 0.55, -8], ["chasm", 0.0, -5]]
	for k in layers:
		var bg := Background.new()
		bg.kind = k[0]
		bg.factor = k[1]
		bg.z_index = k[2]
		bg.theme = theme
		bg.main = self
		add_child(bg)

	for g in ground:
		_add_block(Rect2(g[0], g[2], g[1] - g[0], 320 - g[2]), false)
	for p in data["platforms"]:
		_add_block(Rect2(p[0], p[2], p[1], 8), true)

	player = Player.new()
	player.position = Vector2(60, 200)
	player.died.connect(_on_player_died)
	add_child(player)

	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	for l in [hud, banner]:
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		ui.add_child(l)
	hud.position = Vector2(6, 3)
	banner.size = Vector2(SCREEN_W, SCREEN_H)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 20)
	banner.text = data["name"] + "\n¡VAMOS!"
	Game.play_music(data["music"])


func _add_block(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8 if one_way else 1
	body.collision_mask = 0
	body.position = rect.position
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = rect.size
	cs.shape = sh
	cs.position = rect.size / 2
	cs.one_way_collision = one_way
	body.add_child(cs)
	var vis := Terrain.new()
	vis.size = rect.size
	vis.one_way = one_way
	vis.theme = theme
	body.add_child(vis)
	add_child(body)


func _physics_process(delta: float) -> void:
	if not player.dead:
		cam_left = clampf(maxf(cam_left, player.position.x - SCREEN_W * 0.4), 0.0, minf(boss_arena, lock_left))
	shake_amt = maxf(shake_amt - 18.0 * delta, 0.0)
	camera.position = Vector2(roundf(cam_left), 0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake_amt
	player.cam_left = cam_left

	_spawn_entities()
	if state == "play" and cam_left < boss_arena - 150:
		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = randf_range(1.0, 2.4)
			var from_left := randf() < 0.2
			var s := Soldier.new()
			s.dir = 1 if from_left else -1
			s.position = Vector2(cam_left - 10 if from_left else cam_left + SCREEN_W + 10, 90)
			add_child(s)
	if boss and cam_left >= boss_arena - 1.0 and state == "play" and not boss_announced:
		boss_announced = true
		Game.play_music("boss")
		show_banner("¡JEFE FINAL!\n" + data["boss_name"], 2.0)

	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0 and state == "play":
			banner.text = ""

	if state == "over":
		if Input.is_action_just_pressed("restart"):
			Game.retry_level()
		elif Input.is_action_just_pressed("quit_menu"):
			Game.to_menu()
	elif state == "clear" and banner_t <= 0.0 and Game.accept_pressed():
		Game.next_level()

	hud.text = "VIDAS %s   PUNTOS %06d   RÉCORD %06d\nARMA %s" % [
		"♥".repeat(maxi(Game.lives, 0)), Game.score, Game.record, Game.WEAPON_NAMES[player.weapon]]


func _spawn_entities() -> void:
	while next_entity < entities.size() and entities[next_entity][1] < cam_left + SCREEN_W + 40:
		var e: Array = entities[next_entity]
		next_entity += 1
		var n
		var pos := Vector2(e[1], e[2])
		match e[0]:
			"sniper":
				n = Soldier.new()
				n.mode = "sniper"
			"turret":
				n = Turret.new()
			"barrel":
				n = Barrel.new()
			"mine":
				n = Mine.new()
			"tank":
				n = Tank.new()
			"miniboss":
				n = Miniboss.new()
				n.kind = e[3]
			"jet":
				n = Jet.new()
				pos = Vector2(cam_left + SCREEN_W + 40, 26)
			"boss":
				n = Boss.new() if e[3] == "wall" else Heli.new()
				boss = n
			"capsule":
				n = Pickup.new()
				n.weapon = e[3]
				pos = Vector2(cam_left - 10, e[2])
		n.position = pos
		add_child(n)


func ground_y_at(x: float) -> float:
	for g in ground:
		if x >= g[0] and x <= g[1]:
			return g[2]
	return 999.0


func safe_x(x: float) -> float:
	for g in ground:
		if x < g[0]:
			return g[0] + 20.0
		if x <= g[1] - 10:
			return x
	return x


func show_banner(text: String, duration: float) -> void:
	if state == "play":
		banner.text = text
		banner_t = duration


## Bloquea la cámara en x (mini jefe) hasta que se llame a unlock_camera().
func lock_camera(x: float, title: String) -> void:
	lock_left = x
	show_banner("¡ALERTA!\n" + title, 2.0)
	Game.play_music("boss")


func unlock_camera() -> void:
	lock_left = INF
	show_banner("¡MINI JEFE DERROTADO!", 1.5)
	Game.play_music(data["music"])


func add_score(n: int) -> void:
	Game.add_score(n)


func shake(amount: float) -> void:
	shake_amt = minf(maxf(shake_amt, amount), 6.0)


## Efecto visual de explosión, con sonido y temblor proporcionales al tamaño.
func explode(pos: Vector2, radius := 12.0, sound := true) -> void:
	var e := Explosion.new()
	e.position = pos
	e.r = radius
	add_child(e)
	if sound:
		if radius >= 20.0:
			Game.sfx("boom", -4.0, randf_range(0.85, 1.1))
		else:
			Game.sfx("small_boom", -9.0, randf_range(0.9, 1.2))
	shake(radius * 0.12)


## Explosión que hace daño: a enemigos y objetos en el radio y, si hurt_player, al jugador.
func blast(pos: Vector2, radius: float, hurt_player := true, damage := 5) -> void:
	explode(pos, radius)
	for n in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("prop"):
		if n.has_method("take_damage") and n.global_position.distance_to(pos) < radius + 8.0:
			n.call_deferred("take_damage", damage)
	if hurt_player and (player.position + Vector2(0, -10)).distance_to(pos) < radius * 0.75:
		player.hit()


func _on_player_died() -> void:
	Game.lives -= 1
	if Game.lives <= 0:
		state = "over"
		Game.save_record()
		Game.stop_music()
		banner.text = "GAME OVER\nPuntos: %d\n\nEnter: reintentar   Q: menú" % Game.score
		return
	player.respawn(Vector2(safe_x(cam_left + 50), 20))


func stage_clear() -> void:
	if state != "play":
		return
	state = "clear"
	banner_t = 1.5
	Game.save_record()
	Game.stop_music()
	Game.sfx("pickup")
	banner.text = "¡MISIÓN CUMPLIDA!\nPuntos: %d   Récord: %d\n\nPulsa para ver el mapa" % [Game.score, Game.record]
