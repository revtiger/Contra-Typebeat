extends Node2D
## Bomba que cae (del caza o del helicóptero) o granada enemiga en arco (level.throw_grenade). Mientras tanto
## dibuja una marca de aviso en el suelo. Si jet es null, cae desde su posición inicial en cuanto aparece.
## Algunas granadas lanzadas por enemigos (parryable, PARRY_CHANCE) se pueden devolver: parpadean en blanco todo
## el trayecto y, si entran en la zona de parry del héroe (player.parry_point) cuando dispara
## (player._try_parry), vuelven por el mismo arco y con la misma velocidad hacia quien la lanzó y explotan al
## tocar el suelo, dañando a los enemigos y no al héroe.

## probabilidad de que una granada enemiga se pueda devolver
const PARRY_CHANCE := 0.25
const RADIUS := 3.5  # radio de la granada (para tocar la zona de parry)

var main
var jet = null
var target_x := 0.0
var falling := false
var vel := Vector2.ZERO
var gravity := 380.0
var ground_y := 262.0
var t := 0.0
var parryable := false
var returned := false
var origin := Vector2.ZERO  # de dónde salió (hacia donde vuelve si la devuelven)


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 6
	var gy: float = main.ground_y_at(target_x)
	ground_y = gy if gy < 900.0 else 262.0
	if parryable:
		add_to_group("granada_enemiga")
	if jet == null:
		_start_fall(position)


func _start_fall(from: Vector2) -> void:
	falling = true
	position = from
	origin = from
	Game.sfx("whistle", -12.0, randf_range(0.9, 1.1))


func _physics_process(delta: float) -> void:
	t += delta
	if not falling:
		if not is_instance_valid(jet):
			queue_free()
			return
		if jet.position.x <= target_x:
			_start_fall(Vector2(target_x, jet.position.y + 6))
	else:
		vel.y += gravity * delta
		position += vel * delta
		# explota solo al tocar el Terreno (suelo, paredes o plataformas al caer), no al tocar a nadie: así da
		# tiempo a devolverla, y la devuelta no estalla al llegar al enemigo
		if main.touches_terrain(position + Vector2(0, 3), vel.y < 0.0):
			if returned:
				main.blast(position + Vector2(0, -1), 26.0, false, 5, true)  # ahora es del héroe: daña a los enemigos
			else:
				main.blast(position + Vector2(0, -1), 26.0, true, 5, false)  # no daña a los suyos
			queue_free()
			return
		if position.y > 320.0:
			queue_free()
			return
	queue_redraw()


## Se puede devolver ahora: es de las que parpadean, no se ha devuelto y toca la zona de parry del héroe.
func can_parry() -> bool:
	if not parryable or returned or not falling:
		return false
	var p = main.player
	return not p.dead and position.distance_to(p.parry_point()) < p.PARRY_R + RADIUS


## Devuelta: con la velocidad al revés, la misma gravedad la lleva por el mismo arco de vuelta a origin.
func parry() -> void:
	returned = true
	remove_from_group("granada_enemiga")
	vel = -vel
	target_x = origin.x
	Game.sfx("hit", -4.0, 1.5)


func _draw() -> void:
	if not returned and int(t * 8.0) % 2 == 0:
		var m := to_local(Vector2(target_x, ground_y - 2.0))
		draw_colored_polygon(PackedVector2Array([m + Vector2(-6, 0), m + Vector2(6, 0), m + Vector2(0, -10)]), Color(1, 0.15, 0.1))
		draw_rect(Rect2(m + Vector2(-0.5, -7), Vector2(1.5, 4)), Color.WHITE)
		draw_rect(Rect2(m + Vector2(-0.5, -2), Vector2(1.5, 1)), Color.WHITE)
	if falling:
		var c := Color(0.2, 0.22, 0.2)
		var tapa := Color(0.6, 0.1, 0.1)
		# se puede devolver: parpadeo suave hacia el blanco durante todo el trayecto
		if parryable and not returned and int(t * 14.0) % 2 == 0:
			c = c.lerp(Color.WHITE, 0.6)
			tapa = tapa.lerp(Color.WHITE, 0.6)
		draw_circle(Vector2.ZERO, RADIUS, c)
		draw_rect(Rect2(-3, -8, 6, 5), c)
		draw_line(Vector2(-3, -8), Vector2(3, -8), tapa, 1)
