extends Node2D
## Menú principal: jugar, elegir misión, controles y salir. Muestra el récord.

const City = preload("res://scripts/city.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Levels = preload("res://scripts/levels.gd")

const PixelFont = preload("res://scripts/pixel_font.gd")
const LogoText = preload("res://scripts/logo_text.gd")

## Controles: acción (texto blanco) y teclas (dorado), alineados en columnas con la fuente monoespaciada.
const CONTROLS := [
	["Moverse", "Flechas / WASD"], ["Apuntar arriba", "Arriba"], ["Disparar abajo (aire)", "Abajo"],
	["Saltar", "Z / Espacio / K"], ["Disparar / cuchillo", "X / J"], ["Granada", "C / L"],
	["Agacharse", "Abajo"], ["Bajar de un puente", "Abajo + Saltar"], ["Pausa", "Esc"],
]
const PAD_TEXT := "Mando: cruceta o stick - A saltar - X disparar - B/Y granada - Start pausa"

var city := City.new()
var page := "main"
var items: Array = []
var sel := 0
var t := 0.0
var boom_t := 1.0
var title := LogoText.new()
var title2 := LogoText.new()
var item_labels: Array[Label] = []
var info_left := Label.new()
var info_right := Label.new()
var pad := Label.new()
var footer := Label.new()
var ui := CanvasLayer.new()


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

	add_child(ui)
	for lt in [title, title2]:
		lt.style = "big_gold"
		lt.z_index = 6
		add_child(lt)
	for l in [info_left, info_right, pad, footer]:
		l.size = Vector2(480, 270)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui.add_child(l)
	title.text = "CONTRA"
	title.position = Vector2(240, 6)
	title2.text = "TYPEBEAT"
	title2.position = Vector2(240, 54)
	# controles en dos columnas
	var left := []
	var right := []
	for c in CONTROLS:
		left.append(c[0] + " " + ".".repeat(22 - c[0].length()))
		right.append(c[1])
	info_left.text = "\n".join(left)
	info_right.text = "\n".join(right)
	for l in [info_left, info_right]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.position.y = 40
	PixelFont.apply(info_left, "white")
	PixelFont.apply(info_right, "small")
	info_left.position.x = 80
	info_right.position.x = 80 + 24 * 6
	pad.text = PAD_TEXT
	PixelFont.apply(pad, "label")
	pad.position.y = 172
	footer.text = "RÉCORD %06d          G·E STUDIOS - 2026 - v0.6" % Game.record
	PixelFont.apply(footer, "label")
	footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	footer.position.y = -4
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
	# una etiqueta por opción: la elegida en dorado con flechas que parpadean, el resto en blanco
	while item_labels.size() < items.size():
		var l := Label.new()
		l.size = Vector2(480, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui.add_child(l)
		item_labels.append(l)
	var top := 214.0 if page == "controls" else 112.0
	for i in item_labels.size():
		var l := item_labels[i]
		l.visible = i < items.size()
		if not l.visible:
			continue
		var chosen := i == sel
		var arrows := int(t * 4.0) % 2 == 0
		l.text = ("> %s" if chosen and arrows else ("%s" if not chosen else "  %s")) % items[i]
		PixelFont.apply(l, "small" if chosen else "white")
		l.position.y = top + i * 14
	var controls := page == "controls"
	for l in [info_left, info_right, pad]:
		l.visible = controls
	title.visible = not controls
	title2.visible = not controls


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
