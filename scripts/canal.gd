extends Node2D
## Canal de la 1.1 (tramo 3 del pueblo, pedido de Eduardo con su referencia
## tools/sprites/chatgpt/pueblo/canal/referencia_canal.png): de x0 a x1 la calle sigue por detrás como una terraza con
## baranda y, por delante, una rampa baja al paseo junto al agua (el suelo, en levels.gd; su frente lo dibuja
## terrain.gd). Esto es el decorado de detrás del paseo: la baranda, el muro de piedra con arcos de desagüe que
## echan agua y el agua del canal (solo decorado: no se puede caer). Está delante de las casas (que se alejan,
## background.gd) y detrás del suelo, del jugador y de los enemigos.
## Entre el agua y el borde del paseo, el piso de adoquines por donde se camina (visto un poco desde arriba).
## Antes de la rampa, una flecha avisa que hay que bajar.
## Sprites: tools/sprites/terraza.py (PixelLab con el estilo de la referencia).

const MURO := preload("res://assets/sprites/terraza_muro.png")
const ARCO := preload("res://assets/sprites/terraza_arco.png")
const BARANDA := preload("res://assets/sprites/terraza_baranda.png")
const CALLE_Y := 230.0
const ARCO_CADA := 256.0  # un arco de desagüe cada tantos px (alineados con la x del mundo)
const ARCO_DESDE := 200.0  # el primero, tantos px después del principio del canal (detrás de la rampa no)
const PISO := 18.0  # alto del piso del paseo que se ve por encima de los pies

var x0 := 0.0
var x1 := 0.0
## y del paseo de abajo (donde camina el jugador)
var bajo := 340.0
var main
var flecha := Node2D.new()
var t := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
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
	var agua_y := CALLE_Y + MURO.get_height()
	# muro de la terraza, del borde de la calle al agua
	_tile(MURO, r, CALLE_Y, MURO.get_height())
	# agua del canal hasta el piso del paseo
	_draw_agua(r, agua_y, bajo - PISO)
	_draw_piso(r, bajo - PISO, bajo + 2.0)
	# arcos de desagüe, con su chorro cayendo al agua
	var aw := float(ARCO.get_width())
	var x := x0 + ARCO_DESDE
	while x + aw <= x1 - ARCO_DESDE * 0.5:
		if x + aw > r.x and x < r.y:
			draw_texture(ARCO, Vector2(x, agua_y + 4.0 - ARCO.get_height()))
		x += ARCO_CADA
	# baranda sobre el borde de la terraza (tapa la parte de abajo de las casas lejanas)
	var bh := float(BARANDA.get_height())
	_tile(BARANDA, r, CALLE_Y - bh + 3.0, bh)


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
	draw_rect(Rect2(r.x, y0, r.y - r.x, 5), Color(0.1, 0.24, 0.26))
	draw_rect(Rect2(r.x, y0 + 5, r.y - r.x, 1), Color(0.3, 0.55, 0.55))
	for k in range(int(r.x) - int(r.x) % 7, int(r.y), 7):
		var s := sin(k * 0.37 + t * 2.4) + sin(k * 0.11 - t * 1.3)
		var yy := y0 + 8.0 + fposmod(k * 0.5, y1 - y0 - 12.0)
		if s > 1.0:
			draw_rect(Rect2(k, yy, 4, 1), Color(0.78, 0.92, 0.86, 0.8))
		elif s < -1.3:
			draw_rect(Rect2(k, yy + 2.0, 3, 1), Color(0.95, 0.66, 0.45, 0.6))


## Piso del paseo: filas de adoquines (más chicos al fondo) con juntas oscuras, el borde contra el agua y brillo
## arriba de cada piedra. El dibujo depende solo de la x del mundo (no cambia de un fotograma a otro).
func _draw_piso(r: Vector2, y0: float, y1: float) -> void:
	draw_rect(Rect2(r.x, y0, r.y - r.x, y1 - y0), Color(0.36, 0.29, 0.23))
	var y := y0 + 2.0
	var fila := 0
	while y < y1:
		var h := 3.0 + fila  # las filas de delante, más altas
		var w := 6.0 + fila * 2.0
		var off := fposmod(fila * 5.0, w)
		var x := r.x - fposmod(r.x - off, w)
		while x < r.y:
			var k := int(x / w) * 7 + fila * 13
			var tono := 0.06 * float(k % 5) / 4.0
			var col := Color(0.64 + tono, 0.55 + tono, 0.42 + tono * 0.8)
			var a := maxf(x + 1.0, r.x)
			var b := minf(x + w, r.y)
			if b > a:
				draw_rect(Rect2(a, y, b - a, minf(h - 1.0, y1 - y)), col)
				draw_rect(Rect2(a, y, b - a, 1), col.lightened(0.18))
			x += w
		y += h
		fila += 1
	# borde de piedra contra el agua
	draw_rect(Rect2(r.x, y0, r.y - r.x, 2), Color(0.78, 0.7, 0.55))
	draw_rect(Rect2(r.x, y0 + 2.0, r.y - r.x, 1), Color(0.28, 0.22, 0.17))


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
