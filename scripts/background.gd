extends Node2D
## Capas de fondo con parallax: cielo (fijo en pantalla), montañas, jungla y agua.

var kind := "mountains"
var factor := 0.8
var main
var t := 0.0

const WIDTH := 4800.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")


func _process(delta: float) -> void:
	if kind == "sky":
		return
	t += delta
	position.x = main.cam_left * factor
	if kind == "water":
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	match kind:
		"sky":
			draw_polygon(
				PackedVector2Array([Vector2(0, 0), Vector2(480, 0), Vector2(480, 270), Vector2(0, 270)]),
				PackedColorArray([Color(0.08, 0.1, 0.3), Color(0.08, 0.1, 0.3), Color(0.95, 0.55, 0.35), Color(0.95, 0.55, 0.35)]))
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
		"water":
			draw_rect(Rect2(-60, 246, WIDTH, 30), Color(0.1, 0.35, 0.7))
			for i in int(WIDTH / 16.0):
				var wx := -60 + i * 16 + sin(t * 2.0 + i) * 3.0
				draw_line(Vector2(wx, 249), Vector2(wx + 7, 249), Color(0.6, 0.8, 1.0), 1)
