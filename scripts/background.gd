extends Node2D
## Capas de fondo con parallax. main debe tener cam_left.
## Jungla: sky, mountains, jungle, water. Desierto: sky, mesas, dunes, chasm.
## Ciudad: sky, colonial (edificios con cúpulas y bandera), ruins (ruinas y carteles de propaganda inventados), sewer.
## Con screen_scroll = true el fondo se desplaza solo (menú e intro, sin cámara).

var kind := "mountains"
var theme := "jungle"
var factor := 0.8
var screen_scroll := false
var main
var t := 0.0

const WIDTH := 5400.0


func _ready() -> void:
	if main == null:
		main = get_tree().get_first_node_in_group("main")


func _process(delta: float) -> void:
	if kind == "sky":
		return
	t += delta
	if screen_scroll:
		position.x = -fmod(main.cam_left * (1.0 - factor), 3000.0)
	else:
		position.x = main.cam_left * factor
	if kind in ["water", "colonial"]:
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	match kind:
		"sky":
			var top := Color(0.08, 0.1, 0.3)
			var bottom := Color(0.95, 0.55, 0.35)
			if theme == "city":
				top = Color(0.22, 0.08, 0.12)
				bottom = Color(0.98, 0.5, 0.18)
			if theme == "desert":
				top = Color(0.35, 0.55, 0.85)
				bottom = Color(1.0, 0.82, 0.55)
			draw_polygon(
				PackedVector2Array([Vector2(0, 0), Vector2(480, 0), Vector2(480, 270), Vector2(0, 270)]),
				PackedColorArray([top, top, bottom, bottom]))
			if theme == "city":
				rng.seed = 5
				for i in 7:
					var cy := rng.randf_range(30, 120)
					draw_rect(Rect2(rng.randf_range(-40, 440), cy, rng.randf_range(80, 160), rng.randf_range(4, 9)), Color(0.35, 0.12, 0.14, 0.5))
				draw_circle(Vector2(90, 150), 30, Color(1, 0.75, 0.35, 0.5))
				draw_circle(Vector2(90, 150), 20, Color(1, 0.85, 0.5))
				for h in [Vector2(120, 55), Vector2(330, 80), Vector2(410, 40)]:
					draw_rect(Rect2(h.x - 6, h.y - 2, 12, 4), Color(0.12, 0.08, 0.1))
					draw_line(h + Vector2(4, -1), h + Vector2(12, -3), Color(0.12, 0.08, 0.1), 1)
					draw_line(h + Vector2(-10, -4), h + Vector2(10, -4), Color(0.12, 0.08, 0.1, 0.7), 1)
			elif theme == "desert":
				draw_circle(Vector2(360, 70), 40, Color(1, 0.95, 0.7, 0.25))
				draw_circle(Vector2(360, 70), 24, Color(1, 0.97, 0.8))
				rng.seed = 11
				for i in 5:
					var y := rng.randf_range(60, 150)
					draw_line(Vector2(0, y), Vector2(480, y + 2), Color(1, 1, 1, 0.07), 1)
			else:
				rng.seed = 3
				for i in 40:
					draw_rect(Rect2(rng.randf() * 480, rng.randf() * 110, 1, 1), Color(1, 1, 1, rng.randf_range(0.3, 0.9)))
				draw_circle(Vector2(380, 150), 26, Color(1, 0.8, 0.5, 0.9))
		"mountains":
			rng.seed = 7
			var pts := PackedVector2Array([Vector2(-60, 270)])
			var x := -60.0
			while x < WIDTH:
				x += rng.randf_range(40, 90)
				pts.append(Vector2(x, rng.randf_range(95, 165)))
			pts.append(Vector2(x, 270))
			draw_colored_polygon(pts, Color(0.28, 0.2, 0.38))
		"mesas":
			rng.seed = 21
			var x := -60.0
			while x < WIDTH:
				var w := rng.randf_range(50, 140)
				var top := rng.randf_range(100, 160)
				var c := Color(0.72, 0.36, 0.25).lerp(Color(0.85, 0.55, 0.45), rng.randf() * 0.5)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, 270), Vector2(x + 10, top + 8), Vector2(x + 14, top), Vector2(x + w - 14, top),
					Vector2(x + w - 10, top + 8), Vector2(x + w, 270)]), c)
				for s in 3:
					var sy := top + 14 + s * 16
					draw_line(Vector2(x + 12, sy), Vector2(x + w - 12, sy), c.darkened(0.15), 2)
				x += w + rng.randf_range(20, 90)
		"jungle":
			rng.seed = 13
			var x := -60.0
			while x < WIDTH:
				x += rng.randf_range(25, 70)
				var top := Vector2(x + rng.randf_range(-12, 12), rng.randf_range(115, 150))
				draw_line(Vector2(x, 240), top, Color(0.3, 0.2, 0.15), 4)
				for a in 6:
					var ang := PI + a * PI / 5.0
					draw_line(top, top + Vector2.from_angle(ang) * 18 + Vector2(0, 6), Color(0.1, 0.35, 0.18), 3)
			for i in int(WIDTH / 14.0):
				draw_circle(Vector2(-60 + i * 14, 205 + rng.randf_range(-12, 8)), rng.randf_range(12, 20), Color(0.08, 0.3, 0.15))
			draw_rect(Rect2(-60, 205, WIDTH + 60, 70), Color(0.08, 0.3, 0.15))
		"dunes":
			rng.seed = 17
			var pts := PackedVector2Array([Vector2(-60, 270)])
			for i in int(WIDTH / 8.0) + 1:
				var px := -60.0 + i * 8.0
				pts.append(Vector2(px, 196 + sin(px * 0.013) * 12 + sin(px * 0.041) * 5))
			pts.append(Vector2(-60 + (int(WIDTH / 8.0)) * 8.0, 270))
			draw_colored_polygon(pts, Color(0.87, 0.66, 0.4))
			var x := -60.0
			while x < WIDTH:
				x += rng.randf_range(70, 200)
				var base := 200 + sin(x * 0.013) * 12 + sin(x * 0.041) * 5
				var h := rng.randf_range(16, 30)
				var cc := Color(0.3, 0.5, 0.25)
				draw_line(Vector2(x, base), Vector2(x, base - h), cc, 5)
				draw_line(Vector2(x - 7, base - h * 0.5), Vector2(x - 7, base - h * 0.8), cc, 3)
				draw_line(Vector2(x - 7, base - h * 0.5), Vector2(x, base - h * 0.5), cc, 3)
				draw_line(Vector2(x + 7, base - h * 0.4), Vector2(x + 7, base - h * 0.65), cc, 3)
				draw_line(Vector2(x + 7, base - h * 0.4), Vector2(x, base - h * 0.4), cc, 3)
			# restos de vehículos quemados
			rng.seed = 29
			x = 200.0
			while x < WIDTH:
				var by := 204 + sin(x * 0.013) * 12
				draw_rect(Rect2(x, by - 8, 26, 8), Color(0.3, 0.26, 0.22))
				draw_rect(Rect2(x + 6, by - 13, 12, 5), Color(0.3, 0.26, 0.22))
				draw_line(Vector2(x + 18, by - 11), Vector2(x + 32, by - 16), Color(0.3, 0.26, 0.22), 2)
				x += rng.randf_range(500, 900)
		"colonial":
			_draw_colonial(rng)
		"ruins":
			_draw_ruins(rng)
		"sewer":
			draw_rect(Rect2(-60, 232, WIDTH, 45), Color(0.08, 0.06, 0.07))
			for i in int(WIDTH / 40.0):
				draw_rect(Rect2(-60 + i * 40, 240, 22, 3), Color(0.2, 0.16, 0.14))
		"water":
			draw_rect(Rect2(-60, 246, WIDTH, 30), Color(0.1, 0.35, 0.7))
			for i in int(WIDTH / 16.0):
				var wx := -60 + i * 16 + sin(t * 2.0 + i) * 3.0
				draw_line(Vector2(wx, 249), Vector2(wx + 7, 249), Color(0.6, 0.8, 1.0), 1)
		"chasm":
			draw_polygon(
				PackedVector2Array([Vector2(-60, 225), Vector2(WIDTH, 225), Vector2(WIDTH, 275), Vector2(-60, 275)]),
				PackedColorArray([Color(0.45, 0.25, 0.15), Color(0.45, 0.25, 0.15), Color(0.08, 0.04, 0.03), Color(0.08, 0.04, 0.03)]))


## Edificios coloniales lejanos: fachadas con arcos, cúpulas, torres y una bandera que ondea.
func _draw_colonial(rng: RandomNumberGenerator) -> void:
	rng.seed = 31
	var base := Color(0.36, 0.16, 0.14)
	var x := -60.0
	while x < WIDTH:
		var w := rng.randf_range(70, 150)
		var h := rng.randf_range(50, 90)
		var y := 215.0 - h
		draw_rect(Rect2(x, y, w, h + 60), base)
		draw_rect(Rect2(x - 3, y, w + 6, 4), base.lightened(0.12))
		for ax in range(int(x) + 8, int(x + w) - 8, 14):
			draw_rect(Rect2(ax, y + 14, 7, 12), base.darkened(0.35))
			draw_circle(Vector2(ax + 3.5, y + 14), 3.5, base.darkened(0.35))
			draw_rect(Rect2(ax, y + 38, 7, 10), Color(0.95, 0.55, 0.2, 0.35))
		var kind_roll := rng.randf()
		if kind_roll < 0.35:
			# cúpula con linterna
			var cx := x + w * 0.5
			draw_circle(Vector2(cx, y), w * 0.18, base.lightened(0.08))
			draw_rect(Rect2(cx - w * 0.18, y, w * 0.36, 6), base)
			draw_rect(Rect2(cx - 2, y - w * 0.18 - 10, 4, 10), base.lightened(0.08))
		elif kind_roll < 0.6:
			# dos torres de campanario
			for tx in [x + 6, x + w - 20]:
				draw_rect(Rect2(tx, y - 36, 14, 36), base.lightened(0.05))
				draw_rect(Rect2(tx + 4, y - 30, 6, 8), base.darkened(0.4))
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 1, y - 36), Vector2(tx + 7, y - 48), Vector2(tx + 15, y - 36)]), base.lightened(0.05))
		elif kind_roll < 0.72:
			# asta con bandera ondeando (bandera nacional, sin personas reales)
			var fx := x + w * 0.5
			draw_line(Vector2(fx, y), Vector2(fx, y - 60), Color(0.25, 0.2, 0.2), 2)
			for i in 12:
				var wave := sin(t * 3.0 + i * 0.6) * 2.0
				var col := Color(0, 0.45, 0.28) if i < 4 else (Color(0.92, 0.9, 0.86) if i < 8 else Color(0.78, 0.12, 0.16))
				draw_rect(Rect2(fx + 1 + i * 2, y - 60 + wave, 2, 16), col)
		x += w + rng.randf_range(4, 30)


## Ruinas cercanas: edificios rotos, coches quemados y carteles de propaganda inventados.
func _draw_ruins(rng: RandomNumberGenerator) -> void:
	rng.seed = 47
	var col := Color(0.2, 0.1, 0.1)
	var x := -60.0
	var font := ThemeDB.fallback_font
	var slogans := ["¡TODO VA DE MARAVILLA!", "LA PRESIDENTA TE CUIDA", "OBEDECER ES AVANZAR", "PROHIBIDO PREOCUPARSE"]
	var n := 0
	while x < WIDTH:
		var w := rng.randf_range(40, 90)
		var h := rng.randf_range(40, 110)
		var top := 225.0 - h
		var pts := PackedVector2Array([Vector2(x, 240), Vector2(x, top + rng.randf_range(0, 20)), Vector2(x + w * 0.3, top),
			Vector2(x + w * 0.45, top + rng.randf_range(10, 30)), Vector2(x + w * 0.7, top + rng.randf_range(0, 15)),
			Vector2(x + w, top + rng.randf_range(10, 40)), Vector2(x + w, 240)])
		draw_colored_polygon(pts, col)
		for wy in range(int(top) + 14, 220, 12):
			for wx in range(int(x) + 6, int(x + w) - 8, 10):
				if rng.randf() < 0.6:
					draw_rect(Rect2(wx, wy, 5, 6), Color(0.08, 0.04, 0.05) if rng.randf() < 0.8 else Color(1, 0.55, 0.15, 0.7))
		if rng.randf() < 0.3:
			# cartel de propaganda en un edificio
			var bw := 92.0
			var bx := x + (w - bw) * 0.5
			var by := top + 16
			draw_rect(Rect2(bx, by, bw, 40), Color(0.85, 0.8, 0.7))
			draw_rect(Rect2(bx + 2, by + 2, bw - 4, 36), Color(0.62, 0.14, 0.16))
			draw_circle(Vector2(bx + 16, by + 20), 9, Color(0.75, 0.75, 0.8))
			draw_rect(Rect2(bx + 11, by + 17, 10, 3), Color(0.9, 0.1, 0.1))
			# el lema en dos líneas, cortado por el espacio más cercano a la mitad
			var text: String = slogans[n % slogans.size()]
			var cut := text.length() / 2
			for d in text.length():
				if cut + d < text.length() and text[cut + d] == " ":
					cut += d
					break
				if cut - d > 0 and text[cut - d] == " ":
					cut -= d
					break
			draw_string(font, Vector2(bx + 29, by + 17), text.substr(0, cut), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.95, 0.85))
			draw_string(font, Vector2(bx + 29, by + 29), text.substr(cut + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.95, 0.85))
			n += 1
		if rng.randf() < 0.25:
			# coche quemado
			var cx := x + w + 4
			draw_rect(Rect2(cx, 222, 34, 10), Color(0.16, 0.12, 0.12))
			draw_rect(Rect2(cx + 7, 214, 18, 8), Color(0.16, 0.12, 0.12))
			draw_circle(Vector2(cx + 7, 232), 4, Color(0.08, 0.06, 0.06))
			draw_circle(Vector2(cx + 27, 232), 4, Color(0.08, 0.06, 0.06))
		x += w + rng.randf_range(10, 50)
