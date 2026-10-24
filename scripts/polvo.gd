extends Node2D
## Nubecitas de polvo a los pies (al saltar y al aterrizar): bolitas pixeladas que se abren a los lados, suben un
## poco y se desvanecen. Uso: Polvo.levantar(padre, posición_de_los_pies, cantidad).

const LIFE := 0.35
const COLOR := Color(0.86, 0.78, 0.62)

var puffs := []  # [pos, vel, radio]
var t := 0.0


static func levantar(parent: Node, feet: Vector2, n := 6) -> void:
	if parent == null:
		return
	var p = load("res://scripts/polvo.gd").new()
	p.position = feet
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		p.puffs.append([Vector2(side * randf_range(1, 4), -1), Vector2(side * randf_range(25, 60), randf_range(-18, -6)),
			randf_range(1.5, 3.0)])
	parent.add_child(p)


func _ready() -> void:
	z_index = 3


func _process(delta: float) -> void:
	t += delta
	if t >= LIFE:
		queue_free()
		return
	for d in puffs:
		d[0] += d[1] * delta
		d[1] *= 1.0 - 6.0 * delta
	queue_redraw()


func _draw() -> void:
	var k := t / LIFE
	var c := COLOR
	c.a = 0.85 * (1.0 - k)
	for d in puffs:
		draw_circle(d[0].round(), d[2] * (1.0 + k), c)
