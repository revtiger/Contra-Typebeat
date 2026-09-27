extends Node2D
## Explosión simple: círculos que crecen y se desvanecen.

var r := 12.0
var t := 0.0
const DUR := 0.4


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	t += delta
	if t >= DUR:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := t / DUR
	draw_circle(Vector2.ZERO, r * (0.4 + k), Color(1, 0.9, 0.3, 1.0 - k))
	draw_circle(Vector2.ZERO, r * (0.2 + 0.7 * k), Color(1, 0.4, 0.1, 1.0 - k))
