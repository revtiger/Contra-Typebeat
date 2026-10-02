extends Node2D
## Mapa de campaña entre fases: América y Europa con la ruta de la historia
## Argentina → México → EUA → Alemania → nivel secreto (ONU, Nueva York).
## Game.level es la fase a la que se va (Levels.LIST); la zona es Game.level / 3.
## Después de la última fase muestra "¡MUNDO SALVADO!".

const Levels = preload("res://scripts/levels.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")

## Una parada por zona (lon, lat), en el orden de Levels.ZONES.
const STOPS := [
	{"name": "ARGENTINA", "lon": -58.4, "lat": -34.6, "label": "right"},
	{"name": "MÉXICO", "lon": -99.1, "lat": 19.4, "label": "left"},
	{"name": "EUA", "lon": -77.0, "lat": 38.9, "label": "left"},
	{"name": "ALEMANIA", "lon": 13.4, "lat": 52.5, "label": "below"},
	{"name": "ONU", "lon": -74.0, "lat": 40.7, "label": "above", "secret": true},
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
	[-70.6, 43], [-67, 44.8], [-64.5, 45.5], [-61, 45.5], [-60, 47], [-56, 52], [-60, 55], [-64, 60],
	[-78, 62], [-95, 60], [-110, 60], [-130, 60], [-130, 55],
]
const SOUTH := [
	[-77.4, 8.6], [-75.5, 10.5], [-72, 12], [-68, 10.5], [-63, 10.7], [-60, 8.5], [-52, 5], [-50, 0],
	[-44, -2.5], [-35, -5], [-35, -9], [-39, -13], [-39, -18], [-41, -22], [-48, -26], [-53, -34],
	[-58, -34.5], [-57, -38], [-62, -39], [-65, -42], [-65, -46], [-69, -51], [-68, -55], [-72, -54],
	[-75, -48], [-73, -40], [-72, -30], [-70, -18], [-76, -14], [-81, -5], [-80, -1], [-78, 2],
]
const EUROPE := [
	[-9.5, 43], [-9, 38.7], [-6, 36.5], [-2, 36.7], [0, 38.5], [3.2, 42], [5, 43.3], [7.5, 43.8],
	[10, 44], [12.5, 41.8], [15.5, 38], [16.5, 40], [18.5, 40.2], [13, 45.5], [19.5, 42], [23, 38],
	[26, 40.5], [29, 41], [28, 45], [30, 46.5], [40, 47], [40, 62], [30, 62], [28, 66], [31, 70],
	[25, 71], [15, 68.5], [10, 63], [5, 62], [5.5, 58.5], [8, 58], [10.5, 59.5], [12, 56.5],
	[10.5, 57.5], [8.5, 56.5], [8.6, 54.9], [4.5, 53], [2, 51], [-1.5, 49.5], [-4.5, 48.5],
	[-1.5, 46.5], [-1.5, 43.5],
]
const BRITAIN := [
	[-5.5, 50], [1.5, 51], [0.5, 53], [-1.5, 55], [-3, 58.5], [-5, 58.5], [-6, 56], [-4.5, 54.5],
	[-3, 53.5], [-4.5, 51.5],
]
const AFRICA := [
	[-17, 21], [-17, 15], [-10, 5], [5, 4.5], [10, 4], [9, -1], [13, -10], [12, -18], [15, -27],
	[18, -34.5], [25, -34], [33, -28], [40, -15], [40, 12], [33, 31], [25, 32], [20, 30.5], [10, 34],
	[10, 37], [-1, 35.5], [-6, 36], [-10, 30], [-13, 27],
]

const S := 1.5
const OX := 8.0
const OY := 20.0
const LON0 := -130.0
const LAT0 := 72.0

var t := 0.0
var from_i := -1
var to_i := 0
var won := false
var title := Label.new()
var info := Label.new()
var hint := Label.new()


func _ready() -> void:
	add_to_group("map")
	RenderingServer.set_default_clear_color(Color(0.03, 0.08, 0.14))
	won = Game.level >= Levels.LIST.size()
	to_i = mini(Game.level / 3, STOPS.size() - 1)
	from_i = (Game.level - 1) / 3 if Game.level > 0 else -1
	var ui := CanvasLayer.new()
	add_child(ui)
	for l in [title, info, hint]:
		l.position = Vector2(270, 0)
		l.size = Vector2(205, 270)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ui.add_child(l)
	title.position.y = 34
	PixelFont.apply(title, "title")
	info.position.y = 58
	PixelFont.apply(info, "white")
	hint.position.y = 236
	PixelFont.apply(hint, "small")
	if won:
		title.text = "¡MUNDO SALVADO!"
		info.text = "La Orden Mundial ha caído y el apocalipsis se ha detenido.\n\nPuntos: %d   Vidas: %d" % [Game.score, Game.lives]
	else:
		var d: Dictionary = Levels.LIST[Game.level]
		title.text = "NIVEL %s" % d["phase"]
		var target := ""
		match d["boss_role"]:
			"door": target = "Objetivo: llegar a la puerta %s." % d["phase"].substr(2)
			"final": target = "JEFE FINAL:\n%s" % d["boss_name"]
			_: target = "MINI JEFE:\n%s" % d["boss_name"]
		info.text = "%s\n%s\n\n%s\n\nPuntos: %d   Vidas: %d" % [d["zone"], d["place"], target, Game.score, Game.lives]
	Game.play_music("menu")


func _xy(lon: float, lat: float) -> Vector2:
	return Vector2(OX + (lon - LON0) * S, OY + (LAT0 - lat) * S)


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
	hint.text = ("Pulsa para volver al menú" if won else "Pulsa para empezar") if ready_to_go and int(t * 2.0) % 2 == 0 else ""
	if ready_to_go and Game.accept_pressed():
		Game.sfx("select", -4.0)
		if won:
			Game.to_menu()
		else:
			Game.go_level()
	queue_redraw()


func _draw() -> void:
	# cuadrícula de mapa militar
	for x in range(0, 268, 22):
		draw_line(Vector2(x, 0), Vector2(x, 270), Color(0.2, 0.4, 0.5, 0.15), 1)
	for y in range(0, 270, 22):
		draw_line(Vector2(0, y), Vector2(268, y), Color(0.2, 0.4, 0.5, 0.15), 1)
	var land := Color(0.3, 0.42, 0.28)
	for poly in [NORTH, SOUTH, EUROPE, BRITAIN, AFRICA]:
		var pts := _poly(poly)
		draw_colored_polygon(pts, land if poly != AFRICA else land.darkened(0.25))
		pts.append(pts[0])
		draw_polyline(pts, land.lightened(0.3), 1)
	draw_rect(Rect2(0, 0, 268, 270), Color(0.6, 0.8, 0.9, 0.4), false, 1)

	# ruta: tramos completados y el tramo animado hacia el destino
	var k := clampf(t / 1.5, 0.0, 1.0)
	var moving := from_i >= 0 and from_i != to_i and not won
	for i in range(0, to_i - (1 if moving else 0)):
		_dashed(_stop_pos(i), _stop_pos(i + 1), 1.0, Color(1, 0.85, 0.2))
	if moving:
		_dashed(_stop_pos(from_i), _stop_pos(to_i), k, Color(1, 0.3, 0.2))
		var p := _stop_pos(from_i).lerp(_stop_pos(to_i), k)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3, 3), p + Vector2(-3, 3)]), Color.WHITE)

	# paradas
	for i in STOPS.size():
		var sp := _stop_pos(i)
		var done := i < to_i or won
		var secret: bool = STOPS[i].get("secret", false) and i > to_i
		if done:
			draw_circle(sp, 4, Color(0.2, 0.8, 0.3))
			draw_line(sp + Vector2(-2, 0), sp + Vector2(-0.5, 2), Color.WHITE, 1)
			draw_line(sp + Vector2(-0.5, 2), sp + Vector2(2.5, -2), Color.WHITE, 1)
		elif i == to_i:
			var r := 4.0 + 3.0 * absf(sin(t * 4.0))
			draw_circle(sp, r + 3, Color(1, 0.2, 0.1, 0.3))
			draw_circle(sp, 4, Color(1, 0.2, 0.1))
			draw_arc(sp, 9, 0, TAU, 20, Color(1, 0.3, 0.2), 1)
		elif not secret:
			draw_circle(sp, 3, Color(0.5, 0.5, 0.5))
		var label: String = "???" if secret else STOPS[i]["name"]
		var lw := PixelFont.font("white").get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("white")).x
		var lp := sp + Vector2(8, 3)
		match STOPS[i].get("label", "right"):
			"left": lp = sp + Vector2(-8 - lw, 3)
			"below": lp = sp + Vector2(-lw / 2.0, 16)
			"above": lp = sp + Vector2(-lw / 2.0, -10)
		var lit := i <= to_i or won
		draw_string(PixelFont.font("white" if lit else "label"), lp + Vector2(0, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("white"),
			Color.WHITE if lit else Color(0.7, 0.7, 0.7))


func _dashed(a: Vector2, b: Vector2, k: float, c: Color) -> void:
	var end := a.lerp(b, k)
	var n := int(a.distance_to(end) / 4.0)
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(end, float(i) / n), a.lerp(end, float(i + 1) / n), c, 2)
