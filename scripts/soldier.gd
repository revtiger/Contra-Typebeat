extends CharacterBody2D
## Soldado enemigo. "run": corre en línea recta y salta escalones. "sniper": se queda quieto y dispara al jugador.

const Bullet = preload("res://scripts/bullet.gd")

var mode := "run"
var dir := -1
var speed := 70.0
var hp := 1
var shoot_t := 1.2
var anim_t := 0.0
var main
var aim := Vector2.LEFT


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1 | 8
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 24)
	cs.shape = r
	cs.position = Vector2(0, -12)
	add_child(cs)
	if mode == "sniper":
		hp = 2
		shoot_t = randf_range(0.6, 1.6)


func _physics_process(delta: float) -> void:
	anim_t += delta
	velocity.y += 900.0 * delta
	var p = main.player
	if mode == "run":
		velocity.x = dir * speed
	else:
		velocity.x = 0.0
		var to: Vector2 = (p.position + Vector2(0, -14)) - (position + Vector2(0, -17))
		dir = 1 if to.x > 0 else -1
		aim = Vector2.from_angle(roundf(to.angle() / (PI / 4)) * (PI / 4))
		var on_screen: bool = position.x > main.cam_left and position.x < main.cam_left + 480
		shoot_t -= delta
		if shoot_t <= 0.0 and on_screen and not p.dead:
			shoot_t = randf_range(1.3, 2.2)
			var b := Bullet.new()
			b.from_player = false
			b.vel = aim * 120.0
			b.position = position + Vector2(0, -17) + aim * 10
			get_parent().add_child(b)
			Game.sfx("shot", -20.0, 0.7)
	move_and_slide()
	if mode == "run" and is_on_wall() and is_on_floor():
		velocity.y = -300.0
	if position.y > 320 or position.x < main.cam_left - 60 or position.x > main.cam_left + 560:
		queue_free()
	queue_redraw()


func take_damage(n: int) -> void:
	hp -= n
	if hp <= 0 and not is_queued_for_deletion():
		main.add_score(200 if mode == "sniper" else 100)
		main.explode(position + Vector2(0, -12), 10)
		Game.sfx("death", -18.0, 1.8)
		queue_free()


const UNIFORM := Color(0.45, 0.5, 0.35)
const HELMET := Color(0.3, 0.35, 0.25)
const SKIN := Color(0.85, 0.65, 0.5)


func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	if dir < 0:
		x = -x - w
	draw_rect(Rect2(x, y, w, h), c)


func _draw() -> void:
	var desert: bool = main.theme == "desert"
	var uniform := Color(0.78, 0.66, 0.45) if desert else UNIFORM
	var helmet := Color(0.6, 0.2, 0.15) if desert else HELMET
	var ph := sin(anim_t * 16.0) * 3.0 if mode == "run" and is_on_floor() else 0.0
	_r(-4 + ph, -10, 4, 10, uniform.darkened(0.3))
	_r(0 - ph, -10, 4, 10, uniform.darkened(0.3))
	_r(-4, -20, 8, 11, uniform)
	_r(-3, -25, 7, 5, SKIN)
	_r(-4, -27, 9, 3, helmet)
	if desert:
		_r(-6, -26, 3, 5, helmet)
	if mode == "sniper":
		var sh := Vector2(0, -17)
		draw_line(sh, sh + aim * 11, Color(0.2, 0.2, 0.2), 2)
	else:
		_r(3, -17, 5, 2, Color(0.2, 0.2, 0.2))
