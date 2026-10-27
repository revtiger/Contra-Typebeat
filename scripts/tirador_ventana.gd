extends Area2D
## Emboscada de azotea: un soldado se asoma por una ventana (Edificios.ventanas) cuando el héroe está en altura.
## aviso (la ventana se ilumina y sale un "!", AVISO_T s) -> asomado (dispara una ráfaga corta al héroe) ->
## se esconde y desaparece. Solo se le puede dar mientras está asomado (EnemyHurtbox); de un tiro muere.
## Lo crea level.gd (_emboscada). Arte provisional: en greybox se ve como una caja.

const Bullet = preload("res://scripts/bullet.gd")
const AVISO_T := 0.6
const RAFAGA := 3
const ENTRE_TIROS := 0.18
const BALA_V := 180.0
const SIZE := Vector2(14, 20)

var ventana := Rect2()
var state := "aviso"  # aviso | asomado | escondido
var state_t := AVISO_T
var tiros := RAFAGA
var tiro_t := 0.25  # primer tiro un instante después de asomarse
var main
var cs := CollisionShape2D.new()


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 0  # escondido: no se le puede dar hasta que se asoma
	collision_mask = 0
	monitoring = false
	position = ventana.get_center() + Vector2(0, ventana.size.y / 2.0 - SIZE.y / 2.0)
	var r := RectangleShape2D.new()
	r.size = SIZE
	cs.shape = r
	add_child(cs)
	z_index = 1
	Game.sfx("beep", -10.0, 1.6)


func _physics_process(delta: float) -> void:
	state_t -= delta
	match state:
		"aviso":
			if state_t <= 0.0:
				state = "asomado"
				collision_layer = 4  # EnemyHurtbox
		"asomado":
			tiro_t -= delta
			if tiro_t <= 0.0 and tiros > 0:
				tiros -= 1
				tiro_t = ENTRE_TIROS
				_disparar()
			elif tiros == 0 and tiro_t <= -0.3:
				state = "escondido"
				state_t = 0.25
				collision_layer = 0
		"escondido":
			if state_t <= 0.0:
				queue_free()
	queue_redraw()


func _disparar() -> void:
	var p = main.player
	if p.dead:
		return
	var b := Bullet.new()
	b.from_player = false
	b.vel = ((p.position + Vector2(0, -20)) - position).normalized() * BALA_V
	b.position = position
	main.add_child(b)
	Game.sfx("shot", -18.0, 0.8)


func take_damage(_n: int) -> void:
	if state != "asomado":
		return
	main.add_score(300)
	Game.sfx("death", -14.0, 2.0)
	Juice.hitstop(0.03)
	queue_free()


## Arte provisional (modo arte): ventana iluminada en el aviso y una silueta asomada.
func _draw() -> void:
	var v := Rect2(ventana.position - position, ventana.size)
	if state == "aviso":
		draw_rect(v, Color(1, 0.85, 0.3, 0.6 if int(state_t * 12.0) % 2 == 0 else 0.3))
		draw_rect(Rect2(-1, -SIZE.y / 2.0 - 12, 2, 6), Color(1, 0.2, 0.15))
		draw_rect(Rect2(-1, -SIZE.y / 2.0 - 4, 2, 2), Color(1, 0.2, 0.15))
	elif state == "asomado":
		draw_rect(Rect2(-SIZE / 2.0, SIZE), Color(0.25, 0.3, 0.22))
