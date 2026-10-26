extends Node2D
## Canal de la 1.1 (tramo 3 del pueblo, pedido de Eduardo con su referencia
## tools/sprites/chatgpt/pueblo/canal/referencia_canal.png): de x0 a x1 la calle sigue por detrás como una terraza con
## baranda y, por delante, una rampa baja al paseo junto al agua (el suelo, en levels.gd; el frente del paseo y las
## rampas los dibuja terrain.gd). Esto es el decorado de detrás del paseo: la baranda, el muro de piedra con arcos de
## desagüe que echan agua, el agua del canal (solo decorado: no se puede caer) y la franja del piso de adoquines que
## se ve por encima de los pies. Está delante de las casas (que se alejan, background.gd) y detrás del suelo, del
## jugador y de los enemigos. Antes de la rampa, una flecha avisa que hay que bajar.
## Sprites: tools/sprites/canal_kit.py (kit de piezas de ChatGPT).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const MURO := preload("res://assets/sprites/canal_muro.png")
const ARCO := preload("res://assets/sprites/canal_arco.png")
const BARANDA := preload("res://assets/sprites/canal_baranda.png")
const PISO_TEX := preload("res://assets/sprites/canal_piso.png")
const CALLE_Y := 230.0
const ARCO_CADA := 230.0  # un arco de desagüe cada tantos px
const ARCO_MARGEN := 40.0  # los arcos van sobre el tramo llano del paseo, a esta distancia de las rampas

var x0 := 0.0
var x1 := 0.0
## y del paseo de abajo (donde camina el jugador)
var bajo := 337.0
var meta: Dictionary
var main
var flecha := Node2D.new()
var t := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	meta = SpriteUtil.meta("res://assets/sprites/canal_meta.json")
	z_index = -7
	# la flecha va delante de todo
	flecha.z_index = 4
	flecha.draw.connect(_draw_flecha)
	add_child(flecha)


func _process(delta: float) -> void:
	t += delta
	var visible_now: bool = main.cam_left + 480.0 > x0 and main.cam_left < x1
	# el agua se mueve: solo se redibuja mientras se ve
	if visible_now:
		queue_redraw()
	flecha.queue_redraw()


## Tramo de la pantalla que hay que dibujar (en x del mundo), recortado al canal.
func _visible() -> Vector2:
	return Vector2(maxf(x0, main.cam_left - 8.0), minf(x1, main.cam_left + 488.0))


func _draw() -> void:
	var r := _visible()
	if r.x >= r.y:
		return
	var mh: float = meta["muro_h"]
	var piso: float = meta["piso"]
	# muro de la terraza, del borde de la calle al agua
	_tile(MURO, r, CALLE_Y, mh)
	# agua del canal y, delante, el piso del paseo
	_draw_agua(r, CALLE_Y + mh, bajo - piso)
	_tile(PISO_TEX, r, bajo - piso, piso)
	# arcos de desagüe sobre el tramo llano, repartidos parejos, con la cascada cayendo al agua
	var desde: float = x0 + meta["rampa_largo"] + ARCO_MARGEN
	var hasta: float = x1 - meta["rampa_largo"] - ARCO_MARGEN
	var aw := float(ARCO.get_width())
	var n := maxi(1, int((hasta - desde) / ARCO_CADA))
	var paso := (hasta - desde - aw) / maxf(1.0, n - 1.0)
	for k in n:
		var x := roundf(desde + k * paso) if n > 1 else roundf((desde + hasta - aw) * 0.5)
		if x + aw > r.x and x < r.y:
			draw_texture(ARCO, Vector2(x, CALLE_Y))
	# baranda sobre el borde de la terraza (tapa la parte de abajo de las casas lejanas)
	var bh := float(BARANDA.get_height())
	_tile(BARANDA, r, CALLE_Y - bh + 2.0, bh)


## Textura repetida en horizontal (alineada con la x del mundo) de r.x a r.y, de y a y + h.
func _tile(tex: Texture2D, r: Vector2, y: float, h: float) -> void:
	var tw := float(tex.get_width())
	var x := r.x - fposmod(r.x, tw)
	while x < r.y:
		var a := maxf(x, r.x)
		var b := minf(x + tw, r.y)
		draw_texture_rect_region(tex, Rect2(a, y, b - a, h), Rect2(a - x, 0, b - a, h))
		x += tw


## Agua: franja verdeazulada con el reflejo oscuro del muro arriba y brillos que se mueven.
func _draw_agua(r: Vector2, y0: float, y1: float) -> void:
	draw_rect(Rect2(r.x, y0, r.y - r.x, y1 - y0), Color(0.15, 0.36, 0.38))
	draw_rect(Rect2(r.x, y0, r.y - r.x, 4), Color(0.1, 0.24, 0.26))
	draw_rect(Rect2(r.x, y0 + 4, r.y - r.x, 1), Color(0.3, 0.55, 0.55))
	for k in range(int(r.x) - int(r.x) % 7, int(r.y), 7):
		var s := sin(k * 0.37 + t * 2.4) + sin(k * 0.11 - t * 1.3)
		var yy := y0 + 6.0 + fposmod(k * 0.5, maxf(1.0, y1 - y0 - 8.0))
		if s > 1.0:
			draw_rect(Rect2(k, yy, 4, 1), Color(0.78, 0.92, 0.86, 0.8))
		elif s < -1.3:
			draw_rect(Rect2(k, yy, 3, 1), Color(0.95, 0.66, 0.45, 0.6))


## Flecha que parpadea sobre el principio de la rampa mientras el jugador se acerca por la calle.
func _draw_flecha() -> void:
	var p = main.player
	if p.position.x < x0 - 300.0 or p.position.x > x0 + 40.0 or main.cam_y > 4.0:
		return
	if fmod(t, 0.6) > 0.42:
		return
	var c := Vector2(x0 + 40.0, 170.0 + roundf(sin(t * 6.0) * 3.0))
	var pts := PackedVector2Array([
		c + Vector2(-5, -14), c + Vector2(5, -14), c + Vector2(5, -2), c + Vector2(11, -2), c + Vector2(0, 10),
		c + Vector2(-11, -2), c + Vector2(-5, -2)])
	var borde := PackedVector2Array()
	for q in pts:
		borde.append(c + (q - c) * 1.0 + (q - c).normalized() * 1.5)
	flecha.draw_colored_polygon(borde, Color(0.15, 0.05, 0.02))
	flecha.draw_colored_polygon(pts, Color(1.0, 0.82, 0.15))
	flecha.draw_line(pts[0] + Vector2(1, 1), pts[2] + Vector2(1, 0), Color(1, 0.95, 0.6), 1.0)
