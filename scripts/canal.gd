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
const ARCO_ANIM := preload("res://assets/sprites/canal_arco_anim.png")
const BARANDA := preload("res://assets/sprites/canal_baranda.png")
const PISO_TEX := preload("res://assets/sprites/canal_piso.png")
const CALLE_Y := 230.0
const ARCO_CADA := 190.0  # un arco de desagüe cada tantos px (en levels.gd los nidos van entre los arcos)
const ARCO_MARGEN := 40.0  # los arcos van sobre el tramo llano del paseo, a esta distancia de las rampas
const ARCO_FPS := 14.0
const CORRIENTE := 14.0  # px/s a los que corre el agua del canal (hacia la derecha); delante, más rápido

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
	var arcos := _arcos()
	# muro de la terraza, del borde de la calle al agua
	_tile(MURO, r, CALLE_Y, mh)
	# agua del canal, con la espuma donde caen los chorros
	_draw_agua(r, CALLE_Y + mh, bajo - piso)
	var chorro := SpriteUtil.v(meta["arco_chorro"])
	for x in arcos:
		if x + chorro.x + 30.0 > r.x and x + chorro.x - 30.0 < r.y:
			_draw_espuma(Vector2(x + chorro.x, CALLE_Y + chorro.y + 2.0), bajo - piso)
	# arcos de desagüe con el chorro que baja (canal_arco_anim.png, un fotograma por paso)
	var nf: int = meta["arco_frames"]
	var aw := float(ARCO_ANIM.get_width()) / nf
	var ah := float(ARCO_ANIM.get_height())
	for k in arcos.size():
		var x: float = arcos[k]
		if x + aw > r.x and x < r.y:
			# cada arco a destiempo, para que no caigan todos igual
			var f := (int(t * ARCO_FPS) + k * 3) % nf
			draw_texture_rect_region(ARCO_ANIM, Rect2(x, CALLE_Y, aw, ah), Rect2(f * aw, 0, aw, ah))
	# delante, el piso del paseo (tapa la parte de abajo de la espuma)
	_tile(PISO_TEX, r, bajo - piso, piso)
	# baranda sobre el borde de la terraza (tapa la parte de abajo de las casas lejanas)
	var bh := float(BARANDA.get_height())
	_tile(BARANDA, r, CALLE_Y - bh + 2.0, bh)


## x de cada arco de desagüe: repartidos parejos sobre el tramo llano del paseo.
func _arcos() -> Array:
	var desde: float = x0 + meta["rampa_largo"] + ARCO_MARGEN
	var hasta: float = x1 - meta["rampa_largo"] - ARCO_MARGEN
	var aw := float(ARCO_ANIM.get_width()) / float(meta["arco_frames"])
	var n := maxi(1, int((hasta - desde) / ARCO_CADA))
	if n == 1:
		return [roundf((desde + hasta - aw) * 0.5)]
	var paso := (hasta - desde - aw) / (n - 1.0)
	var out := []
	for k in n:
		out.append(roundf(desde + k * paso))
	return out


## Textura repetida en horizontal (alineada con la x del mundo) de r.x a r.y, de y a y + h.
func _tile(tex: Texture2D, r: Vector2, y: float, h: float) -> void:
	var tw := float(tex.get_width())
	var x := r.x - fposmod(r.x, tw)
	while x < r.y:
		var a := maxf(x, r.x)
		var b := minf(x + tw, r.y)
		draw_texture_rect_region(tex, Rect2(a, y, b - a, h), Rect2(a - x, 0, b - a, h))
		x += tw


## Agua del canal: verdeazulada, con la sombra y el reflejo tembloroso del muro arriba, ondas que corren hacia la
## derecha (las de delante más rápido, como más cerca) y brillos del sol del atardecer que titilan.
func _draw_agua(r: Vector2, y0: float, y1: float) -> void:
	var w := r.y - r.x
	draw_rect(Rect2(r.x, y0, w, y1 - y0), Color(0.15, 0.36, 0.38))
	draw_rect(Rect2(r.x, y1 - 4.0, w, 4.0), Color(0.18, 0.42, 0.43))
	draw_rect(Rect2(r.x, y0, w, 3), Color(0.09, 0.22, 0.24))
	# reflejo del remate del muro: una línea clara que se ondula
	for x in range(int(r.x), int(r.y), 3):
		var dy := roundf(sin(x * 0.21 + t * 3.1) * 0.8)
		draw_rect(Rect2(x, y0 + 3.0 + dy, 3, 1), Color(0.3, 0.55, 0.55, 0.9))
	# ondas: en cada fila, rayas claras que avanzan con la corriente
	var fila := 0
	var y := y0 + 6.0
	while y < y1 - 1.0:
		var vel := CORRIENTE * (1.0 + fila * 0.5)
		var sep := 19.0 + fila * 6.0
		var off := fposmod(t * vel + fila * 37.0, sep)
		var x := r.x - fposmod(r.x, sep) - sep + off
		while x < r.y:
			var largo := 3.0 + roundf(absf(sin(roundf(x - off) * 0.13 + fila)) * 6.0)
			var dy := roundf(sin(x * 0.07 + t * 2.0 + fila) * 0.6)
			var a := maxf(roundf(x), r.x)
			var b := minf(roundf(x) + largo, r.y)
			if b > a:
				draw_rect(Rect2(a, y + dy, b - a, 1), Color(0.55, 0.78, 0.76, 0.55))
			x += sep
		y += 4.0
		fila += 1
	# brillos que titilan (amarillo del atardecer y blanco)
	for k in range(int(r.x) - int(r.x) % 7, int(r.y), 7):
		var s := sin(k * 0.37 + t * 2.4) + sin(k * 0.11 - t * 1.3)
		var yy := y0 + 6.0 + fposmod(k * 0.5, maxf(1.0, y1 - y0 - 8.0))
		if s > 1.3:
			draw_rect(Rect2(k + roundf(fposmod(t * CORRIENTE, 7.0)), yy, 2, 1), Color(0.85, 0.96, 0.9, 0.9))
		elif s < -1.4:
			draw_rect(Rect2(k, yy, 3, 1), Color(0.98, 0.72, 0.45, 0.7))


## Espuma donde cae un chorro: anillos aplanados que se abren y se apagan, y burbujas que saltan.
func _draw_espuma(c: Vector2, y_max: float) -> void:
	for k in 3:
		var f := fmod(t * 0.9 + k / 3.0, 1.0)
		var rx := 6.0 + f * 22.0
		var ry := minf(1.0 + f * 3.0, y_max - c.y)
		var col := Color(0.85, 0.95, 0.95, 0.75 * (1.0 - f))
		var pts := PackedVector2Array()
		for i in 21:
			var a := PI * i / 20.0  # solo la mitad de delante (la de atrás la tapa el chorro)
			pts.append((c + Vector2(cos(a) * rx, sin(a) * ry)).round())
		draw_polyline(pts, col, 1.0)
	for i in 6:
		var f := fmod(t * 1.7 + i * 0.37, 1.0)
		var bx := c.x + roundf(sin(i * 2.3) * 10.0 + (f - 0.5) * 4.0)
		var by := c.y + roundf(minf(3.0, y_max - c.y - 1.0) * fmod(i * 0.61, 1.0))
		draw_rect(Rect2(bx, by, 1, 1), Color(0.95, 1, 1, 1.0 - f))


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
