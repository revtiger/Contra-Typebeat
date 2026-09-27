extends StaticBody2D
## Torreta fija que gira hacia el jugador y dispara. Aguanta varios impactos.

const Bullet = preload("res://scripts/bullet.gd")

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
	r.size = Vector2(20, 18)
	cs.shape = r
	cs.position = Vector2(0, -9)
	add_child(cs)


func _physics_process(delta: float) -> void:
	flash -= delta
	var p = main.player
	var to: Vector2 = (p.position + Vector2(0, -14)) - (position + Vector2(0, -12))
	aim = Vector2.from_angle(roundf(to.angle() / (PI / 6)) * (PI / 6))
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and not p.dead:
		shoot_t = 1.5
		var b := Bullet.new()
		b.from_player = false
		b.vel = aim * 110.0
		b.position = position + Vector2(0, -12) + aim * 12
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
	var white := flash > 0.0
	draw_rect(Rect2(-10, -8, 20, 8), Color.WHITE if white else Color(0.35, 0.35, 0.4))
	draw_circle(Vector2(0, -12), 7, Color.WHITE if white else Color(0.5, 0.5, 0.55))
	draw_line(Vector2(0, -12), Vector2(0, -12) + aim * 12, Color(0.15, 0.15, 0.15), 3)
	draw_circle(Vector2(0, -12), 2.5, Color(1, 0.2, 0.2))
