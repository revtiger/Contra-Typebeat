extends Node2D
## Intro: créditos, historia a máquina de escribir con explosiones de fondo y el logo que cae con una explosión.
## Cualquier botón la salta (pilar "acción inmediata").

const Background = preload("res://scripts/background.gd")
const Explosion = preload("res://scripts/explosion.gd")

const STORY := "AÑO 2087.\n\nEl ejército del General Zarko ha tomado\nla Jungla de Galuga y el Desierto Rojo.\n\nSolo dos soldados pueden detenerlo."
const T_CREDITS := 2.4
const T_STORY := 9.0
const T_LOGO := 12.0

var t := 0.0
var cam_left := 0.0
var shown_chars := 0
var logo_hit := false
var boom_t := 0.5
var flash := 0.0
var credits := Label.new()
var story := Label.new()
var logo := Label.new()
var logo2 := Label.new()
var skip := Label.new()
var world := Node2D.new()
var dim := ColorRect.new()


func _ready() -> void:
	add_to_group("main")
	RenderingServer.set_default_clear_color(Color.BLACK)
	add_child(world)
	for k in [["sky", 0.0], ["mesas", 0.85], ["dunes", 0.55]]:
		var bg := Background.new()
		bg.kind = k[0]
		bg.factor = k[1]
		bg.theme = "desert"
		bg.screen_scroll = true
		bg.main = self
		world.add_child(bg)
	dim.color = Color.BLACK
	dim.size = Vector2(480, 270)
	add_child(dim)

	var ui := CanvasLayer.new()
	add_child(ui)
	for l in [credits, story, logo, logo2, skip]:
		l.size = Vector2(480, 270)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		ui.add_child(l)
	credits.text = "GWYN & EDUARDO\n\npresentan"
	credits.add_theme_font_size_override("font_size", 16)
	story.add_theme_font_size_override("font_size", 12)
	logo.text = "CONTRA"
	logo.add_theme_font_size_override("font_size", 52)
	logo.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
	logo.position.y = -30
	logo2.text = "TYPEBEAT"
	logo2.add_theme_font_size_override("font_size", 28)
	logo2.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	logo2.position.y = 20
	logo.visible = false
	logo2.visible = false
	skip.text = "cualquier botón para saltar"
	skip.add_theme_font_size_override("font_size", 8)
	skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	skip.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	skip.position.y = -4
	Game.play_music("menu")


func _unhandled_input(event: InputEvent) -> void:
	if t > 0.3 and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		Game.to_menu()


func _process(delta: float) -> void:
	t += delta
	cam_left += 30.0 * delta
	flash = maxf(flash - delta * 3.0, 0.0)
	credits.modulate.a = clampf(minf(t / 0.6, (T_CREDITS - t) / 0.6), 0.0, 1.0)

	if t > T_CREDITS and t < T_LOGO:
		dim.color.a = 1.0 - clampf((t - T_CREDITS) / 1.0, 0.0, 0.5)
		var n := mini(int((t - T_CREDITS - 0.5) * 28.0), STORY.length())
		if n > shown_chars:
			shown_chars = n
			if STORY[n - 1] != " " and STORY[n - 1] != "\n":
				Game.sfx("type", -12.0)
		story.text = STORY.substr(0, maxi(shown_chars, 0))
		boom_t -= delta
		if boom_t <= 0.0:
			boom_t = randf_range(0.5, 1.2)
			_explosion(Vector2(randf_range(40, 440), randf_range(170, 210)), randf_range(8, 16), -16.0)
	story.modulate.a = clampf((T_LOGO - 0.3 - t) / 0.5, 0.0, 1.0)

	if t >= T_LOGO:
		dim.color.a = 0.0
		if not logo_hit:
			logo_hit = true
			logo.visible = true
			logo2.visible = true
			flash = 1.0
			Game.sfx("boom", 0.0, 0.8)
			for i in 6:
				_explosion(Vector2(240 + randf_range(-150, 150), 110 + randf_range(-30, 40)), randf_range(14, 28), 99.0)
		var k := clampf((t - T_LOGO) / 0.25, 0.0, 1.0)
		logo.scale = Vector2.ONE * lerpf(2.5, 1.0, k)
		logo.pivot_offset = Vector2(240, 135)
		logo2.modulate.a = clampf((t - T_LOGO - 0.4) / 0.4, 0.0, 1.0)
		if t > T_LOGO + 2.5:
			Game.to_menu()
	queue_redraw()


func _explosion(pos: Vector2, r: float, vol: float) -> void:
	var e := Explosion.new()
	e.position = pos
	e.r = r
	add_child(e)
	if vol < 50.0:
		Game.sfx("small_boom", vol, randf_range(0.7, 1.0))


func _draw() -> void:
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 480, 270), Color(1, 1, 1, flash * 0.8))
