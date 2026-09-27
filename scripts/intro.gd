extends Node2D
## Intro al estilo de Metal Slug 2 (sin caras ni nombres de personajes):
## 1. Pantalla de presentación tipo NEO GEO (parodia: "MAX 480x270 PIXEL POWER")
## 2. Fondo negro: las letras de ONU caen de una en una, gigantes y en piedra, y después OUTBREAK
## 3. Fogonazo blanco y todo pasa a color: letras doradas sobre cielo azul, "SUPER SOLDADO-001",
##    "PULSA START" y el copyright. Después va al menú. Cualquier botón la salta.

const Explosion = preload("res://scripts/explosion.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const LogoText = preload("res://scripts/logo_text.gd")

const T_SPLASH_END := 2.6
const T_WORD1 := 3.2
const T_WORD2 := 4.9
const T_WORD2_AT := 4.6
const T_FLASH := 6.4
const T_END := 13.0

var t := 0.0
var shake := 0.0
var flash := 0.0
var colored := false
var bg := Node2D.new()
var word1 := LogoText.new()
var word2 := LogoText.new()
var gold1 := LogoText.new()
var gold2 := LogoText.new()
var flash_rect := ColorRect.new()
var splash := Node2D.new()
var ui := CanvasLayer.new()
var splash_title := Label.new()
var splash_sub := Label.new()
var subtitle := Label.new()
var press := Label.new()
var copyright := Label.new()
var credit := Label.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	# fondo a color (aparece con el fogonazo): cielo azul degradado y la ciudad en llamas abajo
	bg.visible = false
	bg.draw.connect(_draw_sky)
	add_child(bg)

	for w in [word1, word2, gold1, gold2]:
		w.position.x = 240
		add_child(w)
	word1.text = "ONU"
	word1.style = "big_stone"
	word1.position.y = 16
	word1.scale = Vector2(2, 2)
	word1.reveal_at = T_WORD1
	word1.interval = 0.42
	word2.text = "OUTBREAK"
	word2.position.y = 124
	word2.reveal_at = T_WORD2_AT
	word2.interval = 0.12
	word2.style = "big_stone"
	for w in [word1, word2]:
		w.letter_landed.connect(_on_letter)
	gold1.text = "ONU"
	gold1.style = "big_gold"
	gold1.position.y = 16
	gold1.scale = Vector2(2, 2)
	gold2.text = "OUTBREAK"
	gold2.position.y = 124
	gold2.style = "big_gold"
	gold1.visible = false
	gold2.visible = false

	flash_rect.size = Vector2(500, 290)
	flash_rect.position = Vector2(-10, -10)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.z_index = 30
	add_child(flash_rect)

	# pantalla de presentación (fondo claro, logo negro, como la de NEO GEO)
	splash.draw.connect(_draw_splash)
	splash.z_index = 20
	add_child(splash)

	add_child(ui)
	for l in [splash_title, splash_sub, subtitle, press, copyright, credit]:
		l.size = Vector2(480, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui.add_child(l)
	splash_title.text = "G·E"
	PixelFont.apply(splash_title, "title", 4)
	splash_title.size.y = 80
	splash_title.position.y = 70
	splash_title.modulate = Color(0.08, 0.08, 0.12)
	splash_sub.text = "MAX 480x270 PIXEL POWER\nPRO-SOLDIER SPEC"
	PixelFont.apply(splash_sub, "white")
	splash_sub.size.y = 40
	splash_sub.position.y = 150
	splash_sub.modulate = Color(0.1, 0.1, 0.15)
	subtitle.text = "SUPER SOLDADO-001"
	PixelFont.apply(subtitle, "small")
	subtitle.position.y = 182
	press.text = "PULSA START"
	PixelFont.apply(press, "white")
	press.position.y = 206
	copyright.text = "(C) 2026 G·E STUDIOS"
	PixelFont.apply(copyright, "label")
	copyright.position.y = 226
	credit.text = "CREDITO 0"
	PixelFont.apply(credit, "white")
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit.size.x = 470
	credit.position.y = 252
	for l in [subtitle, press, copyright, credit]:
		l.visible = false
	Game.stop_music()


func _unhandled_input(event: InputEvent) -> void:
	if t > 0.3 and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		Game.to_menu()


func _on_letter(_i: int, pos: Vector2) -> void:
	shake = 5.0
	Game.sfx("cannon", -6.0, randf_range(0.8, 1.0))
	var e := Explosion.new()
	e.position = pos + Vector2(0, 10)
	e.r = 14.0
	add_child(e)


func _process(delta: float) -> void:
	t += delta
	shake = maxf(shake - delta * 12.0, 0.0)
	flash = maxf(flash - delta * 2.5, 0.0)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake
	for w in [word1, word2, gold1, gold2]:
		w.position.x = 240 + sh.x
	# presentación: aparece y se funde
	var a := clampf(minf(t / 0.4, (T_SPLASH_END - t) / 0.4), 0.0, 1.0)
	splash.visible = t < T_SPLASH_END
	splash.modulate.a = a
	splash_title.visible = splash.visible
	splash_sub.visible = splash.visible
	splash_title.modulate.a = a
	splash_sub.modulate.a = a
	# fogonazo: todo pasa a color
	if t >= T_FLASH and not colored:
		colored = true
		flash = 1.0
		Game.sfx("boom", 0.0, 0.7)
		Game.play_music("menu")
		bg.visible = true
		word1.visible = false
		word2.visible = false
		gold1.visible = true
		gold2.visible = true
		for l in [subtitle, copyright, credit]:
			l.visible = true
	if colored:
		press.visible = int(t * 2.0) % 2 == 0
		bg.queue_redraw()
	flash_rect.color.a = flash
	if t > T_END:
		Game.to_menu()


func _draw_splash() -> void:
	splash.draw_rect(Rect2(0, 0, 480, 270), Color(0.95, 0.95, 0.93))
	splash.draw_rect(Rect2(150, 186, 180, 3), Color(0.2, 0.3, 0.8))


func _draw_sky() -> void:
	var top := Color(0.1, 0.2, 0.55)
	var bottom := Color(0.45, 0.65, 0.95)
	bg.draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(480, 0), Vector2(480, 270), Vector2(0, 270)]),
		PackedColorArray([top, top, bottom, bottom]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 6:
		var cx := fmod(rng.randf() * 600.0 + t * rng.randf_range(4, 10), 600.0) - 60.0
		var cy := rng.randf_range(20, 150)
		for j in 4:
			bg.draw_circle(Vector2(cx + j * 14, cy + (j % 2) * 3), 10 + (j % 2) * 4, Color(1, 1, 1, 0.35))
	# horizonte con ruinas en silueta
	rng.seed = 12
	var x := -10.0
	while x < 490.0:
		var w := rng.randf_range(20, 50)
		var h := rng.randf_range(20, 60)
		bg.draw_rect(Rect2(x, 270 - h, w, h), Color(0.12, 0.18, 0.38))
		x += w + rng.randf_range(0, 8)
