extends Node2D
## Menú principal: jugar, elegir misión, controles y salir. Muestra el récord.

const City = preload("res://scripts/city.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Levels = preload("res://scripts/levels.gd")

const CONTROLS := "Moverse ...................... Flechas o WASD
Apuntar arriba ............. Arriba
Disparar abajo (en el aire) .. Abajo
Saltar ....................... Z, Espacio o K
Disparar / cuchillo ........ X o J
Granada .................... C o L
Agacharse .................. Abajo
Bajar de un puente ........ Abajo + Saltar
Pausa ....................... Esc

Mando: cruceta o stick, A saltar, X disparar, B/Y granada, Start pausa"

var city := City.new()
var page := "main"
var items: Array = []
var sel := 0
var t := 0.0
var boom_t := 1.0
var title := Label.new()
var title2 := Label.new()
var list := Label.new()
var info := Label.new()
var footer := Label.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	city.burning = true
	city.burn_t = 5.0
	add_child(city)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.3)
	shade.size = Vector2(480, 270)
	shade.z_index = 5
	add_child(shade)

	var ui := CanvasLayer.new()
	add_child(ui)
	for l in [title, title2, list, info, footer]:
		l.size = Vector2(480, 270)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		ui.add_child(l)
	title.text = "CONTRA"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
	title.position.y = 14
	title2.text = "TYPEBEAT"
	title2.add_theme_font_size_override("font_size", 22)
	title2.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title2.position.y = 64
	list.add_theme_font_size_override("font_size", 14)
	list.position.y = 112
	list.add_theme_constant_override("line_spacing", 2)
	info.add_theme_font_size_override("font_size", 9)
	info.position.y = 60
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.position.x = 90
	footer.add_theme_font_size_override("font_size", 8)
	footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	footer.position.y = -4
	footer.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	footer.text = "RÉCORD %06d          Gwyn & Eduardo · 2026 · v0.4" % Game.record
	_open("main")
	Game.play_music("menu")


func _open(p: String) -> void:
	page = p
	sel = 0
	match p:
		"main":
			items = ["JUGAR", "ELEGIR MISIÓN", "CONTROLES", "VER INTRO", "SALIR"]
		"levels":
			items = []
			for l in Levels.LIST:
				items.append(l["name"])
			items.append("VOLVER")
		"controls":
			items = ["VOLVER"]
	_refresh()


func _refresh() -> void:
	var lines := []
	for i in items.size():
		var blink := i == sel and int(t * 4.0) % 2 == 0
		lines.append(("▶ %s ◀" if blink else ("  %s  " if i != sel else "▷ %s ◁")) % items[i])
	list.text = "\n".join(lines)
	info.visible = page == "controls"
	info.text = CONTROLS
	list.position.y = 226 if page == "controls" else 112
	title.visible = page != "controls"
	title2.visible = page != "controls"


func _process(delta: float) -> void:
	t += delta
	boom_t -= delta
	if boom_t <= 0.0:
		boom_t = randf_range(0.6, 1.6)
		var e := Explosion.new()
		e.position = city.tower_top() + Vector2(randf_range(-34, 34), randf_range(0, 50))
		e.r = randf_range(8, 18)
		add_child(e)

	if Input.is_action_just_pressed("up"):
		sel = (sel - 1 + items.size()) % items.size()
		Game.sfx("move", -8.0)
	elif Input.is_action_just_pressed("down"):
		sel = (sel + 1) % items.size()
		Game.sfx("move", -8.0)
	elif Game.accept_pressed():
		Game.sfx("select", -4.0)
		_choose(items[sel])
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("quit_menu"):
		if page != "main":
			_open("main")
	_refresh()


func _choose(item: String) -> void:
	match page:
		"main":
			match item:
				"JUGAR": Game.start_game(0)
				"ELEGIR MISIÓN": _open("levels")
				"CONTROLES": _open("controls")
				"VER INTRO": Game.go_intro()
				"SALIR": get_tree().quit()
		"levels":
			if item == "VOLVER":
				_open("main")
			else:
				Game.start_game(sel)
		"controls":
			_open("main")
