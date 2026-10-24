extends Node2D
## Salpicadura de sangre pixelada (gore de arcade, al estilo Metal Slug): gotas cuadradas que salen disparadas
## en la dirección del golpe, caen con gravedad y se quedan un momento en el suelo antes de desvanecerse.
## Uso: Sangre.salpicar(padre, posición, dirección, cantidad).

const COLORS := [Color(0.55, 0.03, 0.05), Color(0.75, 0.06, 0.07), Color(0.92, 0.16, 0.12), Color(0.38, 0.02, 0.04)]
const GRAVITY := 520.0
const LIFE := 1.1

var drops := []   # [pos, vel, color, size, landed]
var t := 0.0
var floor_y := 1e9


static func salpicar(parent: Node, pos: Vector2, dir: Vector2, n := 10, floor_y := 1e9) -> void:
	if parent == null:
		return
	var s = load("res://scripts/sangre.gd").new()
	s.position = pos
	s.floor_y = floor_y - pos.y
	for i in n:
		var v := dir.normalized().rotated(randf_range(-0.7, 0.7)) * randf_range(40.0, 150.0) + Vector2(0, randf_range(-90.0, -20.0))
		s.drops.append([Vector2(randf_range(-2, 2), randf_range(-2, 2)), v, COLORS[randi() % COLORS.size()],
			2.0 if randf() < 0.6 else 1.0, false])
	parent.add_child(s)


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	t += delta
	if t >= LIFE:
		queue_free()
		return
	for d in drops:
		if d[4]:
			continue
		d[1].y += GRAVITY * delta
		d[0] += d[1] * delta
		if d[0].y >= floor_y:
			d[0].y = floor_y
			d[4] = true  # mancha en el suelo
	queue_redraw()


func _draw() -> void:
	var a := clampf((LIFE - t) / 0.35, 0.0, 1.0)
	for d in drops:
		var c: Color = d[2]
		c.a = a
		var sz: float = d[3]
		var p: Vector2 = d[0].round()
		if d[4]:
			draw_rect(Rect2(p + Vector2(-sz, 0), Vector2(sz * 2.0 + 1.0, 1)), c)
		else:
			draw_rect(Rect2(p, Vector2(sz, sz)), c)
