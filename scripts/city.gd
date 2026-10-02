extends Node2D
## Ciudad de noche con un rascacielos que estalla y arde (intro y menú, estilo "Duro de matar").

const TOWER := Rect2(330, 108, 64, 170)
## rascacielos en llamas animado (PixelLab, tools/sprites/tower.py): 9 fotogramas de 96x192
const TOWER_TEX := preload("res://assets/sprites/city_tower.png")
const TOWER_FRAME := Vector2(96, 192)
const TOWER_FRAMES := 9
const TOWER_FPS := 10.0

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
	if burning:
		_draw_burning_tower(glow)
		_draw_street()
		return
	draw_rect(tw, Color(0.14, 0.15, 0.2))
	draw_rect(Rect2(tw.position.x + 26, tw.position.y - 14, 12, 14), Color(0.14, 0.15, 0.2))
	draw_line(Vector2(tw.position.x + 32, tw.position.y - 14), Vector2(tw.position.x + 32, tw.position.y - 30), Color(0.3, 0.3, 0.35), 1)
	if int(t * 2.0) % 2 == 0:
		draw_rect(Rect2(tw.position.x + 31, tw.position.y - 31, 3, 2), Color(1, 0.1, 0.1))
	rng.seed = 21
	for wy in range(int(tw.position.y) + 4, 262, 8):
		for wx in range(int(tw.position.x) + 4, int(tw.end.x) - 3, 7):
			var c := Color(0.95, 0.85, 0.5, 0.8) if rng.randf() < 0.4 else Color(0.2, 0.22, 0.3)
			draw_rect(Rect2(wx, wy, 4, 5), c)

	_draw_street()


## Sprite animado del rascacielos en llamas, con resplandor detrás y humo que tapa el borde de arriba.
func _draw_burning_tower(glow: float) -> void:
	var c := tower_top() + Vector2(0, 14)
	draw_circle(c, 60, Color(1, 0.45, 0.1, 0.12 * glow))
	draw_circle(c, 35, Color(1, 0.55, 0.15, 0.15 * glow))
	var f := int(t * TOWER_FPS) % TOWER_FRAMES
	var pos := Vector2(TOWER.get_center().x - TOWER_FRAME.x / 2.0, 270 - TOWER_FRAME.y)
	draw_texture_rect_region(TOWER_TEX, Rect2(pos, TOWER_FRAME), Rect2(Vector2(f * TOWER_FRAME.x, 0), TOWER_FRAME))
	for i in 8:
		var k := fmod(t * 0.25 + i / 8.0, 1.0)
		var sp := Vector2(pos.x + 48, pos.y + 6) + Vector2(k * 90 + sin(i * 3.0) * 8, -k * 90)
		draw_circle(sp, 10 + k * 22, Color(0.15, 0.13, 0.14, 0.6 * (1.0 - k) * glow))


func _draw_street() -> void:
	draw_rect(Rect2(0, 262, 480, 8), Color(0.05, 0.05, 0.08))
	for i in 8:
		draw_rect(Rect2(i * 64 + 20, 250, 2, 12), Color(0.2, 0.2, 0.25))
		draw_circle(Vector2(i * 64 + 21, 250), 2, Color(1, 0.85, 0.5, 0.8))
