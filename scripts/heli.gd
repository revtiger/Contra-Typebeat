extends StaticBody2D
## Jefe helicóptero de ataque (era el de Bolivia; ahora sin usar, se puede reaprovechar). Entra por la derecha cuando la cámara se bloquea
## y alterna ráfagas apuntadas, bombas (con aviso en el suelo) y un abanico de balas a media vida.

const Bullet = preload("res://scripts/bullet.gd")
const Bomb = preload("res://scripts/bomb.gd")
const MAX_HP := 110

var hp := MAX_HP
var state := "wait"  # wait | enter | fight | dying
var t := 0.0
var attack_t := 1.5
var pattern := 0
var burst_left := 0
var burst_t := 0.0
var flash := 0.0
var fall_v := 0.0
var boom_t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(62, 24)
	cs.shape = r
	cs.position = Vector2(6, 0)
	add_child(cs)
	position = Vector2(main.boss_arena + 560, 60)


func _physics_process(delta: float) -> void:
	t += delta
	flash -= delta
	var arena: float = main.boss_arena
	match state:
		"wait":
			if main.cam_left >= arena - 1.0:
				state = "enter"
				Game.sfx("jet", 0.0, 0.6)
		"enter":
			position = position.lerp(Vector2(arena + 330, 70), 1.5 * delta)
			if position.x < arena + 340:
				state = "fight"
		"fight":
			var target := Vector2(arena + 250 + sin(t * 0.55) * 170, 72 + sin(t * 1.7) * 12)
			position = position.lerp(target, 2.0 * delta)
			_attack(delta)
		"dying":
			fall_v += 160.0 * delta
			position += Vector2(-35, fall_v) * delta
			rotation += 1.8 * delta
			boom_t -= delta
			if boom_t <= 0.0:
				boom_t = 0.12
				main.explode(position + Vector2(randf_range(-28, 28), randf_range(-12, 12)), randf_range(10, 20))
			if position.y >= 212.0:
				main.blast(position, 50.0, false, 10)
				main.explode(position + Vector2(-20, 0), 30.0)
				main.explode(position + Vector2(20, -10), 26.0)
				main.stage_clear()
				queue_free()
	queue_redraw()


func _attack(delta: float) -> void:
	var p = main.player
	if p.dead:
		return
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_t = 0.13
			burst_left -= 1
			var from := position + Vector2(-26, 6)
			_shoot(from, (p.position + Vector2(0, -12) - from).normalized() * 125.0)
		return
	attack_t -= delta
	if attack_t > 0.0:
		return
	attack_t = lerpf(1.0, 2.0, float(hp) / MAX_HP)
	var n_patterns := 3 if hp < MAX_HP / 2 else 2
	pattern = (pattern + 1) % n_patterns
	match pattern:
		0:
			burst_left = 5
			burst_t = 0.0
		1:
			for o in [-45.0, 0.0, 45.0]:
				var b := Bomb.new()
				b.target_x = p.position.x + o
				b.position = Vector2(p.position.x + o, position.y + 10)
				get_parent().add_child(b)
		2:
			for i in 9:
				var a := PI * 0.5 + (i - 4) * 0.22
				_shoot(position + Vector2(0, 12), Vector2.from_angle(a) * 100.0)


func _shoot(from: Vector2, v: Vector2) -> void:
	var b := Bullet.new()
	b.from_player = false
	b.life = 4.0
	b.vel = v
	b.position = from
	get_parent().add_child(b)
	Game.sfx("shot", -18.0, 0.6)


func take_damage(n: int) -> void:
	if state != "fight":
		return
	hp -= n
	flash = 0.05
	if hp <= 0:
		state = "dying"
		main.add_score(15000)
		Game.sfx("boom", 0.0, 0.7)
		main.shake(6.0)


func _draw() -> void:
	var body := Color(0.52, 0.48, 0.3)
	if flash > 0.0:
		body = Color.WHITE
	# cola y rotor de cola
	draw_rect(Rect2(10, -6, 34, 6), body.darkened(0.15))
	draw_rect(Rect2(40, -14, 5, 10), body.darkened(0.15))
	var tr := sin(t * 50.0) * 7.0
	draw_line(Vector2(44, -8 - tr), Vector2(44, -8 + tr), Color(0.2, 0.2, 0.2, 0.8), 2)
	# fuselaje
	draw_circle(Vector2(-6, 0), 13, body)
	draw_rect(Rect2(-6, -13, 22, 24), body)
	draw_circle(Vector2(-16, -2), 7, Color(0.3, 0.6, 0.8))
	draw_circle(Vector2(-18, -4), 2, Color(0.8, 0.95, 1))
	# armas laterales y patines
	draw_rect(Rect2(-12, 6, 20, 4), Color(0.25, 0.25, 0.22))
	draw_line(Vector2(-26, 6), Vector2(-12, 8), Color(0.2, 0.2, 0.2), 2)
	draw_line(Vector2(-18, 16), Vector2(16, 16), Color(0.2, 0.2, 0.2), 2)
	draw_line(Vector2(-10, 11), Vector2(-10, 16), Color(0.2, 0.2, 0.2), 1)
	draw_line(Vector2(8, 11), Vector2(8, 16), Color(0.2, 0.2, 0.2), 1)
	# rotor principal
	draw_rect(Rect2(-2, -17, 4, 4), Color(0.2, 0.2, 0.2))
	var w := absf(cos(t * 40.0)) * 44.0 + 6.0
	draw_line(Vector2(-w, -17), Vector2(w, -17), Color(0.15, 0.15, 0.15, 0.85), 2)
	# humo cuando está dañado
	if hp < MAX_HP / 2:
		for i in 3:
			var k := fmod(t * 1.5 + i * 0.33, 1.0)
			draw_circle(Vector2(20 + k * 20, -10 - k * 18), 3 + k * 5, Color(0.2, 0.2, 0.2, 0.5 * (1.0 - k)))
	# barra de vida
	if state == "fight":
		draw_set_transform(Vector2.ZERO, -rotation)
		draw_rect(Rect2(-30, -30, 70, 4), Color(0.2, 0, 0))
		draw_rect(Rect2(-30, -30, 70.0 * hp / MAX_HP, 4), Color(1, 0.25, 0.2))
