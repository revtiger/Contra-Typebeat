extends StaticBody2D
## Caja de madera (o pila de cajas) en la calle del pueblo: es suelo firme, sirve de escalón para subir a los toldos
## y de ahí a los techos. No se rompe. Sprite: assets/sprites/caja.png (PixelLab, tools/sprites/caja.py).
## alto = cuántas cajas apiladas.

const TEX := preload("res://assets/sprites/caja.png")

var alto := 1
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	collision_layer = 1
	collision_mask = 0
	var s := Vector2(TEX.get_width(), TEX.get_height() * alto)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = s - Vector2(2, 0)
	cs.shape = r
	cs.position = Vector2(0, -s.y / 2.0)
	add_child(cs)


func _physics_process(_delta: float) -> void:
	if position.x < main.cam_left - 80:
		queue_free()


func _draw() -> void:
	var w := float(TEX.get_width())
	var h := float(TEX.get_height())
	for i in alto:
		# cada caja un poco corrida para que la pila no parezca un bloque
		var dx := 0.0 if i % 2 == 0 else 1.0
		draw_texture(TEX, Vector2(-w / 2.0 + dx, -h * (i + 1)))
