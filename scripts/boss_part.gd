extends StaticBody2D
## Pieza de un jefe por piezas: recibe los impactos y se los pasa al jefe con su nombre.

var boss
var part_name := ""


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0


func take_damage(n: int) -> void:
	if boss:
		boss.part_damage(part_name, n)
