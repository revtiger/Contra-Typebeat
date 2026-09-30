extends Area2D
## Proyectiles de Sergio Massa (massa.gd). Hacen daño al jugador al tocarlo.
##   bubble:  "promesa", bocadillo lento que ondula hacia el jugador; se revienta de un tiro
##   bundle:  fajo de billetes lanzado en arco; al tocar el suelo se abre en billetes (flutter)
##   flutter: billete que salta y cae revoloteando
##   bill:    billete disparado por La Maquinita, recto y rápido

const PixelFont = preload("res://scripts/pixel_font.gd")
const PROMISES := ["$$$", "¡PLATA!", "PROMETO", "IVA 0"]

var kind := "bubble"
var vel := Vector2.ZERO
var target_y := 200.0
var harmless := false
var main
var t := 0.0
var life := 5.0
var text := ""
var spin := 0.0
var bundle_tex: Texture2D


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = 5
	collision_layer = 0
	collision_mask = 0 if harmless else 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = {"bubble": 8.0, "bundle": 7.0, "flutter": 3.0, "bill": 3.0}[kind]
	cs.shape = c
	add_child(cs)
	match kind:
		"bubble":
			text = PROMISES[randi() % PROMISES.size()]
			# se puede reventar a tiros: está en la capa de enemigos
			add_to_group("enemy")
			collision_layer = 4
			life = 6.0
		"bundle":
			bundle_tex = load("res://assets/sprites/boss_massa_bundle.png")
			spin = randf_range(6.0, 9.0) * signf(vel.x)
		"flutter":
			life = 3.0
			spin = randf_range(-6.0, 6.0)
		"bill":
			life = 3.0
			spin = 14.0 * signf(vel.x)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	match kind:
		"bubble":
			# se acerca a la altura del jugador ondulando
			position.x += vel.x * delta
			position.y = lerpf(position.y, target_y, 1.5 * delta) + sin(t * 5.0) * 0.6
		"bundle":
			vel.y += 420.0 * delta
			position += vel * delta
			rotation += spin * delta
			var gy: float = main.ground_y_at(position.x)
			if gy < 900.0 and position.y >= gy - 4.0 and vel.y > 0.0:
				_burst()
			elif position.y > 300.0:
				queue_free()
		"flutter":
			vel.y = minf(vel.y + 260.0 * delta, 45.0)
			vel.x = lerpf(vel.x, sin(t * 6.0) * 30.0, 2.0 * delta)
			position += vel * delta
			rotation = sin(t * 8.0) * 0.6
			var gy: float = main.ground_y_at(position.x)
			if gy < 900.0 and position.y >= gy - 2.0:
				queue_free()
		"bill":
			position += vel * delta
			rotation += spin * delta


## El fajo se abre en billetes que saltan y caen revoloteando.
func _burst() -> void:
	main.explode(position + Vector2(0, -4), 8.0, false)
	Game.sfx("small_boom", -10.0, 1.4)
	for i in 5:
		var s = get_script().new()
		s.kind = "flutter"
		s.position = position + Vector2(0, -6)
		s.vel = Vector2(randf_range(-70, 70), randf_range(-200, -120))
		# diferido: puede llamarse desde una señal de colisión, cuando Godot no deja crear áreas
		main.add_child.call_deferred(s)
	queue_free()


func _on_hit(other: Node) -> void:
	if harmless or is_queued_for_deletion():
		return
	if other.is_in_group("player"):
		other.hit()
		if kind == "bundle":
			_burst()
		else:
			queue_free()


## La promesa se revienta de un tiro.
func take_damage(_n: int) -> void:
	if kind != "bubble" or is_queued_for_deletion():
		return
	main.add_score(100)
	main.explode(position, 6.0, false)
	Game.sfx("small_boom", -12.0, 1.8)
	queue_free()


func _draw() -> void:
	match kind:
		"bubble":
			var font := PixelFont.font("small")
			var fs := PixelFont.size("small")
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0
			var r := Rect2(-w / 2.0, -7, w, 13)
			draw_rect(r.grow(1), Color.BLACK)
			draw_rect(r, Color(1, 1, 1))
			# colita del bocadillo hacia quien habla
			var tail := 1.0 if vel.x < 0.0 else -1.0
			draw_colored_polygon(PackedVector2Array([Vector2(tail * w * 0.3, 5), Vector2(tail * (w * 0.3 + 6), 10), Vector2(tail * w * 0.15, 5)]), Color.WHITE)
			draw_string(font, Vector2(-w / 2.0 + 4, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.35, 0.75))
		"bundle":
			if bundle_tex:
				draw_texture(bundle_tex, -bundle_tex.get_size() / 2.0)
		"flutter", "bill":
			var col := Color(0.55, 0.78, 0.95) if kind == "bill" else Color(0.95, 0.7, 0.8)
			draw_rect(Rect2(-5, -2.5, 10, 5), Color(0.1, 0.15, 0.1))
			draw_rect(Rect2(-4, -1.5, 8, 3), col)
			draw_rect(Rect2(-1, -1, 2, 2), col.darkened(0.4))
