extends StaticBody2D
## Torreta fija que gira hacia el jugador y dispara. Aguanta varios impactos.
## Sprites de PixelLab (tools/sprites/turret.py): búnker de sacos terreros y ametralladora que gira encima.

const Bullet = preload("res://scripts/bullet.gd")
const BASE := preload("res://assets/sprites/turret_base.png")
const GUN := preload("res://assets/sprites/turret_gun.png")
## pivote del arma sobre el búnker y punto de giro dentro del sprite del arma (cerca de la culata)
const PIVOT := Vector2(0, -23)
const GUN_PIVOT := Vector2(6, 3)

var hp := 8
var shoot_t := 1.0
var flash := 0.0
var aim := Vector2.LEFT
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(34, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	add_child(cs)


func _physics_process(delta: float) -> void:
	flash -= delta
	var p = main.player
	var to: Vector2 = (p.position + Vector2(0, -14)) - (position + PIVOT)
	aim = Vector2.from_angle(roundf(to.angle() / (PI / 6)) * (PI / 6))
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and not p.dead:
		shoot_t = 1.5
		var b := Bullet.new()
		b.from_player = false
		b.vel = aim * 110.0
		b.position = position + PIVOT + aim * (GUN.get_width() - GUN_PIVOT.x)
		get_parent().add_child(b)
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
		main.explode(position + Vector2(0, -10), 18)
		queue_free()


func _draw() -> void:
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	draw_texture(BASE, Vector2(-BASE.get_width() / 2.0, -BASE.get_height()), tint)
	# el arma gira sobre su pivote; apuntando a la izquierda se voltea para que la culata no quede boca abajo
	draw_set_transform(PIVOT, aim.angle(), Vector2(1, -1 if aim.x < -0.01 else 1))
	draw_texture(GUN, -GUN_PIVOT, tint)
	draw_set_transform(Vector2.ZERO)
