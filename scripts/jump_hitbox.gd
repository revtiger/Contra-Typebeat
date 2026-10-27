extends Area2D
## Jump hitbox: punto del mapa que da un segundo impulso en el aire (doble salto). Si la zona de agarre del héroe
## (player.grab_point) lo toca y se pulsa disparar en el aire, el héroe sube otra vez (player.BOOST_V). Sirve para
## llegar a techos, pisos superiores o plataformas que solo se alcanzan con el timing correcto.
## Capa 6 Interactivos (ARQUITECTURA.md): no detecta nada; el héroe lo busca con una consulta de física.
## Qué es en el arte (lámpara, cartel, cornisa…) se decide en el pixel art final.

const SIZE := Vector2(12, 12)


func _ready() -> void:
	add_to_group("jump_hitbox")
	collision_layer = 32  # Interactivos
	collision_mask = 0
	monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = SIZE
	cs.shape = r
	add_child(cs)
