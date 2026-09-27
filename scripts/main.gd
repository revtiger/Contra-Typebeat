extends Node2D
## Nivel 1 "Jungla": construye el nivel, la cámara, el HUD y controla el estado de la partida.

const Player = preload("res://scripts/player.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Turret = preload("res://scripts/turret.gd")
const Boss = preload("res://scripts/boss.gd")
const Pickup = preload("res://scripts/pickup.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Background = preload("res://scripts/background.gd")
const Explosion = preload("res://scripts/explosion.gd")

const SCREEN_W := 480.0
const SCREEN_H := 270.0
const LEVEL_END := 4300.0
const BOSS_ARENA := LEVEL_END - SCREEN_W
const START_LIVES := 3

# [x_inicio, x_fin, y_superficie]; los huecos entre tramos son fosos con agua.
const GROUND := [
	[0, 900, 230], [948, 1500, 230], [1500, 1900, 200], [1948, 2600, 230],
	[2648, 3400, 230], [3440, 4300, 230],
]
# Puentes que se atraviesan desde abajo: [x, ancho, y].
const PLATFORMS := [
	[300, 120, 175], [600, 110, 175], [680, 80, 125], [1080, 150, 175], [1250, 90, 125],
	[1560, 100, 150], [2080, 120, 175], [2240, 120, 125], [2780, 160, 175], [2900, 110, 125],
	[3600, 120, 175],
]
# Enemigos y objetos colocados; aparecen cuando la cámara se acerca a su x.
const ENTITIES := [
	["sniper", 340, 175], ["turret", 700, 230], ["capsule", 900, 0, "M"], ["sniper", 1130, 175],
	["turret", 1250, 230], ["sniper", 1280, 125], ["turret", 1720, 200], ["sniper", 1600, 150],
	["turret", 2290, 125], ["sniper", 2120, 175], ["turret", 2450, 230], ["capsule", 2600, 0, "S"],
	["sniper", 2820, 175], ["turret", 3000, 230], ["turret", 2950, 125], ["sniper", 3500, 230],
	["sniper", 3640, 175], ["boss", 4190, 230],
]

var player
var boss
var camera := Camera2D.new()
var cam_left := 0.0
var score := 0
var lives := START_LIVES
var state := "play"  # play | over | clear
var spawn_t := 2.5
var next_entity := 0
var entities := ENTITIES.duplicate()
var hud := Label.new()
var banner := Label.new()
var banner_t := 2.0


func _ready() -> void:
	add_to_group("main")
	entities.sort_custom(func(a, b): return a[1] < b[1])
	_setup_input()
	RenderingServer.set_default_clear_color(Color(0.1, 0.1, 0.2))

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := Background.new()
	sky.kind = "sky"
	sky_layer.add_child(sky)
	add_child(sky_layer)
	for k in [["mountains", 0.85, -9], ["jungle", 0.55, -8], ["water", 0.0, -5]]:
		var bg := Background.new()
		bg.kind = k[0]
		bg.factor = k[1]
		bg.z_index = k[2]
		add_child(bg)

	for g in GROUND:
		_add_block(Rect2(g[0], g[2], g[1] - g[0], 320 - g[2]), false)
	for p in PLATFORMS:
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
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		ui.add_child(l)
	hud.position = Vector2(6, 4)
	banner.size = Vector2(SCREEN_W, SCREEN_H)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 20)
	banner.text = "MISIÓN 1: JUNGLA"


func _setup_input() -> void:
	var keys := {
		"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
		"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S],
		"jump": [KEY_Z, KEY_SPACE, KEY_K], "shoot": [KEY_X, KEY_J],
		"restart": [KEY_ENTER, KEY_R],
	}
	var pad := {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A], "shoot": [JOY_BUTTON_X, JOY_BUTTON_B], "restart": [JOY_BUTTON_START],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in pad[action]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)


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
	body.add_child(vis)
	add_child(body)


func _physics_process(delta: float) -> void:
	if not player.dead:
		cam_left = clampf(maxf(cam_left, player.position.x - SCREEN_W * 0.4), 0.0, BOSS_ARENA)
	camera.position = Vector2(roundf(cam_left), 0)
	player.cam_left = cam_left

	_spawn_entities()
	if state == "play" and cam_left < BOSS_ARENA - 150:
		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = randf_range(1.0, 2.4)
			var from_left := randf() < 0.2
			var s := Soldier.new()
			s.dir = 1 if from_left else -1
			s.position = Vector2(cam_left - 10 if from_left else cam_left + SCREEN_W + 10, 90)
			add_child(s)

	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0 and state == "play":
			banner.text = ""
	if state != "play" and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	var w: String = {"N": "Normal", "M": "Metralleta", "S": "Spread"}[player.weapon]
	hud.text = "VIDAS %s   PUNTOS %06d   ARMA %s" % ["♥".repeat(maxi(lives, 0)), score, w]


func _spawn_entities() -> void:
	while next_entity < entities.size() and entities[next_entity][1] < cam_left + SCREEN_W + 40:
		var e: Array = entities[next_entity]
		next_entity += 1
		var n
		match e[0]:
			"sniper":
				n = Soldier.new()
				n.mode = "sniper"
			"turret":
				n = Turret.new()
			"boss":
				n = Boss.new()
				boss = n
			"capsule":
				n = Pickup.new()
				n.weapon = e[3]
				e = ["capsule", cam_left - 10, 60]
		n.position = Vector2(e[1], e[2])
		add_child(n)


func ground_y_at(x: float) -> float:
	for g in GROUND:
		if x >= g[0] and x <= g[1]:
			return g[2]
	return 999.0


func safe_x(x: float) -> float:
	for g in GROUND:
		if x < g[0]:
			return g[0] + 20.0
		if x <= g[1] - 10:
			return x
	return x


func add_score(n: int) -> void:
	score += n


func explode(pos: Vector2, radius := 12.0) -> void:
	var e := Explosion.new()
	e.position = pos
	e.r = radius
	add_child(e)


func _on_player_died() -> void:
	lives -= 1
	if lives <= 0:
		state = "over"
		banner.text = "GAME OVER\nPuntos: %d\n\nEnter para reintentar" % score
		return
	player.respawn(Vector2(safe_x(cam_left + 50), 20))


func stage_clear() -> void:
	state = "clear"
	banner.text = "¡MISIÓN CUMPLIDA!\nPuntos: %d\n\nEnter para jugar otra vez" % score
