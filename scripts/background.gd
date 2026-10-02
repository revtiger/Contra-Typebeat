extends Node2D
## Capas de fondo con parallax. main debe tener cam_left.
## Jungla: sky, mountains, jungle, water. Desierto: sky, mesas, dunes, chasm.
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
	if kind == "water":
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	match kind:
		"sky":
			var top := Color(0.08, 0.1, 0.3)
			var bottom := Color(0.95, 0.55, 0.35)
			if theme == "desert":
				top = Color(0.35, 0.55, 0.85)
				bottom = Color(1.0, 0.82, 0.55)
			draw_polygon(
				PackedVector2Array([Vector2(0, 0), Vector2(480, 0), Vector2(480, 270), Vector2(0, 270)]),
				PackedColorArray([top, top, bottom, bottom]))
			if theme == "desert":
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
		"water":
			draw_rect(Rect2(-60, 246, WIDTH, 30), Color(0.1, 0.35, 0.7))
			for i in int(WIDTH / 16.0):
				var wx := -60 + i * 16 + sin(t * 2.0 + i) * 3.0
				draw_line(Vector2(wx, 249), Vector2(wx + 7, 249), Color(0.6, 0.8, 1.0), 1)
		"chasm":
			draw_polygon(
				PackedVector2Array([Vector2(-60, 225), Vector2(WIDTH, 225), Vector2(WIDTH, 275), Vector2(-60, 275)]),
				PackedColorArray([Color(0.45, 0.25, 0.15), Color(0.45, 0.25, 0.15), Color(0.08, 0.04, 0.03), Color(0.08, 0.04, 0.03)]))
