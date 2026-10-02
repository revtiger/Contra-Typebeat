extends CharacterBody2D
## Tanque: avanza hacia el jugador y dispara obuses rasantes.
## El obús va a la altura del pecho: se esquiva saltando o tumbándose.

const Bullet = preload("res://scripts/bullet.gd")
const MAX_HP := 20

var hp := MAX_HP
var dir := -1
var shoot_t := 1.6
var flash := 0.0
var recoil := 0.0
var anim_t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, 20)
	cs.shape = r
	cs.position = Vector2(0, -10)
	add_child(cs)


func _physics_process(delta: float) -> void:
	flash -= delta
	recoil = maxf(recoil - delta * 20.0, 0.0)
	velocity.y += 900.0 * delta
	var p = main.player
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	var dx: float = p.position.x - position.x
	dir = 1 if dx > 0 else -1
	velocity.x = dir * 22.0 if on_screen and absf(dx) > 120.0 else 0.0
	if velocity.x != 0.0:
		anim_t += delta
	move_and_slide()
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and not p.dead:
		shoot_t = 2.3
		recoil = 3.0
		var b := Bullet.new()
		b.from_player = false
		b.kind = "shell"
		b.vel = Vector2(dir * 150.0, 0)
		b.position = position + Vector2(dir * 24, -15)
		get_parent().add_child(b)
		Game.sfx("cannon", -6.0)
		main.explode(position + Vector2(dir * 24, -15), 5.0, false)
	if position.x < main.cam_left - 80 or position.y > 320:
		queue_free()
	queue_redraw()


func take_damage(n: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= n
	flash = 0.06
	Game.sfx("hit", -16.0, 0.7)
	if hp <= 0:
		main.add_score(2000)
		main.blast(position + Vector2(0, -12), 36.0, false, 8)
		main.explode(position + Vector2(-10, -20), 20.0, false)
		main.explode(position + Vector2(12, -6), 16.0, false)
		queue_free()


func _draw() -> void:
	var hull := Color.WHITE if flash > 0.0 else Color(0.55, 0.5, 0.3)
	var d := float(dir)
	# orugas
	draw_rect(Rect2(-18, -7, 36, 7), Color(0.2, 0.2, 0.2))
	for i in 5:
		var x := -14.0 + i * 7.0 + fmod(anim_t * 20.0 * -d, 7.0)
		draw_circle(Vector2(clampf(x, -15, 15), -3.5), 2.5, Color(0.35, 0.35, 0.35))
	# casco y torreta
	draw_rect(Rect2(-17, -14, 34, 7), hull)
	draw_rect(Rect2(-8 - d * 2, -20, 14, 6), hull.darkened(0.15))
	var gx := d * (6.0 - recoil)
	draw_line(Vector2(gx, -17), Vector2(gx + d * 18, -16), Color(0.25, 0.25, 0.2), 3)
	draw_rect(Rect2(-17, -14, 34, 1), Color(1, 1, 1, 0.2))
	# vida
	if hp < MAX_HP:
		draw_rect(Rect2(-14, -26, 28, 2), Color(0.2, 0, 0))
		draw_rect(Rect2(-14, -26, 28.0 * hp / MAX_HP, 2), Color(1, 0.3, 0.2))
