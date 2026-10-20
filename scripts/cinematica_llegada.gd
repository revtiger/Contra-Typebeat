extends CanvasLayer
## Cinemática de llegada a la 1.1 (idea y arte de Eduardo: cielo y helicóptero de ChatGPT, poses de paracaídas
## de las hojas de cada soldado). La pone level.gd la primera vez que se entra a la fase (Game.seen_cine).
##   1. Toma aérea: el cielo del atardecer se desplaza despacio; entra el helicóptero, se queda en el aire, el
##      soldado elegido salta por la puerta, cae un momento y abre el paracaídas; el helicóptero se va.
##   2. Fundido a negro y corte al pueblo: el soldado baja en paracaídas meciéndose y aterriza, la tela cae a un
##      lado y empieza la fase.
## Franjas negras de cine arriba y abajo; cualquier botón la salta. Arte: tools/sprites/cinematica.py
## (cine_cielo.png, cine_heli.png) y tools/sprites/heroes_sheets.py (player_<id>_para.png).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const SKY := preload("res://assets/sprites/cine_cielo.png")
const HELI := preload("res://assets/sprites/cine_heli.png")

const AIR_T := 6.0       # duración de la toma aérea
const FADE_T := 0.45
const JUMP_AT := 2.6     # salta del helicóptero
const CHUTE_AT := 3.05   # abre el paracaídas
const DESCENT_T := 3.2   # en el pueblo: tiempo bajando hasta tocar el suelo
const LAND_FRAMES := [[4, 0.12], [5, 0.16], [6, 0.3], [7, 0.55]]  # fotograma del paracaídas y su duración
const BAR_H := 24.0      # franjas de cine
const LAND_X := 96.0     # donde aterriza en el pueblo (x de los pies)

var level
var t := 0.0
var finished := false
var canvas := Node2D.new()
var heli_meta: Dictionary
var para_tex: Texture2D
var para_meta: Dictionary
var body_tex: Texture2D
var body_meta: Dictionary
var ground_y := 230.0
# soldado en la toma aérea
var jumped := false
var hero_pos := Vector2.ZERO
var hero_vel := Vector2.ZERO
var heli_pos := Vector2(-230, 50)
var heli_vx := 0.0      # velocidad horizontal (para inclinarlo)
var heli_tilt := 0.0    # inclinación en grados: morro abajo al acelerar, arriba al frenar
var bars := 1.0          # 1 = franjas puestas; baja a 0 al acabar


func _ready() -> void:
	layer = 15
	level = get_tree().get_first_node_in_group("level")
	heli_meta = SpriteUtil.meta("res://assets/sprites/cine_heli_meta.json")
	var body_path := "res://assets/sprites/player_%s_body.png" % Game.hero
	body_tex = load(body_path)
	body_meta = SpriteUtil.meta(body_path.replace(".png", "_meta.json"))
	para_tex = load("res://assets/sprites/player_%s_para.png" % Game.hero)
	para_meta = body_meta["para"]
	ground_y = level.ground_y_at(LAND_X)
	add_child(canvas)
	canvas.draw.connect(_draw_cine)
	Game.sfx("cannon", -18.0, 0.4)


func _process(delta: float) -> void:
	if finished:
		bars = move_toward(bars, 0.0, delta * 3.0)
		canvas.queue_redraw()
		if bars <= 0.0:
			queue_free()
		return
	t += delta
	if t > 0.3 and Game.accept_pressed():
		_finish()
		return
	_update_air(delta)
	if t >= AIR_T + DESCENT_T + _land_total():
		_finish()
	canvas.queue_redraw()


## Toma aérea: el helicóptero entra frenando, se queda (con un balanceo) y se va acelerando.
func _update_air(delta: float) -> void:
	# recorrido suave (curvas sin saltos de velocidad): entra frenando, flota con un vaivén y sale acelerando
	var x := 0.0
	if t < 2.4:
		var k := t / 2.4
		x = lerpf(-230.0, 140.0, 1.0 - pow(1.0 - k, 3.0))
	elif t < 3.4:
		x = 140.0 + sin((t - 2.4) * PI) * 4.0
	else:
		var k := t - 3.4
		x = 140.0 + 30.0 * k * k + 18.0 * k * k * k
	var vx := (x - heli_pos.x) / maxf(delta, 0.001)
	var ax := (vx - heli_vx) / maxf(delta, 0.001)
	heli_vx = vx
	heli_pos.x = x
	heli_pos.y = 50.0 + sin(t * 1.8) * 2.0
	# morro abajo al ir rápido o acelerar, morro arriba al frenar (suavizado; en grados, dentro de las
	# inclinaciones dibujadas en la hoja)
	var tilts: Array = heli_meta["tilts"]
	var want := clampf(vx * 0.05 + ax * 0.035, float(tilts[0]), float(tilts[-1]))
	heli_tilt = lerpf(heli_tilt, want, 1.0 - exp(-4.0 * delta))
	if t >= JUMP_AT and not jumped:
		jumped = true
		# la puerta, girada con la inclinación alrededor del centro del fotograma
		var fr: Array = heli_meta["frame"]
		var half := Vector2(fr[0], fr[1]) / 2.0
		var door: Vector2 = (SpriteUtil.v(heli_meta["door"]) - half).rotated(deg_to_rad(heli_tilt)) + half
		hero_pos = heli_pos + door + Vector2(0, 14)  # pies ya por debajo del helicóptero
		hero_vel = Vector2(30.0, 20.0)
		Game.sfx("jump", -8.0, 0.8)
	if jumped:
		if t < CHUTE_AT:
			hero_vel.y += 180.0 * delta
		else:
			if t - delta < CHUTE_AT:
				Game.sfx("select", -10.0, 0.6)  # se abre la tela
			hero_vel = hero_vel.move_toward(Vector2(18.0, 14.0), 200.0 * delta)
		hero_pos += hero_vel * delta


func _land_total() -> float:
	var s := 0.0
	for f in LAND_FRAMES:
		s += f[1]
	return s


func _finish() -> void:
	if finished:
		return
	finished = true
	level.end_cine(LAND_X + float(para_meta.get("end_x", 0)))


func _para_frame(i: int, feet: Vector2, scale := 1.0) -> void:
	var fr: Array = para_meta["frame"]
	var pf: Vector2 = SpriteUtil.v(para_meta["feet"])
	var src := Rect2(i * fr[0], 0, fr[0], fr[1])
	canvas.draw_texture_rect_region(para_tex, Rect2(feet - pf * scale, Vector2(fr[0], fr[1]) * scale), src)


func _body_frame(anim: String, i: int, feet: Vector2) -> void:
	var a: Dictionary = body_meta["anims"][anim]
	var fr: Array = body_meta["frame"]
	var bf: Vector2 = SpriteUtil.v(body_meta["feet"])
	var src := Rect2(i * fr[0], a["row"] * fr[1], fr[0], fr[1])
	canvas.draw_texture_rect_region(body_tex, Rect2(feet - bf, Vector2(fr[0], fr[1])), src)


func _draw_cine() -> void:
	if not finished and t < AIR_T:
		_draw_air()
	elif not finished:
		_draw_town(t - AIR_T)
	# fundidos: a negro al final de la toma aérea y desde negro al empezar la del pueblo
	var fade := 0.0
	if not finished:
		if t > AIR_T - FADE_T and t < AIR_T:
			fade = (t - (AIR_T - FADE_T)) / FADE_T
		elif t >= AIR_T and t < AIR_T + FADE_T:
			fade = 1.0 - (t - AIR_T) / FADE_T
	if fade > 0.0:
		canvas.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, fade))
	# franjas de cine
	var h := BAR_H * bars
	canvas.draw_rect(Rect2(0, 0, 480, h), Color.BLACK)
	canvas.draw_rect(Rect2(0, 270 - h, 480, h), Color.BLACK)
	if not finished and t > 0.3:
		var font := PixelFont.font("label")
		canvas.draw_string(font, Vector2(400, 262), "SALTAR", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("label"), Color(1, 1, 1, 0.6))


func _draw_air() -> void:
	# cielo: paneo lento hacia la izquierda (el helicóptero avanza a la derecha)
	var sw := SKY.get_width()
	var off := -minf(t * 14.0, sw - 480.0)
	canvas.draw_texture(SKY, Vector2(off, 0))
	# soldado (detrás del helicóptero: sale de la cabina y cae por debajo): encogido y luego con el paracaídas
	# (más pequeño: está lejos)
	if jumped and hero_pos.y < 300.0:
		if t < CHUTE_AT:
			_body_frame("jump", 1, hero_pos.round())
		else:
			var sway := int(t * 5.0) % 4
			_para_frame(sway, hero_pos.round(), 0.75)
	# helicóptero con el rotor girando (30 fotogramas por segundo); la inclinación no se gira aquí (un sprite girado
	# se ve plano, como de papel): cada fila de la hoja ya viene dibujada con la suya, se elige la más cercana
	var fr: Array = heli_meta["frame"]
	var n: int = heli_meta["frames"]
	var i := int(t * 30.0) % n
	var tilts: Array = heli_meta["tilts"]
	var step := float(tilts[1]) - float(tilts[0])
	var row := clampi(roundi((heli_tilt - float(tilts[0])) / step), 0, tilts.size() - 1)
	canvas.draw_texture_rect_region(HELI, Rect2(heli_pos.round(), Vector2(fr[0], fr[1])), Rect2(i * fr[0], row * fr[1], fr[0], fr[1]))
	# título de la fase
	if t > 0.5 and t < 2.6:
		var a := clampf(minf(t - 0.5, 2.6 - t) * 3.0, 0.0, 1.0)
		var font := PixelFont.font("title")
		var fs := PixelFont.size("title")
		var txt := "ARGENTINA"
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		canvas.draw_string(font, Vector2(240 - w / 2.0, 220), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))


func _draw_town(tt: float) -> void:
	# el pueblo es la fase en sí (la cámara está al principio): aquí solo se dibuja al soldado bajando
	var fr_i := 0
	var feet := Vector2(LAND_X, ground_y)
	if tt < DESCENT_T:
		var k := tt / DESCENT_T
		feet.y = lerpf(-10.0, ground_y, k)
		feet.x = LAND_X - 30.0 * (1.0 - k) + sin(tt * 3.0) * 4.0 * (1.0 - k)
		fr_i = int(tt * 5.0) % 4
		if ground_y - feet.y < 18.0:
			fr_i = 4  # prepara el aterrizaje
	else:
		var lt := tt - DESCENT_T
		fr_i = 7
		for f in LAND_FRAMES:
			if lt < f[1]:
				fr_i = f[0]
				break
			lt -= f[1]
		if tt - DESCENT_T < 0.05:
			Game.sfx("jump", -10.0, 0.5)
	_para_frame(fr_i, feet.round())
