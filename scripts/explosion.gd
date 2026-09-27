extends Node2D
## Explosión: destello, bola de fuego, metralla con gravedad y humo que sube.

var r := 12.0
var t := 0.0
var debris := []  # [pos, vel, tamaño]
var smoke := []   # [pos, vel, radio]
const DUR := 1.0


func _ready() -> void:
	z_index = 10
	var n := int(clampf(r / 2.0, 3, 16))
	for i in n:
		var a := randf_range(PI * 1.05, PI * 1.95)
		debris.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(60, 60 + r * 6), randf_range(1, 2.5)])
	for i in maxi(2, n / 2):
		smoke.append([Vector2(randf_range(-r, r) * 0.5, randf_range(-r, 0) * 0.5),
			Vector2(randf_range(-8, 8), randf_range(-25, -12)), randf_range(r * 0.3, r * 0.6)])


func _process(delta: float) -> void:
	t += delta
	if t >= DUR:
		queue_free()
		return
	for d in debris:
		d[1].y += 400.0 * delta
		d[0] += d[1] * delta
	for s in smoke:
		s[0] += s[1] * delta
	queue_redraw()


func _draw() -> void:
	var k := clampf(t / 0.45, 0.0, 1.0)
	for s in smoke:
		var a := clampf((t - 0.1) / 0.3, 0.0, 1.0) * (1.0 - t / DUR) * 0.6
		draw_circle(s[0], s[2] * (1.0 + t), Color(0.25, 0.22, 0.2, a))
	if k < 1.0:
		draw_circle(Vector2.ZERO, r * (0.5 + k), Color(1, 0.35, 0.05, 1.0 - k))
		draw_circle(Vector2.ZERO, r * (0.35 + 0.7 * k), Color(1, 0.75, 0.15, 1.0 - k))
		draw_circle(Vector2.ZERO, r * 0.5 * (1.0 - k), Color(1, 1, 0.9, 1.0 - k))
	if t < 0.05:
		draw_circle(Vector2.ZERO, r * 1.6, Color(1, 1, 1, 0.5))
	for d in debris:
		var c := Color(1, 0.7, 0.2).lerp(Color(0.3, 0.2, 0.1), clampf(t * 2.0, 0.0, 1.0))
		draw_rect(Rect2(d[0], Vector2(d[2], d[2])), c)
