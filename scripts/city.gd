extends Node2D
## Ciudad de noche con un rascacielos que estalla y arde (intro y menú, estilo "Duro de matar").

const TOWER := Rect2(330, 108, 64, 170)
const FIRE_FLOORS := 7

var burning := false
var t := 0.0
var burn_t := 0.0


func _process(delta: float) -> void:
	t += delta
	if burning:
		burn_t += delta
	queue_redraw()


func tower_top() -> Vector2:
	return Vector2(TOWER.position.x + TOWER.size.x / 2, TOWER.position.y + 16)


func _draw() -> void:
	var glow := clampf(burn_t / 2.0, 0.0, 1.0) if burning else 0.0
	var top := Color(0.02, 0.03, 0.1)
	var bottom := Color(0.12, 0.08, 0.22).lerp(Color(0.55, 0.2, 0.08), glow * 0.6)
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(480, 0), Vector2(480, 270), Vector2(0, 270)]),
		PackedColorArray([top, top, bottom, bottom]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 60:
		draw_rect(Rect2(rng.randf() * 480, rng.randf() * 140, 1, 1), Color(1, 1, 1, rng.randf_range(0.2, 0.8)))
	draw_circle(Vector2(70, 50), 14, Color(0.95, 0.93, 0.8))
	draw_circle(Vector2(76, 46), 13, top.lerp(bottom, 0.2))

	# edificios lejanos
	rng.seed = 8
	var x := -10.0
	while x < 480:
		var w := rng.randf_range(20, 45)
		var h := rng.randf_range(50, 110)
		draw_rect(Rect2(x, 270 - h - 20, w, h + 20), Color(0.06, 0.06, 0.13))
		x += w + rng.randf_range(0, 6)
	# edificios cercanos con ventanas
	rng.seed = 12
	x = -5.0
	while x < 480:
		var w := rng.randf_range(28, 60)
		var h := rng.randf_range(40, 95)
		if x + w > TOWER.position.x - 4 and x < TOWER.end.x + 4:
			x = TOWER.end.x + 6
			continue
		var r := Rect2(x, 270 - h, w, h)
		draw_rect(r, Color(0.09, 0.09, 0.16))
		for wy in range(int(r.position.y) + 5, 262, 7):
			for wx in range(int(r.position.x) + 4, int(r.end.x) - 4, 6):
				if rng.randf() < 0.35:
					draw_rect(Rect2(wx, wy, 3, 3), Color(0.95, 0.8, 0.4, rng.randf_range(0.4, 0.9)))
		x += w + rng.randf_range(2, 10)

	# rascacielos
	var tw := TOWER
	draw_rect(tw, Color(0.14, 0.15, 0.2))
	draw_rect(Rect2(tw.position.x + 26, tw.position.y - 14, 12, 14), Color(0.14, 0.15, 0.2))
	draw_line(Vector2(tw.position.x + 32, tw.position.y - 14), Vector2(tw.position.x + 32, tw.position.y - 30), Color(0.3, 0.3, 0.35), 1)
	if int(t * 2.0) % 2 == 0:
		draw_rect(Rect2(tw.position.x + 31, tw.position.y - 31, 3, 2), Color(1, 0.1, 0.1))
	rng.seed = 21
	var floor_i := 0
	for wy in range(int(tw.position.y) + 4, 262, 8):
		var on_fire := burning and floor_i < FIRE_FLOORS
		for wx in range(int(tw.position.x) + 4, int(tw.end.x) - 3, 7):
			var c := Color(0.95, 0.85, 0.5, 0.8) if rng.randf() < 0.4 else Color(0.2, 0.22, 0.3)
			if on_fire:
				var k := 0.5 + 0.5 * sin(t * 13.0 + wx * 0.7 + wy * 1.3)
				c = Color(1, 0.35, 0.05).lerp(Color(1, 0.9, 0.3), k)
			draw_rect(Rect2(wx, wy, 4, 5), c)
		floor_i += 1

	if burning:
		# resplandor, llamas y humo
		var c := tower_top() + Vector2(0, 14)
		draw_circle(c, 60, Color(1, 0.45, 0.1, 0.12 * glow))
		draw_circle(c, 35, Color(1, 0.55, 0.15, 0.15 * glow))
		for i in 10:
			var fx := tw.position.x + 2 + i * 6.5
			var fh := 8.0 + 6.0 * absf(sin(t * 7.0 + i * 2.1))
			var fy := tw.position.y + 6 + (i % 3) * 16
			var side := -1.0 if i < 5 else 1.0
			var base := Vector2(tw.position.x if side < 0 else tw.end.x, fy)
			if i % 2 == 0:
				draw_colored_polygon(PackedVector2Array([base, base + Vector2(side * fh, -fh * 0.6), base + Vector2(0, -8)]), Color(1, 0.5, 0.1, 0.9))
			draw_colored_polygon(PackedVector2Array([Vector2(fx, tw.position.y), Vector2(fx + 3, tw.position.y - fh), Vector2(fx + 6, tw.position.y)]), Color(1, 0.6 + 0.3 * sin(t * 9.0 + i), 0.15))
		for i in 8:
			var k := fmod(t * 0.25 + i / 8.0, 1.0)
			var sp := tower_top() + Vector2(k * 90 + sin(i * 3.0) * 8, -k * 120 - 10)
			draw_circle(sp, 8 + k * 22, Color(0.15, 0.13, 0.14, 0.55 * (1.0 - k) * glow))

	# calle
	draw_rect(Rect2(0, 262, 480, 8), Color(0.05, 0.05, 0.08))
	for i in 8:
		draw_rect(Rect2(i * 64 + 20, 250, 2, 12), Color(0.2, 0.2, 0.25))
		draw_circle(Vector2(i * 64 + 21, 250), 2, Color(1, 0.85, 0.5, 0.8))
