extends Node2D
## Dibujo de un bloque de terreno según el tema: suelo (jungla o arena) o puente/saliente.

var size := Vector2.ZERO
var one_way := false
## Cuestas: altura (local) del borde de arriba al principio y al final del tramo. En los bloques planos,
## los dos son 0 (el borde de arriba es la y del bloque).
var top0 := 0.0
var top1 := 0.0
## Grosor que se ve de los salientes (la colisión es solo la superficie): parecen roca o tejado macizo
const LEDGE_DEPTH := 22.0
var theme := "jungle"

const PUEBLO_GROUND := preload("res://assets/sprites/ground_pueblo.png")
## Canal de la 1.1 (tools/sprites/terraza.py, referencia de Eduardo): los tramos más bajos que la calle son el paseo
## junto al agua (borde de adoquines y muro de piedra) y las rampas que bajan a él son de piedra. El muro del fondo,
## el agua y la baranda los dibuja canal.gd.
const TERRAZA_MURO := preload("res://assets/sprites/terraza_muro.png")
const TERRAZA_PIEDRA := preload("res://assets/sprites/terraza_piedra.png")
const CALLE_Y := 230.0  # altura de la calle del pueblo
## el paseo está más cerca que el muro del fondo: un poco más oscuro y cálido
const PASEO_TINTE := Color(0.8, 0.74, 0.68)
const PISO := 18.0  # alto del piso del paseo que se ve por encima de los pies (como en canal.gd)
const RELLENO := Color(0.17, 0.12, 0.09)  # detrás de la piedra (sus bordes tienen huecos)
## piedra bajo la calle: más oscura y marrón, como la tierra de la tira
const CALLE_PIEDRA := Color(0.62, 0.5, 0.42)
## Suelos de PixelLab de la 1.2 y la 1.3 (tools/sprites/argentina.py): tira que se repite y color de relleno debajo
const STRIPS := {
	"quebrada": [preload("res://assets/sprites/ground_quebrada.png"), Color(0.16, 0.06, 0.08)],
	"baires": [preload("res://assets/sprites/ground_baires.png"), Color(0.08, 0.05, 0.1)],
}


func _ready() -> void:
	# las rampas del canal rellenan un polígono con la piedra repetida
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	if top0 != top1 and theme == "pueblo":
		_draw_rampa()
		return
	if top0 != top1 and not STRIPS.has(theme):
		_draw_slope_plain()
		return
	var desert := theme == "desert"
	if theme == "city":
		_draw_city()
		return
	if theme == "base":
		_draw_base()
		return
	if theme == "snow":
		_draw_snow()
		return
	if theme == "pueblo":
		_draw_pueblo()
		return
	if STRIPS.has(theme):
		_draw_strip(STRIPS[theme][0], STRIPS[theme][1])
		return
	if one_way:
		if desert:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.42, 0.34))
			draw_rect(Rect2(0, 0, size.x, 2), Color(0.75, 0.62, 0.5))
			draw_rect(Rect2(0, size.y - 2, size.x, 2), Color(0.38, 0.28, 0.22))
			for x in range(4, int(size.x), 11):
				draw_rect(Rect2(x, 3, 3, 2), Color(0.45, 0.33, 0.27))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.5, 0.33, 0.17))
			for x in range(0, int(size.x), 8):
				draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.2, 0.1))
			draw_rect(Rect2(0, 0, size.x, 2), Color(0.68, 0.5, 0.28))
		return
	var body := Color(0.72, 0.45, 0.28) if desert else Color(0.36, 0.25, 0.16)
	var spot := Color(0.62, 0.36, 0.22) if desert else Color(0.28, 0.19, 0.12)
	var top := Color(0.93, 0.78, 0.5) if desert else Color(0.2, 0.62, 0.2)
	var edge := body.darkened(0.3)
	draw_rect(Rect2(Vector2.ZERO, size), body)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x)
	if desert:
		for y in range(14, int(size.y), 12):
			draw_line(Vector2(0, y), Vector2(size.x, y + rng.randf_range(-2, 2)), spot, 2)
	for i in int(size.x * size.y / 400.0):
		var p := Vector2(rng.randf() * size.x, 8 + rng.randf() * (size.y - 8))
		draw_rect(Rect2(p, Vector2(4, 3)), spot)
	draw_rect(Rect2(0, 0, size.x, 5), top)
	if desert:
		for x in range(0, int(size.x), 9):
			draw_rect(Rect2(x + rng.randf() * 4, 5, 3, 1), top.darkened(0.15))
	else:
		for x in range(0, int(size.x), 6):
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 3, -4), Vector2(x + 6, 0)]), Color(0.25, 0.72, 0.25))
	# caras laterales para que se note el borde en fosos y escalones
	draw_rect(Rect2(0, 0, 2, size.y), edge)
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), edge)


## Pueblo de la pampa: calle de adoquines con tierra y pasto (tira de ground_pueblo.png, sacada de
## las ilustraciones). El pueblo no tiene tablones ni fosos.
func _draw_pueblo() -> void:
	if global_position.y > CALLE_Y + 4.0:
		_draw_paseo()
		return
	var tw := float(PUEBLO_GROUND.get_width())
	var th := float(PUEBLO_GROUND.get_height())
	# debajo de la tira, piedra (solo se ve junto al canal, cuando la cámara baja)
	draw_rect(Rect2(Vector2.ZERO, size), RELLENO)
	var y := th - 6.0
	var ph := float(TERRAZA_PIEDRA.get_height())
	while y < size.y:
		_tile_x(TERRAZA_PIEDRA, y, minf(ph, size.y - y), CALLE_PIEDRA)
		y += ph
	# la tira se alinea con la x del mundo para que no se note el corte entre bloques
	var x := -fposmod(global_position.x, tw)
	while x < size.x:
		var sx := maxf(0.0, -x)
		var w := minf(tw - sx, size.x - maxf(x, 0.0))
		draw_texture_rect_region(PUEBLO_GROUND, Rect2(maxf(x, 0.0), -3, w, th), Rect2(sx, 0, w, th))
		x += tw
	draw_rect(Rect2(0, th - 3, size.x, 2), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.12, 0.08, 0.05))


## Ciudad: asfalto con bordillo y hormigón agrietado; los puentes son vigas de acero.
func _draw_city() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.2, 0.12))
		draw_rect(Rect2(0, 0, size.x, 2), Color(0.75, 0.32, 0.2))
		draw_rect(Rect2(0, size.y - 2, size.x, 2), Color(0.35, 0.12, 0.08))
		for x in range(6, int(size.x) - 4, 12):
			draw_circle(Vector2(x, size.y / 2.0), 1.2, Color(0.3, 0.1, 0.06))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x) + 7
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.33, 0.32))
	for i in int(size.x * size.y / 300.0):
		var p := Vector2(rng.randf() * size.x, 10 + rng.randf() * (size.y - 10))
		draw_rect(Rect2(p, Vector2(3, 2)), Color(0.28, 0.26, 0.26))
	for i in int(size.x / 60.0):
		var cx := rng.randf() * size.x
		draw_line(Vector2(cx, 8), Vector2(cx + rng.randf_range(-8, 8), 8 + rng.randf_range(10, 30)), Color(0.2, 0.18, 0.18), 1)
	draw_rect(Rect2(0, 0, size.x, 6), Color(0.18, 0.18, 0.2))
	draw_rect(Rect2(0, 0, size.x, 1), Color(0.45, 0.45, 0.48))
	for x in range(10, int(size.x) - 12, 40):
		draw_rect(Rect2(x, 2, 16, 1), Color(0.9, 0.75, 0.2))
	# escombros sobre el asfalto
	for i in int(size.x / 90.0):
		var rx := rng.randf() * size.x
		draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 3, -4), Vector2(rx + 7, -2), Vector2(rx + 9, 0)]), Color(0.3, 0.27, 0.26))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.22, 0.2, 0.2))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.22, 0.2, 0.2))


## Nieve (Alemania): roca oscura con una capa de nieve; los puentes son tablones nevados.
func _draw_snow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x) + 3
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.32, 0.22))
		for x in range(0, int(size.x), 8):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.2, 0.14))
		draw_rect(Rect2(0, -2, size.x, 3), Color(0.95, 0.97, 1.0))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.3, 0.36))
	for i in int(size.x * size.y / 400.0):
		draw_rect(Rect2(Vector2(rng.randf() * size.x, 10 + rng.randf() * (size.y - 10)), Vector2(4, 3)), Color(0.24, 0.24, 0.3))
	draw_rect(Rect2(0, 0, size.x, 7), Color(0.95, 0.97, 1.0))
	for x in range(0, int(size.x), 7):
		draw_rect(Rect2(x, 7, 4, 2 + rng.randi() % 3), Color(0.95, 0.97, 1.0))
	draw_rect(Rect2(0, 0, size.x, 1), Color(1, 1, 1))
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.2, 0.2, 0.25))


## Base secreta (ONU): suelo de placas de acero con franjas de peligro; los puentes son rejillas.
func _draw_base() -> void:
	if one_way:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.28, 0.34))
		for x in range(2, int(size.x) - 2, 4):
			draw_line(Vector2(x, 1), Vector2(x, size.y - 1), Color(0.12, 0.13, 0.16), 1)
		draw_rect(Rect2(0, 0, size.x, 1), Color(0.5, 0.55, 0.62))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.22, 0.27))
	for x in range(0, int(size.x), 32):
		draw_rect(Rect2(x, 0, 31, 8), Color(0.34, 0.37, 0.43))
		draw_rect(Rect2(x, 0, 31, 1), Color(0.5, 0.54, 0.6))
		draw_circle(Vector2(x + 3, 4), 1, Color(0.2, 0.22, 0.27))
		draw_circle(Vector2(x + 28, 4), 1, Color(0.2, 0.22, 0.27))
	for x in range(0, int(size.x), 12):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 8), Vector2(x + 6, 8), Vector2(x + 2, 13), Vector2(x - 4, 13)]), Color(0.9, 0.7, 0.1))
	for y in range(24, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.15, 0.16, 0.2), 1)
	draw_rect(Rect2(0, 0, 2, size.y), Color(0.12, 0.13, 0.16))
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), Color(0.12, 0.13, 0.16))


## Suelo hecho con una tira de imagen alineada con la x del mundo (sin cortes entre bloques).
## Los salientes (one_way) usan solo la parte de arriba de la tira y un borde oscuro debajo.
func _draw_strip(tex: Texture2D, fill: Color) -> void:
	if top0 != top1:
		_draw_slope_strip(tex, fill)
		return
	var tw := float(tex.get_width())
	var th := minf(float(tex.get_height()), LEDGE_DEPTH if one_way else size.y)
	if not one_way:
		draw_rect(Rect2(Vector2.ZERO, size), fill)
	var x := -fposmod(global_position.x, tw)
	while x < size.x:
		var sx := maxf(0.0, -x)
		var w := minf(tw - sx, size.x - maxf(x, 0.0))
		draw_texture_rect_region(tex, Rect2(maxf(x, 0.0), 0, w, th), Rect2(sx, 0, w, th))
		x += tw
	var edge := fill.darkened(0.3)
	if one_way:
		draw_rect(Rect2(0, th - 2, size.x, 2), edge)
	draw_rect(Rect2(0, 0, 2, size.y), edge)
	draw_rect(Rect2(size.x - 2, 0, 2, size.y), edge)


## Cuesta con la tira de suelo: columnas de 2 px que siguen la pendiente (alineadas con la x del mundo).
func _draw_slope_strip(tex: Texture2D, fill: Color) -> void:
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	draw_colored_polygon(PackedVector2Array([Vector2(0, top0), Vector2(size.x, top1), Vector2(size.x, size.y), Vector2(0, size.y)]), fill)
	var x := 0.0
	while x < size.x:
		var w := minf(2.0, size.x - x)
		var y := roundf(lerpf(top0, top1, x / size.x))
		var sx := fposmod(global_position.x + x, tw)
		draw_texture_rect_region(tex, Rect2(x, y, w, th), Rect2(sx, 0, minf(w, tw - sx), th))
		x += w


## Cuesta en los temas dibujados por código: relleno con un borde claro arriba.
func _draw_slope_plain() -> void:
	var body := Color(0.72, 0.45, 0.28) if theme == "desert" else Color(0.36, 0.25, 0.16)
	draw_colored_polygon(PackedVector2Array([Vector2(0, top0), Vector2(size.x, top1), Vector2(size.x, size.y), Vector2(0, size.y)]), body)
	draw_line(Vector2(0, top0), Vector2(size.x, top1), body.lightened(0.35), 4)


## Paseo del canal: borde de adoquines (donde se camina) y muro de piedra hasta abajo.
func _draw_paseo() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), RELLENO)
	var mh := float(TERRAZA_MURO.get_height())
	_tile_x(TERRAZA_MURO, -3.0, minf(mh, size.y), PASEO_TINTE)
	var y := mh - 3.0
	var ph := float(TERRAZA_PIEDRA.get_height())
	while y < size.y:
		_tile_x(TERRAZA_PIEDRA, y, minf(ph, size.y - y), PASEO_TINTE)
		y += ph


## Rampa empedrada entre la calle y el paseo del canal: piedra bajo la cuesta, borde de adoquines y, por encima de
## la cuesta, el piso de adoquines que se ensancha de nada (arriba, junto a la calle) a PISO (abajo, junto al paseo).
func _draw_rampa() -> void:
	var w := size.x
	var gx := global_position.x
	var tw := float(TERRAZA_PIEDRA.get_width())
	var th := float(TERRAZA_PIEDRA.get_height())
	var pts := PackedVector2Array([Vector2(0, top0), Vector2(w, top1), Vector2(w, size.y), Vector2(0, size.y)])
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(Vector2((p.x + gx) / tw, (p.y - minf(top0, top1)) / th))
	draw_colored_polygon(pts, RELLENO)
	draw_polygon(pts, PackedColorArray([PASEO_TINTE]), uvs, TERRAZA_PIEDRA)
	_draw_piso_rampa()
	# borde de adoquines de la cuesta: bloques de 9 px con junta oscura
	draw_line(Vector2(0, top0 + 2), Vector2(w, top1 + 2), Color(0.8, 0.7, 0.53), 5.0)
	draw_line(Vector2(0, top0), Vector2(w, top1), Color(0.93, 0.85, 0.68), 1.0)
	draw_line(Vector2(0, top0 + 5), Vector2(w, top1 + 5), Color(0.3, 0.23, 0.18), 1.0)
	for k in range(0, int(w), 9):
		var y := lerpf(top0, top1, float(k) / w)
		draw_line(Vector2(k, y), Vector2(k, y + 4), Color(0.5, 0.41, 0.31), 1.0)


## Piso de la rampa: columnas de adoquines que siguen la cuesta (se ven como escalones bajos).
func _draw_piso_rampa() -> void:
	var w := size.x
	var bajo_izq := top0 > top1  # la parte de abajo (el paseo) está a la izquierda: rampa que sube
	var x := 0.0
	var col := 0
	while x < w:
		var cw := minf(6.0, w - x)
		var t := (x + cw * 0.5) / w
		var y := roundf(lerpf(top0, top1, t))
		var h := roundf(PISO * (1.0 - t if bajo_izq else t))
		if h >= 1.0:
			draw_rect(Rect2(x, y - h, cw, h), Color(0.36, 0.29, 0.23))
			var yy := y - h + 1.0
			var fila := 0
			while yy < y:
				var k := (int((x + global_position.x) / 6.0) * 7 + fila * 13) % 5
				var tono := 0.06 * float(k) / 4.0
				var c := Color(0.64 + tono, 0.55 + tono, 0.42 + tono * 0.8)
				var rh := minf(3.0 + fila, y - yy)
				draw_rect(Rect2(x + 1.0, yy, cw - 1.0, maxf(1.0, rh - 1.0)), c)
				draw_rect(Rect2(x + 1.0, yy, cw - 1.0, 1), c.lightened(0.18))
				yy += rh
				fila += 1
			# borde de arriba del piso, contra el muro
			draw_rect(Rect2(x, y - h - 1.0, cw, 1), Color(0.28, 0.22, 0.17))
		x += cw
		col += 1


## Tira que se repite en horizontal alineada con la x del mundo, de y a y + h.
func _tile_x(tex: Texture2D, y: float, h: float, tint := Color.WHITE) -> void:
	var tw := float(tex.get_width())
	var x := -fposmod(global_position.x, tw)
	while x < size.x:
		var sx := maxf(0.0, -x)
		var w := minf(tw - sx, size.x - maxf(x, 0.0))
		draw_texture_rect_region(tex, Rect2(maxf(x, 0.0), y, w, h), Rect2(sx, 0, w, h), tint)
		x += tw
