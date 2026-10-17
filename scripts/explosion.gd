extends Node2D
## Explosión: animación de Sprite Fusion (assets/sprites/explosion.png, 12 fotogramas de 64x64: destello,
## bola de fuego, estallido y humo que se deshace) escalada al radio, más metralla con gravedad.
## Origen: tools/sprites/spritefusion/explosion/ (semilla hecha con PixelLab, animada con Sprite Fusion).

const SHEET := preload("res://assets/sprites/explosion.png")
const FRAME := 64
const FRAMES := 12
const FPS := 14.0
const DUR := FRAMES / FPS
## diámetro de la bola de fuego dentro del fotograma (px): con él se escala la animación al radio r
const FIRE_SIZE := 58.0

var r := 12.0
var t := 0.0
var debris := []  # [pos, vel, tamaño]


func _ready() -> void:
	z_index = 10
	var n := int(clampf(r / 2.0, 3, 16))
	for i in n:
		var a := randf_range(PI * 1.05, PI * 1.95)
		debris.append([Vector2.ZERO, Vector2.from_angle(a) * randf_range(60, 60 + r * 6), randf_range(1, 2.5)])


func _process(delta: float) -> void:
	t += delta
	if t >= DUR:
		queue_free()
		return
	for d in debris:
		d[1].y += 400.0 * delta
		d[0] += d[1] * delta
	queue_redraw()


func _draw() -> void:
	var f := mini(int(t * FPS), FRAMES - 1)
	var s := r * 2.4 / FIRE_SIZE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	draw_texture_rect_region(SHEET, Rect2(-FRAME / 2.0, -FRAME / 2.0, FRAME, FRAME), Rect2(f * FRAME, 0, FRAME, FRAME))
	draw_set_transform(Vector2.ZERO)
	for d in debris:
		var c := Color(1, 0.7, 0.2).lerp(Color(0.3, 0.2, 0.1), clampf(t * 2.0, 0.0, 1.0))
		draw_rect(Rect2(d[0], Vector2(d[2], d[2])), c)
