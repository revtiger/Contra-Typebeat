extends Area2D
const PixelFont = preload("res://scripts/pixel_font.gd")
## "capsule": cápsula voladora que cruza la pantalla; al dispararle suelta el arma.
## "item": el arma que cae al suelo y se recoge al tocarla.

var mode := "capsule"
var weapon := "S"
var main
var t := 0.0
var base_y := 60.0
var vel := Vector2.ZERO
## Segundos que el arma se queda en el suelo antes de desaparecer (parpadea los últimos 3).
var item_life := 9.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	base_y = position.y
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 10)
	cs.shape = r
	add_child(cs)
	z_index = 4
	if mode == "capsule":
		collision_layer = 4
		collision_mask = 0
	else:
		collision_layer = 0
		collision_mask = 2
		body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	t += delta
	if mode == "capsule":
		position.x += 75.0 * delta
		position.y = base_y + sin(t * 3.0) * 20.0
		if position.x > main.cam_left + 520:
			queue_free()
	else:
		item_life -= delta
		if item_life <= 0.0:
			queue_free()
			return
		vel.y += 500.0 * delta
		position += vel * delta
		var gy: float = main.ground_y_at(position.x) - 6
		if position.y >= gy and position.y - vel.y * delta <= gy + 1:
			position.y = gy
			vel = Vector2.ZERO
		if position.y > 320 or position.x < main.cam_left - 40:
			queue_free()
	queue_redraw()


func take_damage(_n: int) -> void:
	if mode != "capsule" or is_queued_for_deletion():
		return
	main.explode(position, 12)
	var item = get_script().new()
	item.mode = "item"
	item.weapon = weapon
	item.vel = Vector2(40, -180)
	item.position = position
	get_parent().add_child.call_deferred(item)
	queue_free()


func _on_body(b: Node) -> void:
	if b.is_in_group("player") and not b.dead:
		if weapon == "B":
			b.add_bombs(10)
		else:
			b.set_weapon(weapon)
		main.add_score(1000)
		queue_free()


func _draw() -> void:
	if mode == "capsule":
		draw_rect(Rect2(-8, -5, 16, 10), Color(0.75, 0.75, 0.8))
		draw_rect(Rect2(-8, -5, 16, 10), Color(0.3, 0.3, 0.35), false, 1)
		var wing := sin(t * 20.0) * 4.0
		draw_line(Vector2(-4, -5), Vector2(-10, -8 - wing), Color(0.9, 0.9, 0.95), 2)
		draw_line(Vector2(4, -5), Vector2(10, -8 - wing), Color(0.9, 0.9, 0.95), 2)
	else:
		if item_life < 3.0 and int(t * (8.0 if item_life > 1.0 else 16.0)) % 2 == 0:
			return
		draw_circle(Vector2.ZERO, 7, Color(0.9, 0.15, 0.15))
		draw_line(Vector2(-12, -2), Vector2(-5, 0), Color(0.9, 0.8, 0.2), 3)
		draw_line(Vector2(12, -2), Vector2(5, 0), Color(0.9, 0.8, 0.2), 3)
		draw_string(PixelFont.font("small"), Vector2(-3, 5), weapon, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size("small"))
