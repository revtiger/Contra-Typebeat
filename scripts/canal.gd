extends Node2D
## Canal de la 1.1 (tramo 3 del pueblo, pedido de Eduardo con su referencia
## tools/sprites/chatgpt/pueblo/canal/referencia_canal.png): de x0 a x1 la calle sigue por detrás como una terraza con
## baranda y, por delante, una rampa baja al paseo junto al agua (el suelo, en levels.gd; el frente del paseo y las
## rampas los dibuja terrain.gd). Esto es el decorado de detrás del paseo: la baranda, el muro de piedra con arcos de
## desagüe que echan agua, el agua del canal (solo decorado: no se puede caer) y la franja del piso de adoquines que
## se ve por encima de los pies. Está delante de las casas (que se alejan, background.gd) y detrás del suelo, del
## jugador y de los enemigos. Antes de la rampa, una flecha avisa que hay que bajar.
## Sprites: tools/sprites/canal_kit.py (kit de piezas de ChatGPT) y tools/sprites/agua.py (agua, chorro y espuma de
## ChatGPT; el chorro y la espuma animados con PixelLab).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const MURO := preload("res://assets/sprites/canal_muro.png")
const ARCO := preload("res://assets/sprites/canal_arco.png")
const AGUA := preload("res://assets/sprites/canal_agua.png")
const CHORRO := preload("res://assets/sprites/canal_chorro.png")
const ESPUMA := preload("res://assets/sprites/canal_espuma.png")
const BARANDA := preload("res://assets/sprites/canal_baranda.png")
const PISO_TEX := preload("res://assets/sprites/canal_piso.png")
const CALLE_Y := 230.0
const ARCO_CADA := 190.0  # un arco de desagüe cada tantos px (en levels.gd los nidos van entre los arcos)
const ARCO_MARGEN := 40.0  # los arcos van sobre el tramo llano del paseo, a esta distancia de las rampas
const AGUA_FPS := 12.0   # fotogramas por segundo del chorro y la espuma
const CORRIENTE := 12.0  # px/s a los que corre el agua del canal (hacia la derecha)

var x0 := 0.0
var x1 := 0.0
## y del paseo de abajo (donde camina el jugador)
var bajo := 337.0
var meta: Dictionary
var agua_meta: Dictionary
var main
var flecha := Node2D.new()
var t := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	meta = SpriteUtil.meta("res://assets/sprites/canal_meta.json")
	agua_meta = SpriteUtil.meta("res://assets/sprites/canal_agua_meta.json")
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
	# agua del canal
	_draw_agua(r, CALLE_Y + mh, bajo - piso)
	# arcos de desagüe; encima de cada uno, el chorro que cae y, en el agua, la espuma (cada arco a destiempo)
	var chorro := SpriteUtil.v(meta["arco_chorro"])
	var aw := float(ARCO.get_width())
	for k in arcos.size():
		var x: float = arcos[k]
		if x + aw <= r.x or x >= r.y:
			continue
		draw_texture(ARCO, Vector2(x, CALLE_Y))
		var paso := int(t * AGUA_FPS) + k * 3
		var cf := SpriteUtil.v(agua_meta["chorro"]["frame"])
		var c_at := Vector2(x + chorro.x - cf.x / 2.0, CALLE_Y + chorro.y - cf.y).round()
		_frame(CHORRO, cf, paso % int(agua_meta["chorro"]["frames"]), c_at)
		var ef := SpriteUtil.v(agua_meta["espuma"]["frame"])
		var e_at := Vector2(x + chorro.x - ef.x / 2.0, bajo - piso - ef.y + 3.0).round()
		_frame(ESPUMA, ef, (paso + 2) % int(agua_meta["espuma"]["frames"]), e_at)
	# delante, el piso del paseo (tapa la parte de abajo de la espuma)
	_tile(PISO_TEX, r, bajo - piso, piso)
	# baranda sobre el borde de la terraza (tapa la parte de abajo de las casas lejanas)
	var bh := float(BARANDA.get_height())
	_tile(BARANDA, r, CALLE_Y - bh + 2.0, bh)


## x de cada arco de desagüe: repartidos parejos sobre el tramo llano del paseo.
func _arcos() -> Array:
	var desde: float = x0 + meta["rampa_largo"] + ARCO_MARGEN
	var hasta: float = x1 - meta["rampa_largo"] - ARCO_MARGEN
	var aw := float(ARCO.get_width())
	var n := maxi(1, int((hasta - desde) / ARCO_CADA))
	if n == 1:
		return [roundf((desde + hasta - aw) * 0.5)]
	var paso := (hasta - desde - aw) / (n - 1.0)
	var out := []
	for k in n:
		out.append(roundf(desde + k * paso))
	return out


## Fotograma f de una tira de fotogramas en fila.
func _frame(tex: Texture2D, size: Vector2, f: int, at: Vector2) -> void:
	draw_texture_rect_region(tex, Rect2(at, size), Rect2(f * size.x, 0, size.x, size.y))


## Textura repetida en horizontal (alineada con la x del mundo) de r.x a r.y, de y a y + h.
func _tile(tex: Texture2D, r: Vector2, y: float, h: float) -> void:
	var tw := float(tex.get_width())
	var x := r.x - fposmod(r.x, tw)
	while x < r.y:
		var a := maxf(x, r.x)
		var b := minf(x + tw, r.y)
		draw_texture_rect_region(tex, Rect2(a, y, b - a, h), Rect2(a - x, 0, b - a, h))
		x += tw


## Agua del canal (tira de ChatGPT): corre hacia la derecha y, encima, la misma tira en espejo, más tenue y más
## rápida, hace que los reflejos se muevan y centelleen. Arriba, la sombra del muro y su reflejo que tiembla.
func _draw_agua(r: Vector2, y0: float, y1: float) -> void:
	var h := minf(y1 - y0, float(AGUA.get_height()))
	draw_rect(Rect2(r.x, y0, r.y - r.x, y1 - y0), Color(0.12, 0.3, 0.32))
	_tile_corre(AGUA, r, y0, h, roundf(t * CORRIENTE), Color.WHITE)
	# capa en espejo: se dibuja con la x invertida (x -> -x), así que va hacia el otro lado del dibujo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	_tile_corre(AGUA, Vector2(-r.y, -r.x), y0, h, roundf(-t * CORRIENTE * 1.8), Color(1, 1, 1, 0.38))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(r.x, y0, r.y - r.x, 2), Color(0.06, 0.16, 0.18, 0.8))
	for x in range(int(r.x), int(r.y), 3):
		var dy := roundf(sin(x * 0.21 + t * 3.1) * 0.8)
		draw_rect(Rect2(x, y0 + 2.0 + dy, 3, 1), Color(0.35, 0.6, 0.58, 0.6))


## Textura repetida en horizontal de r.x a r.y, corrida off px a la derecha (alineada con la x del mundo).
func _tile_corre(tex: Texture2D, r: Vector2, y: float, h: float, off: float, tint: Color) -> void:
	var tw := float(tex.get_width())
	var x := r.x - fposmod(r.x - off, tw)
	while x < r.y:
		var a := maxf(x, r.x)
		var b := minf(x + tw, r.y)
		draw_texture_rect_region(tex, Rect2(a, y, b - a, h), Rect2(a - x, 0, b - a, h), tint)
		x += tw


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
