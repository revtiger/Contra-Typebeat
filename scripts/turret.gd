extends StaticBody2D
## Nido de ametralladora: un soldado agachado tras un búnker de sacos terreros maneja una ametralladora montada.
## Solo dispara hacia la izquierda (no puede voltearse): al frente o en diagonal hacia arriba, según dónde esté el
## jugador. Si el jugador ya le pasó por detrás, deja de disparar. Aguanta varios impactos.
## Sprites: tools/sprites/turret.py (turret_soldado.png: una columna por dirección; PixelLab sobre el soldado de
## Argentina y el búnker).

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const SHEET := preload("res://assets/sprites/turret_soldado.png")
## dirección de cada fotograma
const AIMS := [Vector2(-1, 0), Vector2(-0.7071, -0.7071)]

var hp := 8
var shoot_t := 1.0
var flash := 0.0
var muzzle_flash := 0.0
var recoil := 0.0
var dir := 0
var meta: Dictionary
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	meta = SpriteUtil.meta("res://assets/sprites/turret_soldado_meta.json")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	# el búnker y el soldado que asoma por encima
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(34, 40)
	cs.shape = r
	cs.position = Vector2(0, -20)
	add_child(cs)


## Punto del fotograma (px de la hoja) en coordenadas locales: los pies (centro del borde de abajo del búnker)
## están en el origen.
func _local(p: Array) -> Vector2:
	return Vector2(p[0], p[1]) - SpriteUtil.v(meta["feet"])


func _physics_process(delta: float) -> void:
	flash -= delta
	muzzle_flash -= delta
	recoil = move_toward(recoil, 0.0, delta * 20.0)
	var p = main.player
	var to: Vector2 = (p.position + Vector2(0, -14)) - (position + _local(meta["muzzles"][0]))
	var ahead: bool = to.x < -8.0  # el jugador está delante (a la izquierda)
	if ahead:
		# en diagonal si está claramente por encima; si no, al frente
		dir = 1 if to.y / -to.x < -0.45 else 0
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and ahead and not p.dead:
		shoot_t = 1.5
		var b := Bullet.new()
		b.from_player = false
		b.vel = AIMS[dir] * 110.0
		b.position = position + _local(meta["muzzles"][dir])
		get_parent().add_child(b)
		muzzle_flash = 0.07
		recoil = 1.5
		Game.sfx("shot", -18.0, 0.55)
	if position.x < main.cam_left - 60:
		queue_free()
	queue_redraw()


func take_damage(n: int) -> void:
	hp -= n
	flash = 0.06
	Game.sfx("hit", -18.0)
	if hp <= 0 and not is_queued_for_deletion():
		main.add_score(500)
		main.explode(position + Vector2(0, -14), 20)
		queue_free()


func _draw() -> void:
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	var fr: Array = meta["frame"]
	var size := Vector2(fr[0], fr[1])
	var at := -SpriteUtil.v(meta["feet"])
	# culatazo: todo el nido tiembla un píxel hacia atrás (a la derecha) al disparar
	at.x += roundf(recoil)
	draw_texture_rect_region(SHEET, Rect2(at, size), Rect2(dir * fr[0], 0, fr[0], fr[1]), tint)
	if muzzle_flash > 0.0:
		var m: Vector2 = _local(meta["muzzles"][dir]) + AIMS[dir] * 2.0
		draw_circle(m, 3.5, Color(1, 0.85, 0.3))
		draw_circle(m, 2.0, Color(1, 1, 0.85))
