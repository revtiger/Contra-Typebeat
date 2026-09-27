extends StaticBody2D
## Jefe final: muro defensivo con dos cañones y una puerta de la que salen soldados.
## Origen en la esquina inferior izquierda del muro.

const Bullet = preload("res://scripts/bullet.gd")
const Soldier = preload("res://scripts/soldier.gd")

const WIDTH := 100.0
const HEIGHT := 170.0
const MAX_HP := 70
const CANNONS := [Vector2(4, -130), Vector2(4, -75)]
const CORE := Vector2(40, -105)

var hp := MAX_HP
var shoot_t := 2.0
var spawn_t := 3.0
var flash := 0.0
var dying := false
var die_t := 0.0
var anim_t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(WIDTH, HEIGHT)
	cs.shape = r
	cs.position = Vector2(WIDTH / 2, -HEIGHT / 2)
	add_child(cs)


func _active() -> bool:
	return main.cam_left >= main.BOSS_ARENA - 1.0


func _physics_process(delta: float) -> void:
	anim_t += delta
	flash -= delta
	if dying:
		die_t -= delta
		if int(die_t * 10) != int((die_t + delta) * 10):
			main.explode(position + Vector2(randf() * WIDTH, -randf() * HEIGHT), randf_range(12, 26))
		if die_t <= 0.0:
			main.stage_clear()
			queue_free()
		queue_redraw()
		return
	if not _active() or main.player.dead:
		queue_redraw()
		return
	shoot_t -= delta
	if shoot_t <= 0.0:
		shoot_t = lerpf(0.8, 1.8, float(hp) / MAX_HP)
		for c in CANNONS:
			var from: Vector2 = position + c
			var d: Vector2 = (main.player.position + Vector2(0, -12) - from).normalized()
			for a in [-0.22, 0.0, 0.22]:
				var b := Bullet.new()
				b.from_player = false
				b.life = 4.0
				b.vel = d.rotated(a) * 110.0
				b.position = from
				get_parent().add_child(b)
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = 3.5
		var s := Soldier.new()
		s.dir = -1
		s.position = position + Vector2(-8, 0)
		get_parent().add_child(s)
	queue_redraw()


func take_damage(n: int) -> void:
	if dying or not _active():
		return
	hp -= n
	flash = 0.05
	if hp <= 0:
		dying = true
		die_t = 2.5
		main.add_score(10000)


func _draw() -> void:
	var metal := Color(0.4, 0.42, 0.48)
	if flash > 0.0:
		metal = metal.lightened(0.5)
	draw_rect(Rect2(0, -HEIGHT, WIDTH, HEIGHT), metal)
	draw_rect(Rect2(0, -HEIGHT, WIDTH, HEIGHT), Color(0.2, 0.2, 0.25), false, 2)
	for y in range(-int(HEIGHT) + 10, 0, 20):
		for x in range(8, int(WIDTH), 20):
			draw_circle(Vector2(x, y), 1.5, Color(0.25, 0.25, 0.3))
	# puerta
	draw_rect(Rect2(0, -34, 22, 34), Color(0.12, 0.12, 0.15))
	# núcleo
	var pulse := 0.5 + 0.5 * sin(anim_t * 6.0)
	draw_circle(CORE, 14, Color(0.15, 0.15, 0.2))
	draw_circle(CORE, 10, Color(1, 0.2 + 0.3 * pulse, 0.2))
	for c in CANNONS:
		draw_rect(Rect2(c.x - 14, c.y - 5, 18, 10), Color(0.2, 0.2, 0.22))
		draw_circle(c + Vector2(-14, 0), 4, Color(0.1, 0.1, 0.1))
	# barra de vida
	if _active() and not dying:
		draw_rect(Rect2(0, -HEIGHT - 10, WIDTH, 5), Color(0.2, 0, 0))
		draw_rect(Rect2(0, -HEIGHT - 10, WIDTH * hp / MAX_HP, 5), Color(1, 0.2, 0.2))
