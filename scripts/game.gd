extends Node
## Autoload "Game": estado entre escenas (vidas, puntos, récord, misión), controles, audio y pausa.

const Levels = preload("res://scripts/levels.gd")
const Sfx = preload("res://scripts/sfx.gd")

const START_LIVES := 3
const RECORD_PATH := "user://record.cfg"
const WEAPON_NAMES := {"N": "Normal", "M": "Metralleta", "S": "Spread", "L": "Láser", "F": "Fuego"}
const SOUNDS := ["shot", "laser", "fire", "jump", "hit", "boom", "small_boom", "death", "pickup",
	"move", "select", "beep", "whistle", "cannon", "jet", "type"]

var score := 0
var lives := START_LIVES
var level := 0
var record := 0
var autoplay := false

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _sounds := {}
var _music := AudioStreamPlayer.new()
var _music_name := ""
var _pause_layer := CanvasLayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_record()
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	for s in SOUNDS:
		_sounds[s] = Sfx.make(s)
	_music.volume_db = -9.0
	add_child(_music)

	_pause_layer.layer = 100
	_pause_layer.visible = false
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.size = Vector2(480, 270)
	_pause_layer.add_child(shade)
	var l := Label.new()
	l.text = "PAUSA\n\nEsc / Start: continuar\nQ / Select: salir al menú"
	l.size = Vector2(480, 270)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 14)
	_pause_layer.add_child(l)
	add_child(_pause_layer)

	if "autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		add_child(load("res://tests/autoplay.gd").new())


func _setup_input() -> void:
	var keys := {
		"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
		"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S],
		"jump": [KEY_Z, KEY_SPACE, KEY_K], "shoot": [KEY_X, KEY_J],
		"restart": [KEY_ENTER, KEY_R], "pause": [KEY_ESCAPE, KEY_P], "quit_menu": [KEY_Q],
	}
	var pad := {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A], "shoot": [JOY_BUTTON_X, JOY_BUTTON_B],
		"restart": [JOY_BUTTON_START], "pause": [JOY_BUTTON_START], "quit_menu": [JOY_BUTTON_BACK],
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
	# Stick izquierdo del mando
	for a in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0],
			["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[1]
		jm.axis_value = a[2]
		InputMap.action_add_event(a[0], jm)


func accept_pressed() -> bool:
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot") \
		or Input.is_action_just_pressed("restart")


# ---------- flujo de partida ----------

func start_game(lv := 0) -> void:
	score = 0
	lives = START_LIVES
	level = lv
	_go("res://scenes/level.tscn")


func retry_level() -> void:
	score = 0
	lives = START_LIVES
	_go("res://scenes/level.tscn")


func has_next_level() -> bool:
	return level + 1 < Levels.LIST.size()


func next_level() -> void:
	level += 1
	_go("res://scenes/level.tscn")


func to_menu() -> void:
	save_record()
	_go("res://scenes/menu.tscn")


func _go(path: String) -> void:
	get_tree().paused = false
	_pause_layer.visible = false
	get_tree().change_scene_to_file.call_deferred(path)


func add_score(n: int) -> void:
	score += n
	record = maxi(record, score)


func _load_record() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RECORD_PATH) == OK:
		record = cfg.get_value("juego", "record", 0)


func save_record() -> void:
	if autoplay:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("juego", "record", record)
	cfg.save(RECORD_PATH)


# ---------- pausa ----------

func _unhandled_input(event: InputEvent) -> void:
	var scene = get_tree().current_scene
	if scene == null or not scene.is_in_group("level") or scene.state != "play":
		return
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_pause_layer.visible = get_tree().paused
		get_viewport().set_input_as_handled()
	elif get_tree().paused and event.is_action_pressed("quit_menu"):
		to_menu()


# ---------- audio ----------

func sfx(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _sounds[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	var key := "music_" + track
	if not _sounds.has(key):
		_sounds[key] = Sfx.music(track)
	_music.stream = _sounds[key]
	_music.play()


func stop_music() -> void:
	_music_name = ""
	_music.stop()
