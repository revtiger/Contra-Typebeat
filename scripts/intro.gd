extends Node2D
## Intro estilo póster de "Duro de matar": ciudad de noche, el rascacielos estalla, entran las caras
## del reparto con traje, una frase y el logo cae con una explosión. Cualquier botón la salta.

const City = preload("res://scripts/city.gd")
const Portrait = preload("res://scripts/portrait.gd")
const Explosion = preload("res://scripts/explosion.gd")

const T_CREDITS := 2.4
const T_BLAST := 3.6
const T_FACES := 4.6
const FACE_GAP := 0.6
const T_STORY := 7.4
const T_LOGO := 10.4
const T_END := 13.5
const TAGLINE := "AÑO 2087. EL GENERAL ZARKO TOMÓ EL CONTINENTE.\nSOLO DOS SOLDADOS PUEDEN DETENERLO."

## Reparto: nombre y aspecto de cada cara. Para cambiarlos, edita aquí.
const CAST := [
	{"name": "GWYN", "hair": Color(0.35, 0.22, 0.12), "style": "short", "stubble": true,
		"suit": Color(0.14, 0.14, 0.18), "tie": Color(0.75, 0.1, 0.1)},
	{"name": "EDUARDO", "hair": Color(0.08, 0.07, 0.07), "style": "slick", "sunglasses": true,
		"skin": Color(0.8, 0.58, 0.42), "suit": Color(0.1, 0.12, 0.25), "tie": Color(0.05, 0.05, 0.05)},
	{"name": "GRAL. ZARKO", "hair": Color(0.55, 0.55, 0.55), "style": "bald", "beard": true, "scar": true,
		"skin": Color(0.88, 0.7, 0.58), "suit": Color(0.05, 0.05, 0.06), "tie": Color(0.55, 0.05, 0.05)},
	{"name": "EL SOCIO", "hair": Color(0.9, 0.78, 0.4), "style": "long",
		"suit": Color(0.35, 0.36, 0.38), "tie": Color(0.1, 0.45, 0.2)},
]

var t := 0.0
var city := City.new()
var dim := ColorRect.new()
var faces: Array = []
var names: Array = []
var credits := Label.new()
var story := Label.new()
var logo := Label.new()
var logo2 := Label.new()
var skip := Label.new()
var shown_chars := 0
var blasted := false
var logo_hit := false
var next_face := 0
var shake := 0.0
var flash := 0.0
var boom_t := 0.0
var flash_rect := ColorRect.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	add_child(city)
	dim.color = Color.BLACK
	dim.size = Vector2(480, 270)
	add_child(dim)

	for i in CAST.size():
		var c: Dictionary = CAST[i]
		var p := Portrait.new()
		p.hair = c["hair"]
		p.hair_style = c["style"]
		p.suit = c["suit"]
		p.tie = c["tie"]
		p.skin = c.get("skin", p.skin)
		p.beard = c.get("beard", false)
		p.stubble = c.get("stubble", false)
		p.sunglasses = c.get("sunglasses", false)
		p.scar = c.get("scar", false)
		p.position = Vector2(36 + i * 108, 14)
		p.visible = false
		p.z_index = 20
		add_child(p)
		faces.append(p)

	flash_rect.size = Vector2(500, 290)
	flash_rect.position = Vector2(-10, -10)
	flash_rect.color = Color(1, 0.95, 0.85, 0)
	flash_rect.z_index = 30
	add_child(flash_rect)

	var ui := CanvasLayer.new()
	add_child(ui)
	for i in CAST.size():
		var n := Label.new()
		n.text = CAST[i]["name"]
		n.size = Vector2(90, 12)
		n.position = Vector2(36 + i * 108 - 15, 90)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", 9)
		n.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
		n.add_theme_color_override("font_outline_color", Color.BLACK)
		n.add_theme_constant_override("outline_size", 4)
		n.visible = false
		ui.add_child(n)
		names.append(n)
	for l in [credits, story, logo, logo2, skip]:
		l.size = Vector2(480, 270)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 6)
		ui.add_child(l)
	credits.text = "GWYN & EDUARDO\n\npresentan"
	credits.add_theme_font_size_override("font_size", 16)
	story.add_theme_font_size_override("font_size", 10)
	story.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	story.position.y = 110
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	story.position.x = 14
	logo.text = "CONTRA"
	logo.add_theme_font_size_override("font_size", 46)
	logo.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
	logo.position = Vector2(-60, 62)
	logo2.text = "TYPEBEAT"
	logo2.add_theme_font_size_override("font_size", 24)
	logo2.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	logo2.position = Vector2(-60, 104)
	logo.visible = false
	logo2.visible = false
	skip.text = "cualquier botón para saltar"
	skip.add_theme_font_size_override("font_size", 8)
	skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	skip.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	skip.position.y = -2
	Game.play_music("menu")


func _unhandled_input(event: InputEvent) -> void:
	if t > 0.3 and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		Game.to_menu()


func _boom(pos: Vector2, r: float, sound := true) -> void:
	var e := Explosion.new()
	e.position = pos
	e.r = r
	add_child(e)
	if sound:
		Game.sfx("boom" if r >= 18.0 else "small_boom", -6.0 if r >= 18.0 else -12.0, randf_range(0.7, 1.0))


func _process(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta * 3.0, 0.0)
	shake = maxf(shake - delta * 10.0, 0.0)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake
	credits.modulate.a = clampf(minf(t / 0.6, (T_CREDITS - t) / 0.6), 0.0, 1.0)

	# la ciudad aparece
	if t > T_CREDITS:
		dim.color.a = 1.0 - clampf((t - T_CREDITS) / 1.0, 0.0, 0.85)

	# el rascacielos estalla
	if t > T_BLAST and not blasted:
		blasted = true
		city.burning = true
		flash = 0.8
		shake = 5.0
		Game.sfx("boom", 2.0, 0.75)
		var top := city.tower_top()
		for i in 7:
			_boom(top + Vector2(randf_range(-40, 40), randf_range(-10, 45)), randf_range(14, 30), i == 0)
	if blasted:
		boom_t -= delta
		if boom_t <= 0.0:
			boom_t = randf_range(0.5, 1.3)
			_boom(city.tower_top() + Vector2(randf_range(-34, 34), randf_range(0, 50)), randf_range(8, 16), false)

	# entran las caras
	if next_face < faces.size() and t > T_FACES + next_face * FACE_GAP:
		faces[next_face].visible = true
		names[next_face].visible = true
		faces[next_face].scale = Vector2.ONE * 1.3
		Game.sfx("cannon", -4.0, 0.9 + next_face * 0.08)
		shake = 2.0
		next_face += 1
	for f in faces:
		if f.visible:
			f.scale = f.scale.lerp(Vector2.ONE, 12.0 * delta)

	# frase
	if t > T_STORY:
		var n := mini(int((t - T_STORY) * 30.0), TAGLINE.length())
		if n > shown_chars:
			shown_chars = n
			if TAGLINE[n - 1] != " " and TAGLINE[n - 1] != "\n":
				Game.sfx("type", -12.0)
		story.text = TAGLINE.substr(0, shown_chars)

	# logo
	if t >= T_LOGO:
		if not logo_hit:
			logo_hit = true
			logo.visible = true
			logo2.visible = true
			flash = 1.0
			shake = 6.0
			Game.sfx("boom", 0.0, 0.8)
			for i in 4:
				_boom(Vector2(180 + randf_range(-110, 110), 205 + randf_range(-20, 20)), randf_range(14, 26), false)
		var k := clampf((t - T_LOGO) / 0.25, 0.0, 1.0)
		logo.pivot_offset = Vector2(240, 135)
		logo.scale = Vector2.ONE * lerpf(2.5, 1.0, k)
		logo2.modulate.a = clampf((t - T_LOGO - 0.4) / 0.4, 0.0, 1.0)
	flash_rect.color.a = flash * 0.8
	if t > T_END:
		Game.to_menu()
