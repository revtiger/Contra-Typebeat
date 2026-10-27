extends Area2D
## Mina terrestre: al pisarla pita y explota 0,4 s después (si sigues corriendo, te salvas). También se puede disparar.
## Sprite: tools/sprites/objetos.py (ChatGPT): luz apagada y encendida; parpadea despacio y, pisada, muy rápido.

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const TEX := preload("res://assets/sprites/mina.png")
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
	r.size = Vector2(20, 6)
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
	var fr := SpriteUtil.v(SpriteUtil.meta("res://assets/sprites/objetos_meta.json")["mina"]["frame"])
	var speed := 30.0 if fuse >= 0.0 else 4.0
	var f := 1 if int(t * speed) % 2 == 0 else 0
	# medio enterrada: los pies (centro del borde de abajo) 2 px por debajo del suelo
	draw_texture_rect_region(TEX, Rect2(-fr.x / 2.0, -fr.y + 2.0, fr.x, fr.y), Rect2(f * fr.x, 0, fr.x, fr.y))
