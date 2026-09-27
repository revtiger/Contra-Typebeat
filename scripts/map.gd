extends Node2D
## Mapa de campaña entre misiones: América con la ruta recorrida y el destino de la próxima misión.
## Game.level indica la misión a la que se va. Si esa misión aún no existe, muestra "PRÓXIMAMENTE".

const Levels = preload("res://scripts/levels.gd")

## Paradas de la campaña en orden (lon, lat). La parada i corresponde a la misión i.
const STOPS := [
	{"name": "ARGENTINA - BRASIL", "sub": "Triple Frontera · Selva de Iguazú", "lon": -54.6, "lat": -25.6, "label": "below"},
	{"name": "BOLIVIA", "sub": "Quebradas de Tupiza", "lon": -65.7, "lat": -21.4, "label": "left"},
	{"name": "MÉXICO - EE.UU.", "sub": "Frontera norte", "lon": -106.4, "lat": 31.7, "label": "right"},
]

# Contornos simplificados (lon, lat)
const NORTH := [
	[-125, 50], [-124.5, 48], [-124, 42], [-122.5, 37.5], [-120.5, 34.5], [-117.2, 32.6], [-115.8, 30],
	[-114, 28], [-112, 25.5], [-110, 23], [-109.5, 23.2], [-110.5, 24.3], [-112.3, 27], [-113.2, 29],
	[-114.7, 31.6], [-112.8, 31.3], [-111, 29], [-109.5, 27], [-108, 25.3], [-106, 23], [-105.5, 20.5],
	[-103, 18.5], [-99, 16.7], [-95, 16], [-92, 14.5], [-89, 13.3], [-87.5, 13], [-86, 11.5], [-85.7, 10],
	[-84.5, 9.5], [-83, 8.2], [-80.5, 7.5], [-78, 8], [-77.4, 7.9], [-77.5, 8.8], [-79.5, 9.5], [-81.5, 9],
	[-83.5, 10.8], [-83.4, 14.5], [-85, 16], [-88.2, 15.8], [-88.3, 18.5], [-87.5, 21.4], [-90.3, 21],
	[-91, 19], [-94.5, 18.2], [-96, 19.5], [-97.5, 22.5], [-97.2, 25.8], [-97.4, 27.5], [-94.5, 29.5],
	[-90, 29.2], [-89, 30.3], [-85, 29.7], [-83, 29], [-82.7, 27.5], [-81.2, 25.2], [-80.1, 26],
	[-80.5, 28.5], [-81.4, 30.7], [-79, 33.5], [-76, 35], [-75.5, 37.5], [-74, 40.5], [-70, 41.5],
	[-70.6, 43], [-67, 44.8], [-64.5, 45.5], [-61, 45.5], [-60, 47], [-60, 50],
]
const SOUTH := [
	[-77.4, 8.6], [-75.5, 10.5], [-72, 12], [-68, 10.5], [-63, 10.7], [-60, 8.5], [-52, 5], [-50, 0],
	[-44, -2.5], [-35, -5], [-35, -9], [-39, -13], [-39, -18], [-41, -22], [-48, -26], [-53, -34],
	[-58, -34.5], [-57, -38], [-62, -39], [-65, -42], [-65, -46], [-69, -51], [-68, -55], [-72, -54],
	[-75, -48], [-73, -40], [-72, -30], [-70, -18], [-76, -14], [-81, -5], [-80, -1], [-78, 2],
]
# Fronteras aproximadas de los países de la ruta
const BORDERS := [
	[[-58, -34.5], [-58.4, -30], [-57, -27.5], [-54.6, -25.6], [-54.3, -24], [-58, -20], [-60, -16],
		[-65, -10], [-69.5, -11]],
	[[-62.5, -22], [-67.5, -22.8], [-68.5, -20], [-69.5, -17.5], [-68.8, -12.5]],
	[[-117.2, 32.6], [-114.8, 32.5], [-111, 31.3], [-108.2, 31.3], [-106.5, 31.8], [-104.5, 29.6],
		[-103, 29], [-101.4, 29.8], [-99.5, 27.5], [-97.2, 25.8]],
]

const S := 2.3
const OX := 16.0
const OY := 12.0

var t := 0.0
var from_i := -1
var to_i := 0
var coming_soon := false
var title := Label.new()
var info := Label.new()
var hint := Label.new()


func _ready() -> void:
	add_to_group("map")
	RenderingServer.set_default_clear_color(Color(0.03, 0.08, 0.14))
	to_i = Game.level
	from_i = to_i - 1
	coming_soon = to_i >= Levels.LIST.size()
	var ui := CanvasLayer.new()
	add_child(ui)
	for l in [title, info, hint]:
		l.position = Vector2(262, 0)
		l.size = Vector2(210, 270)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		ui.add_child(l)
	title.position.y = 40
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	info.position.y = 64
	info.add_theme_font_size_override("font_size", 10)
	hint.position.y = 230
	hint.add_theme_font_size_override("font_size", 9)
	var stop: Dictionary = STOPS[mini(to_i, STOPS.size() - 1)]
	if coming_soon:
		title.text = "PRÓXIMA PARADA"
		info.text = "%s\n%s\n\nMISIÓN %d: PRÓXIMAMENTE\n\nPuntos: %d   Vidas: %d" % [stop["name"], stop["sub"], to_i + 1, Game.score, Game.lives]
	else:
		title.text = "MISIÓN %d" % (to_i + 1)
		info.text = "%s\n%s\n\nObjetivo: cruzar la zona y\nderrotar al jefe.\n\nPuntos: %d   Vidas: %d" % [stop["name"], stop["sub"], Game.score, Game.lives]
	Game.play_music("menu")


func _xy(lon: float, lat: float) -> Vector2:
	return Vector2(OX + (lon + 125.0) * S, OY + (50.0 - lat) * S)


func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_xy(p[0], p[1]))
	return out


func _stop_pos(i: int) -> Vector2:
	return _xy(STOPS[i]["lon"], STOPS[i]["lat"])


func _process(delta: float) -> void:
	t += delta
	var ready_to_go := t > 1.8
	hint.text = ("Pulsa para volver al menú" if coming_soon else "Pulsa para empezar") if ready_to_go and int(t * 2.0) % 2 == 0 else ""
	if ready_to_go and Game.accept_pressed():
		Game.sfx("select", -4.0)
		if coming_soon:
			Game.to_menu()
		else:
			Game.go_level()
	queue_redraw()


func _draw() -> void:
	# cuadrícula de mapa militar
	for x in range(0, 262, 23):
		draw_line(Vector2(x, 0), Vector2(x, 270), Color(0.2, 0.4, 0.5, 0.15), 1)
	for y in range(0, 270, 23):
		draw_line(Vector2(0, y), Vector2(262, y), Color(0.2, 0.4, 0.5, 0.15), 1)
	var land := Color(0.3, 0.42, 0.28)
	for poly in [NORTH, SOUTH]:
		var pts := _poly(poly)
		draw_colored_polygon(pts, land)
		pts.append(pts[0])
		draw_polyline(pts, land.lightened(0.3), 1)
	for b in BORDERS:
		var pts := _poly(b)
		for i in pts.size() - 1:
			if i % 2 == 0:
				draw_line(pts[i], pts[i + 1], Color(0.85, 0.9, 0.7, 0.6), 1)
	draw_rect(Rect2(0, 0, 262, 270), Color(0.6, 0.8, 0.9, 0.4), false, 1)

	# ruta: tramos completados y el tramo animado hacia el destino
	for i in range(0, mini(to_i, STOPS.size() - 1)):
		_dashed(_stop_pos(i), _stop_pos(i + 1), 1.0, Color(1, 0.85, 0.2))
	var dest := mini(to_i, STOPS.size() - 1)
	var k := clampf(t / 1.5, 0.0, 1.0)
	if from_i >= 0 and from_i < STOPS.size() - 1:
		_dashed(_stop_pos(from_i), _stop_pos(dest), k, Color(1, 0.3, 0.2))
		var p := _stop_pos(from_i).lerp(_stop_pos(dest), k)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3, 3), p + Vector2(-3, 3)]), Color.WHITE)

	# paradas
	for i in STOPS.size():
		var sp := _stop_pos(i)
		if i < to_i:
			draw_circle(sp, 4, Color(0.2, 0.8, 0.3))
			draw_line(sp + Vector2(-2, 0), sp + Vector2(-0.5, 2), Color.WHITE, 1)
			draw_line(sp + Vector2(-0.5, 2), sp + Vector2(2.5, -2), Color.WHITE, 1)
		elif i == dest:
			var r := 4.0 + 3.0 * absf(sin(t * 4.0))
			draw_circle(sp, r + 3, Color(1, 0.2, 0.1, 0.3))
			draw_circle(sp, 4, Color(1, 0.2, 0.1))
			draw_arc(sp, 9, 0, TAU, 20, Color(1, 0.3, 0.2), 1)
		else:
			draw_circle(sp, 3, Color(0.5, 0.5, 0.5))
		var label: String = STOPS[i]["name"]
		var lw := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var lp := sp + Vector2(8, 3)
		match STOPS[i].get("label", "right"):
			"left": lp = sp + Vector2(-8 - lw, 3)
			"below": lp = sp + Vector2(-lw / 2.0, 16)
		draw_string(ThemeDB.fallback_font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color.WHITE if i <= dest else Color(0.7, 0.7, 0.7))


func _dashed(a: Vector2, b: Vector2, k: float, c: Color) -> void:
	var end := a.lerp(b, k)
	var n := int(a.distance_to(end) / 4.0)
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(end, float(i) / n), a.lerp(end, float(i + 1) / n), c, 2)
