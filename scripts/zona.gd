extends Area2D
## Zona (capa 7, ARQUITECTURA.md): área invisible que dispara un evento cuando el héroe está dentro.
##   "puerta": con Arriba entra al interior de un edificio grande (level.enter_interior)
##   "salida": al llegar sale del interior y vuelve a la calle más adelante (level.exit_interior)
## En el greybox se ve como una caja azul con su etiqueta.

var tipo := "puerta"
var interior := ""  # puerta: interior al que lleva (levels.gd, INTERIORES)
var etiqueta := ""
var size := Vector2(40, 62)
var level


func _ready() -> void:
	level = get_tree().get_first_node_in_group("level")
	collision_layer = 64  # Zonas
	collision_mask = 2  # solo detecta al jugador (MainHurtbox)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = Vector2(0, -size.y / 2.0)
	add_child(cs)


func _physics_process(_delta: float) -> void:
	if level.state != "play" or not overlaps_body(level.player) or level.player.dead:
		return
	match tipo:
		"puerta":
			if Input.is_action_just_pressed("up"):
				level.enter_interior(interior)
		"salida":
			level.exit_interior()
