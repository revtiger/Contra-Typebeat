extends Node2D
## Impacto de bala: chispa de 6 fotogramas hecha con PixelLab (assets/sprites/impact.png, tools/sprites/impacto.py).
## Se reproduce una vez donde la bala toca algo y desaparece.

const SHEET := preload("res://assets/sprites/impact.png")
const FRAME := 24
const FRAMES := 6
const FPS := 14.0

var t := 0.0


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	t += delta
	if t >= FRAMES / FPS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var f := mini(int(t * FPS), FRAMES - 1)
	draw_texture_rect_region(SHEET, Rect2(-FRAME / 2.0, -FRAME / 2.0, FRAME, FRAME), Rect2(f * FRAME, 0, FRAME, FRAME))
