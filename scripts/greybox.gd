extends Node2D
## Greybox (modo bloques): dibuja la fase con bloques grises etiquetados por encima del arte, para probar
## medidas y jugabilidad sin depender del pixel art. Solo en modo test, con F1 (Game.greybox): la fase se recarga
## con su mundo del greybox (datos "greybox" de levels.gd; si no tiene, la misma fase) y aquí se ven sus cajas.
## - Escenario: siluetas de edificios, árboles y valla (pueblo: PIEZAS de scripts/pueblo_casas.gd, generado
##   por tools/sprites/pueblo.py), con puertas y ventanas; cuadrícula de 16 px contada desde el suelo.
## - Terreno: suelo, cuestas y plataformas de levels.gd, con su altura.
## - Personajes, objetos y balas: sus cajas de colisión reales, del color de su capa (ARQUITECTURA.md).

const PixelFont = preload("res://scripts/pixel_font.gd")
const PuebloCasas = preload("res://scripts/pueblo_casas.gd")
const Edificios = preload("res://scripts/edificios.gd")

const W := 480.0
const H := 270.0
const GRID := 16.0
const GROUND_REF := 230.0  # las líneas horizontales de la cuadrícula se cuentan desde aquí
## grises del escenario, de lejos (oscuro) a cerca (claro)
const C_FONDO := Color(0.16, 0.16, 0.18)
const C_ARBOL := Color(0.23, 0.23, 0.25)
const C_EDIFICIO := Color(0.31, 0.31, 0.33)
const C_HUECO := Color(0.2, 0.2, 0.22)  # puertas y ventanas
const C_VALLA := Color(0.38, 0.38, 0.4)
const C_VEREDA := Color(0.44, 0.44, 0.46)
const C_SUELO := Color(0.55, 0.55, 0.57)
const C_PLATAFORMA := Color(0.68, 0.68, 0.7)
const C_CUERPO := Color(0.82, 0.82, 0.84)  # relleno de personajes y objetos
const C_SENSOR := Color(1, 1, 1, 0.35)  # áreas sin capa (sensor de contacto, muertos)
## [valor de la capa, nombre en la leyenda, color] (ARQUITECTURA.md)
const CAPAS := [
	[2, "JUGADOR", Color(0.3, 1.0, 0.45)],
	[4, "ENEMIGO", Color(1.0, 0.3, 0.3)],
	[8, "ATAQUE J", Color(1.0, 0.9, 0.2)],
	[16, "ATAQUE E", Color(1.0, 0.4, 1.0)],
	[32, "OBJETO", Color(0.3, 0.9, 1.0)],
	[64, "ZONA", Color(0.45, 0.55, 1.0)],
]
## nombre de cada script en pantalla (los que no están aquí, como las balas, van sin nombre)
const NOMBRES := {
	"player": "HEROE", "massa": "MASSA", "politician": "JEFE", "turret": "NIDO", "tank": "TANQUE",
	"barrel": "BARRIL", "mine": "MINA", "miniboss": "MINIJEFE", "boss": "MURO", "heli": "HELICOPTERO",
	"boss_part": "PIEZA", "jump_hitbox": "JUMP", "tirador_ventana": "TIRADOR",
}
const MODOS := {"run": "SOLDADO", "sniper": "FRANCOTIRADOR", "grenadier": "GRANADERO", "asalto": "ASALTANTE"}
const CON_VIDA := ["massa", "politician", "tank", "turret", "miniboss", "boss", "heli"]

var level
var font: FontFile
var fh := 10


func _ready() -> void:
	z_index = 50  # encima de todo el mundo (las explosiones van a 10); el HUD sigue encima en su CanvasLayer
	font = PixelFont.font("white")
	fh = PixelFont.size("white")


func _process(_delta: float) -> void:
	visible = Game.greybox and level.state != "cine"
	if visible:
		queue_redraw()


func _draw() -> void:
	var left: float = level.cam_left
	var top: float = level.cam_y
	draw_rect(Rect2(left - 8, top - 8, W + 16, H + 16), C_FONDO)
	if not level.buildings.is_empty():
		_draw_edificios(left, top)
	elif level.theme == "pueblo":
		_draw_pueblo(left, top)
	_draw_grid(left, top)
	_draw_terreno(left)
	for c in get_tree().get_nodes_in_group("civil"):
		_draw_vecino(c)
	for n in level.get_children():
		if n != self:
			_draw_nodo(n)
	_draw_leyenda(left, top)


# ---------- escenario ----------

func _draw_grid(left: float, top: float) -> void:
	var x := floorf(left / GRID) * GRID
	while x <= left + W:
		var fuerte := fposmod(x, GRID * 4.0) == 0.0
		draw_line(Vector2(x, top), Vector2(x, top + H), Color(1, 1, 1, 0.1 if fuerte else 0.05))
		x += GRID
	var y := GROUND_REF - ceilf((GROUND_REF - top) / GRID) * GRID
	while y <= top + H:
		var fuerte := fposmod(GROUND_REF - y, GRID * 4.0) == 0.0
		draw_line(Vector2(left, y), Vector2(left + W, y), Color(1, 1, 1, 0.1 if fuerte else 0.05))
		y += GRID


## Edificios generados (scripts/edificios.gd): pisos, ventanas, puerta y número. Si siguen por encima de la
## pantalla, flechas arriba: el edificio continúa.
func _draw_edificios(left: float, top: float) -> void:
	var piso := Edificios.PISO
	var base: float = level.buildings[0]["base"]
	draw_rect(Rect2(left, base, W, GROUND_REF - base), C_VEREDA)
	for b in level.buildings:
		if b["x"] + b["w"] < left or b["x"] > left + W:
			continue
		var r := Rect2(b["x"], b["base"] - b["h"], b["w"], b["h"])
		var grande: bool = b["tipo"] == "grande"
		var alto: bool = b["tipo"] == "rascacielos" or b["tipo"] == "torre"
		draw_rect(r, C_EDIFICIO.lightened(0.12 if grande else (0.06 if alto else 0.0)))
		draw_rect(r, C_EDIFICIO.darkened(0.45), false, 2.0 if grande else 1.0)
		for p in int(b["pisos"]):
			var suelo_piso: float = r.end.y - p * piso
			if suelo_piso >= top and suelo_piso - piso <= top + H:
				draw_line(Vector2(r.position.x, suelo_piso), Vector2(r.end.x, suelo_piso), C_EDIFICIO.darkened(0.3))
		var puerta := 40.0 if grande else 20.0
		draw_rect(Rect2(r.get_center().x - puerta / 2.0, r.end.y - 62, puerta, 62), C_HUECO)
		for v in Edificios.ventanas(b):
			if v.end.y >= top and v.position.y <= top + H:
				draw_rect(v, C_HUECO)
		var etiqueta := "#%d %s %d PISO%s" % [b["id"], String(b["tipo"]).to_upper(), b["pisos"], "S" if b["pisos"] > 1 else ""]
		if grande:
			etiqueta = "#%d %s  (ARRIBA EN LA PUERTA: ENTRAR)" % [b["id"], String(b["nombre"]).to_upper()]
		_texto(Vector2(r.position.x + 3, maxf(r.position.y + 3, top + 34)), etiqueta, Color(1, 1, 1, 0.8))
		if r.position.y < top + 30:
			# sigue hacia arriba: flechas en el borde de la pantalla y el alto total
			var ax := r.position.x + 10
			while ax <= r.end.x - 10:
				var p0 := Vector2(ax, top + 47)
				draw_colored_polygon(PackedVector2Array([p0 + Vector2(-4, 4), p0 + Vector2(4, 4), p0 + Vector2(0, -2)]), Color(1, 1, 1, 0.5))
				ax += 24
			_texto(Vector2(r.position.x + 3, top + 52), "SIGUE ARRIBA %dPX" % int(b["h"]), Color(1, 1, 1, 0.6))


func _draw_pueblo(left: float, top: float) -> void:
	draw_rect(Rect2(left, 207, W, GROUND_REF - 207), C_VEREDA)
	for p in PuebloCasas.PIEZAS:
		var r := _rect(p[2])
		if r.end.x < left or r.position.x > left + W:
			continue
		match p[0]:
			"arbol":
				draw_rect(r, C_ARBOL)
				_texto(Vector2(r.position.x + 3, maxf(r.position.y + 3, top + 34)), "ARBOL", Color(1, 1, 1, 0.4))
			"valla":
				draw_rect(r, C_VALLA)
			"edificio":
				draw_rect(r, C_EDIFICIO)
				draw_rect(r, C_EDIFICIO.darkened(0.4), false, 1.0)
				var nombre: String = p[1].to_upper().replace("_", " ")
				_texto(Vector2(r.position.x + 3, maxf(r.position.y + 3, top + 34)), "%s %dPX" % [nombre, int(r.size.y)], Color(1, 1, 1, 0.75))
	for c in PuebloCasas.CASAS:
		var puerta := _rect(c[1])
		if puerta.end.x < left - 200 or puerta.position.x > left + W + 200:
			continue
		draw_rect(puerta, C_HUECO)
		for v in c[2]:
			draw_rect(_rect(v), C_HUECO)


func _draw_terreno(left: float) -> void:
	for g in level.ground:
		if g[1] < left or g[0] > left + W:
			continue
		var y0: float = g[2]
		var y1: float = g[3] if g.size() > 3 else y0
		draw_colored_polygon(PackedVector2Array([Vector2(g[0], y0), Vector2(g[1], y1), Vector2(g[1], H + 8),
			Vector2(g[0], H + 8)]), C_SUELO)
		draw_line(Vector2(g[0], y0), Vector2(g[1], y1), Color.WHITE)
		var tx := maxf(g[0], left) + 4
		var t := "SUELO Y=%d" % int(y0) if y0 == y1 else "CUESTA %d A %d" % [int(y0), int(y1)]
		_texto(Vector2(tx, lerpf(y0, y1, clampf((tx - g[0]) / maxf(1.0, g[1] - g[0]), 0.0, 1.0)) + 3), t, Color(0.1, 0.1, 0.12))
	for p in level.platforms:
		var r := Rect2(p[0], p[2], p[1], 8)
		if r.end.x < left or r.position.x > left + W:
			continue
		draw_rect(r, C_PLATAFORMA)
		draw_line(r.position, Vector2(r.end.x, r.position.y), Color.WHITE)
		var alto: float = level.ground_y_at(r.get_center().x) - r.position.y
		_texto(r.position + Vector2(2, -fh - 1), "PLATAFORMA +%d" % int(alto))


func _draw_vecino(c) -> void:
	if c.get("state") in ["enter", "inside", "peek"]:
		return
	var r := Rect2(c.global_position + Vector2(-6, -40), Vector2(12, 40))
	draw_rect(r, Color(0.6, 0.6, 0.62))
	_etiqueta(r, "VECINO", Color(1, 1, 1, 0.6))


# ---------- personajes, objetos y ataques ----------

func _draw_nodo(n) -> void:
	if n.get_script() == null or not n is Node2D:
		return
	var base: String = n.get_script().resource_path.get_file().get_basename()
	if not n is CollisionObject2D:
		_draw_sin_colision(n, base)
		return
	var caja := Rect2()
	var hay := false
	var capa: int = n.collision_layer
	var col := _color(capa)
	var ataque := capa & (8 | 16) != 0
	for c in n.get_children():
		if c is CollisionObject2D:
			_draw_nodo_hijo(c)
		if not c is CollisionShape2D or c.shape == null:
			continue
		var gp: Vector2 = c.global_position
		if c.shape is RectangleShape2D:
			var r := Rect2(gp - c.shape.size / 2.0, c.shape.size)
			if capa == 0:
				draw_rect(r, C_SENSOR, false, 1.0)
			elif capa & 64:
				# zona: invisible en el juego; aquí, azul translúcido
				draw_rect(r, Color(col, 0.2))
				draw_rect(r, col, false, 1.0)
			else:
				draw_rect(r, col if ataque else C_CUERPO)
				draw_rect(r, col, false, 1.0)
			caja = r if not hay else caja.merge(r)
			hay = true
		elif c.shape is CircleShape2D:
			draw_circle(gp, c.shape.radius, col if capa != 0 else C_SENSOR)
	if not hay:
		return
	var nombre := _nombre(n, base)
	if nombre != "":
		if capa != 0 and base in CON_VIDA and n.get("hp") != null:
			nombre += " %d" % int(n.hp)
		_etiqueta(caja, nombre, Color.WHITE, "%dX%d" % [int(caja.size.x), int(caja.size.y)])
	if n.get("state") == "aviso" and int(n.state_t * 12.0) % 2 == 0:
		# emboscada a punto de salir (asaltante o tirador de ventana)
		draw_rect(caja.grow(2.0), Color(1, 0.2, 0.15), false, 2.0)
		_texto(Vector2(caja.get_center().x - 3, caja.position.y - 3 * fh - 4), "!", Color(1, 0.2, 0.15))
	_draw_direccion(n, base, caja)


## Áreas dentro de un personaje (el sensor de contacto del héroe): solo el contorno.
func _draw_nodo_hijo(a) -> void:
	for c in a.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			draw_rect(Rect2(c.global_position - c.shape.size / 2.0, c.shape.size), C_SENSOR, false, 1.0)


## Hacia dónde mira o apunta: el héroe, la línea de tiro; los demás, una flecha a la altura del pecho.
func _draw_direccion(n, base: String, caja: Rect2) -> void:
	if n.collision_layer == 0:
		return
	var pecho := Vector2(n.global_position.x, caja.position.y + minf(10.0, caja.size.y / 3.0))
	if base == "player":
		draw_line(pecho, pecho + (n.aim as Vector2) * 16.0, CAPAS[2][2], 1.0)
		# zona para devolver granadas (player.parry_point) y zona de agarre de los jump hitbox (player.grab_point)
		draw_arc(n.parry_point(), n.PARRY_R, 0.0, TAU, 16, Color(1, 0.35, 0.3, 0.8), 1.0)
		draw_arc(n.grab_point(), n.GRAB_R, 0.0, TAU, 12, Color(0.3, 0.9, 1.0, 0.8), 1.0)
		return
	if not base in ["soldier", "massa", "tank"]:
		return
	var d := signf(float(n.dir))
	var p := Vector2(caja.get_center().x + d * (caja.size.x / 2.0 + 1.0), pecho.y)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(d * 4.0, 2.0), p + Vector2(0, 4.0)]), _color(4))


## Lo que juega pero no tiene colisión: avisos de bomba, explosiones (zona de daño), avión y puertas.
func _draw_sin_colision(n, base: String) -> void:
	var col := _color(16)
	match base:
		"bomb":
			var gy: float = n.ground_y
			if n.returned:
				col = _color(8)  # devuelta por el héroe: ahora es un ataque suyo
			else:
				draw_rect(Rect2(n.target_x - 6, gy - 2, 12, 2), col)
				_texto(Vector2(n.target_x - 15, gy - fh - 3), "BOMBA", col)
			if n.falling:
				# se puede devolver: parpadea en blanco todo el trayecto
				if n.parryable and not n.returned and int(n.t * 14.0) % 2 == 0:
					col = Color.WHITE
				draw_circle(n.global_position, 3.0, col)
		"explosion":
			draw_arc(n.global_position, n.r, 0.0, TAU, 24, Color(1, 1, 1, 0.7), 1.0)
		"jet":
			var r := Rect2(n.global_position - Vector2(20, 6), Vector2(40, 12))
			draw_rect(r, C_CUERPO)
			_etiqueta(r, "AVION", Color.WHITE)
		"door":
			var r := Rect2(n.global_position - Vector2(n.W / 2.0, n.H), Vector2(n.W, n.H))
			draw_rect(r, C_PLATAFORMA)
			_etiqueta(r, "PUERTA", Color.WHITE)


func _nombre(n, base: String) -> String:
	if base == "soldier":
		return MODOS.get(n.mode, "SOLDADO")
	if base == "pickup":
		return ("CAPSULA " if n.mode == "capsule" else "ARMA ") + str(n.weapon)
	if base == "zona":
		return n.etiqueta
	return NOMBRES.get(base, "")


func _color(capa: int) -> Color:
	for c in CAPAS:
		if capa & c[0]:
			return c[2]
	return C_SENSOR


# ---------- texto ----------

func _rect(r: Array) -> Rect2:
	return Rect2(r[0], r[1], r[2] - r[0], r[3] - r[1])


## Texto con sombra (pos = esquina de arriba a la izquierda).
func _texto(pos: Vector2, t: String, col := Color.WHITE) -> void:
	var p := pos.round() + Vector2(0, fh - 2)
	draw_string(font, p + Vector2(1, 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fh, Color(0, 0, 0, col.a * 0.8))
	draw_string(font, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fh, col)


## Nombre (y medida) centrados encima de una caja.
func _etiqueta(caja: Rect2, t: String, col: Color, medida := "") -> void:
	var y := caja.position.y - fh - 2
	if medida != "":
		_texto(Vector2(caja.get_center().x - medida.length() * 3.0, y), medida, Color(1, 1, 1, 0.6))
		y -= fh
	_texto(Vector2(caja.get_center().x - t.length() * 3.0, y), t, col)


func _draw_leyenda(left: float, top: float) -> void:
	var y := top + H - fh - 3
	draw_rect(Rect2(left, y - 2, W, fh + 5), Color(0.08, 0.08, 0.1, 0.85))
	if level.en_altura:
		_texto(Vector2(left + W - 64, top + 34), "EN ALTURA", Color(0.3, 0.9, 1.0))
	var x := left + 4
	_texto(Vector2(x, y), "GREYBOX  F1 ARTE")
	x += 17 * 6 + 8
	for c in CAPAS:
		draw_rect(Rect2(x, y + 2, 6, 6), c[2])
		_texto(Vector2(x + 9, y), c[1], c[2])
		x += 9 + c[1].length() * 6 + 8
