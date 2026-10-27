extends StaticBody2D
## Barril explosivo: al dispararle estalla y daña todo lo cercano (también a otros barriles: reacción en cadena).
## Con el primer impacto queda abollado y echa humo. Sprite: tools/sprites/objetos.py (ChatGPT): entero y dañado.

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const TEX := preload("res://assets/sprites/barril.png")

var hp := 2
var flash := 0.0
var t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("prop")
	collision_layer = 16
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 22)
	cs.shape = r
	cs.position = Vector2(0, -11)
	add_child(cs)


func _physics_process(delta: float) -> void:
	t += delta
	flash -= delta
	# dañado: el humo se mueve
	if hp < 2 or flash > -0.1:
		queue_redraw()
	if position.x < main.cam_left - 60:
		queue_free()


func take_damage(n: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= n
	flash = 0.06
	queue_redraw()
	if hp <= 0:
		main.add_score(50)
		main.blast(position + Vector2(0, -11), 38.0, true, 6)
		queue_free()


func _draw() -> void:
	var fr := SpriteUtil.v(SpriteUtil.meta("res://assets/sprites/objetos_meta.json")["barril"]["frame"])
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	var f := 1 if hp < 2 else 0
	draw_texture_rect_region(TEX, Rect2(-fr.x / 2.0, -fr.y, fr.x, fr.y), Rect2(f * fr.x, 0, fr.x, fr.y), tint)
	if hp < 2:
		# humo que sale de los agujeros de arriba
		for i in 4:
			var k := fmod(t * 0.9 + i * 0.25, 1.0)
			var c := Vector2(2.0 + sin(t * 2.0 + i) * 2.0 + k * 5.0, -fr.y - k * 22.0)
			draw_circle(c.round(), 2.0 + k * 4.0, Color(0.22, 0.2, 0.19, 0.6 * (1.0 - k)))
