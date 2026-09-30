extends Node2D
## ELIGE TU SOLDADO, al estilo de la pantalla "SOLDIER SELECT" de Metal Slug X:
## marco de acero remachado, título cincelado, cuatro ventanas con retrato (el elegido a color,
## el resto en sepia), placas con el nombre, cuenta atrás y PULSA START.

const PixelFont = preload("res://scripts/pixel_font.gd")
const LogoText = preload("res://scripts/logo_text.gd")

## id del soldado (sprites player_<id>_*.png) y nombre en la placa
## Los dos últimos son diseños de Eduardo (nombres provisionales)
const SOLDIERS := [["presi", "EL PRESI"], ["tenienta", "LA TENIENTA"], ["comando", "EL COMANDO"], ["hawaiano", "EL HAWAIANO"]]
const WIN := Vector2(84, 104)
const STEP := 92.0
const X0 := 60.0
const Y0 := 52.0
const PW := 72
const PH := 96

var sel := 0
var t := 0.0
var countdown := 30.0
var chosen_t := -1.0
var portraits: Texture2D
var title := LogoText.new()


func _ready() -> void:
	add_to_group("select")
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.06))
	portraits = load("res://assets/sprites/portraits.png")
	title.text = "ELIGE TU SOLDADO"
	title.style = "small_steel"
	title.position = Vector2(240, 12)
	add_child(title)
	for i in SOLDIERS.size():
		if SOLDIERS[i][0] == Game.hero:
			sel = i
	Game.play_music("menu")


func _process(delta: float) -> void:
	t += delta
	if chosen_t >= 0.0:
		chosen_t += delta
		if chosen_t > 1.3:
			Game.choose_hero(SOLDIERS[sel][0])
		queue_redraw()
		return
	countdown -= delta
	if Input.is_action_just_pressed("left"):
		sel = (sel - 1 + SOLDIERS.size()) % SOLDIERS.size()
		Game.sfx("move", -8.0)
	elif Input.is_action_just_pressed("right"):
		sel = (sel + 1) % SOLDIERS.size()
		Game.sfx("move", -8.0)
	elif Game.accept_pressed() or countdown <= 0.0:
		chosen_t = 0.0
		Game.sfx("select", -2.0)
		Game.sfx("cannon", -8.0, 1.2)
	elif Input.is_action_just_pressed("quit_menu") or Input.is_action_just_pressed("pause"):
		Game.to_menu()
	queue_redraw()


func _steel(r: Rect2, dark := false) -> void:
	var base := Color(0.3, 0.32, 0.36) if not dark else Color(0.14, 0.15, 0.18)
	draw_rect(r, base)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), base.lightened(0.45))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y)), base.lightened(0.3))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), base.darkened(0.5))
	draw_rect(Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y)), base.darkened(0.4))
	draw_rect(r.grow(1), Color(0.04, 0.03, 0.05), false, 1)


func _rivet(p: Vector2) -> void:
	draw_circle(p, 2.0, Color(0.55, 0.57, 0.62))
	draw_rect(Rect2(p - Vector2(1, 1), Vector2(1, 1)), Color(0.9, 0.9, 0.95))


func _draw() -> void:
	# placa de acero de fondo con remaches
	var plate := Rect2(40, 42, 400, 146)
	_steel(plate)
	for x in range(48, 436, 26):
		_rivet(Vector2(x, 47))
		_rivet(Vector2(x, 183))
	var small_font := PixelFont.font("white")
	var fs := PixelFont.size("white")
	for i in SOLDIERS.size():
		var pos := Vector2(X0 + i * STEP, Y0)
		var win := Rect2(pos, WIN)
		var is_sel := i == sel
		_steel(win, true)
		var row := 0 if is_sel else 1
		var dst := Rect2(pos + Vector2(6, 4), Vector2(PW, PH))
		var tint := Color.WHITE
		if is_sel and chosen_t >= 0.0 and int(chosen_t * 12.0) % 2 == 0 and chosen_t < 0.6:
			tint = Color(3, 3, 3)
		draw_texture_rect_region(portraits, dst, Rect2(i * PW, row * PH, PW, PH), tint)
		if is_sel:
			var gold := Color(1, 0.8, 0.2) if int(t * 4.0) % 2 == 0 or chosen_t >= 0.0 else Color(1, 0.5, 0.1)
			draw_rect(win.grow(1), gold, false, 2)
			# etiqueta P1 encima
			var tag := Rect2(pos + Vector2(4, -12), Vector2(22, 12))
			draw_rect(tag, Color(0.75, 0.1, 0.1))
			draw_rect(tag, Color(0.05, 0.02, 0.02), false, 1)
			draw_string(PixelFont.font("small"), tag.position + Vector2(3, 9), "P1", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("small"))
		# placa con el nombre
		var nameplate := Rect2(pos + Vector2(0, WIN.y + 4), Vector2(WIN.x, 14))
		_steel(nameplate, not is_sel)
		var label: String = SOLDIERS[i][1]
		var font := PixelFont.font("small") if is_sel else small_font
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, nameplate.position + Vector2((WIN.x - w) / 2.0, 11), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	# cuenta atrás y PULSA START
	var metal := PixelFont.font("metal")
	var secs := "%02d" % maxi(int(ceil(countdown)), 0)
	var mw := metal.get_string_size(secs, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("metal")).x
	draw_string(metal, Vector2(240 - mw / 2.0, 248), secs, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("metal"))
	if int(t * 2.0) % 2 == 0 and chosen_t < 0.0:
		draw_string(small_font, Vector2(290, 244), "PULSA START", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(PixelFont.font("label"), Vector2(60, 244), "IZQ / DER: ELEGIR", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
