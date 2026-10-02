extends Area2D
## Mina terrestre: al pisarla pita y explota 0,4 s después (si sigues corriendo, te salvas). También se puede disparar.

const FUSE := 0.4

var main
var t := 0.0
var fuse := -1.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("prop")
	collision_layer = 16
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 6)
	cs.shape = r
	cs.position = Vector2(0, -3)
	add_child(cs)
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	if fuse < 0.0 and b.is_in_group("player"):
		fuse = FUSE
		Game.sfx("beep", -4.0)


func _physics_process(delta: float) -> void:
	t += delta
	if fuse >= 0.0:
		fuse -= delta
		if fuse < 0.0:
			_explode()
			return
	if position.x < main.cam_left - 60:
		queue_free()
	queue_redraw()


func take_damage(_n: int) -> void:
	_explode()


func _explode() -> void:
	if is_queued_for_deletion():
		return
	main.add_score(100)
	main.blast(position + Vector2(0, -4), 30.0, true)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2(0, 0), 6, Color(0.3, 0.3, 0.28))
	draw_rect(Rect2(-7, -1, 14, 1), Color(0.2, 0.2, 0.18))
	var speed := 30.0 if fuse >= 0.0 else 4.0
	if int(t * speed) % 2 == 0:
		draw_circle(Vector2(0, -4), 1.5, Color(1, 0.1, 0.1))
