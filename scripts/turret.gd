extends StaticBody2D
## Nido de ametralladora: un soldado agachado tras un muro de sacos terreros maneja una ametralladora montada.
## Solo dispara hacia la izquierda (no puede voltearse): al frente o en diagonal hacia arriba, según dónde esté el
## jugador. Si el jugador ya le pasó por detrás, deja de disparar. Aguanta varios impactos.
## - Los sacos se van rompiendo con los golpes (intacto → dañado → destrozado) y sueltan arena.
## - Tocar los sacos no hace daño (touch_damage = false): el héroe puede acercarse y matar al soldado con el
##   cuchillo (knifeable, con alcance extra porque el soldado está detrás de los sacos).
## - Al morir el soldado (cuchillo o vida a 0) sale despedido y el nido queda vacío y roto en la calle.
## Sprites: tools/sprites/turret.py (turret_soldado.png: fila por estado, columna por dirección; dibujo de Eduardo
## con ChatGPT y el deterioro con PixelLab).

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Polvo = preload("res://scripts/polvo.gd")
const SHEET := preload("res://assets/sprites/turret_soldado.png")
const MAX_HP := 8
## dirección de cada fotograma
const AIMS := [Vector2(-1, 0), Vector2(-0.7071, -0.7071)]
## dónde está el soldado (respecto a los pies del nido), para que salga despedido de ahí
const GUNNER := Vector2(20, 0)

var hp := MAX_HP
var shoot_t := 1.0
var flash := 0.0
var muzzle_flash := 0.0
var recoil := 0.0
var dir := 0
var meta: Dictionary
var main
var knifeable := true
var knife_reach := 20.0
var touch_damage := false
var empty := false  # el soldado ya murió: solo quedan los sacos rotos


func _ready() -> void:
	main = get_tree().get_first_node_in_group("main")
	meta = SpriteUtil.meta("res://assets/sprites/turret_soldado_meta.json")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 0
	# los sacos y el soldado que asoma por encima
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(60, 46)
	cs.shape = r
	cs.position = Vector2(2, -23)
	add_child(cs)


## Punto del fotograma (px de la hoja) en coordenadas locales: los pies (centro del borde de abajo del búnker)
## están en el origen.
func _local(p: Array) -> Vector2:
	return Vector2(p[0], p[1]) - SpriteUtil.v(meta["feet"])


func _physics_process(delta: float) -> void:
	flash -= delta
	muzzle_flash -= delta
	recoil = move_toward(recoil, 0.0, delta * 20.0)
	if position.x < main.cam_left - 60:
		queue_free()
	if empty:
		if flash > -0.1:
			queue_redraw()  # se apaga el destello del último golpe
		return
	var p = main.player
	var to: Vector2 = (p.position + Vector2(0, -14)) - (position + _local(meta["muzzles"][0]))
	var ahead: bool = to.x < -8.0  # el jugador está delante (a la izquierda)
	if ahead:
		# en diagonal si está claramente por encima; si no, al frente
		dir = 1 if to.y / -to.x < -0.45 else 0
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and ahead and not p.dead:
		shoot_t = 1.5
		var b := Bullet.new()
		b.from_player = false
		b.vel = AIMS[dir] * 110.0
		b.position = position + _local(meta["muzzles"][dir])
		get_parent().add_child(b)
		muzzle_flash = 0.07
		recoil = 1.5
		Game.sfx("shot", -18.0, 0.55)
	queue_redraw()


func take_damage(n: int) -> void:
	if empty:
		return
	var before := _state()
	hp -= n
	flash = 0.06
	Game.sfx("hit", -18.0)
	# arena que salta de los sacos
	Polvo.levantar(get_parent(), position + Vector2(randf_range(-24, 14), randf_range(-26, -6)), 3)
	if _state() != before:
		# se rompe otro trozo del muro
		Polvo.levantar(get_parent(), position + Vector2(-6, -12), 10)
		Game.sfx("small_boom", -14.0, 1.4)
	if hp <= 0:
		main.explode(position + Vector2(0, -18), 20)
		_kill_gunner()


## El cuchillo mata al soldado del nido de una (no rompe más los sacos).
func knifed() -> void:
	if not empty:
		_kill_gunner()


func _kill_gunner() -> void:
	if empty:
		return
	empty = true
	knifeable = false
	main.add_score(500)
	remove_from_group("enemy")
	collision_layer = 0
	# el soldado sale despedido hacia atrás y cae (con la muerte del soldado de Argentina)
	var s := Soldier.new()
	s.mode = "sniper"
	s.dir = -1
	s.position = position + GUNNER
	get_parent().add_child.call_deferred(s)
	s.call_deferred("take_damage", 99)
	queue_redraw()


## 0 intacto, 1 dañado, 2 destrozado (según la vida que le queda)
func _state() -> int:
	if hp > MAX_HP * 0.6:
		return 0
	return 1 if hp > MAX_HP * 0.3 else 2


func _draw() -> void:
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	var fr: Array = meta["frame"]
	var size := Vector2(fr[0], fr[1])
	var at := -SpriteUtil.v(meta["feet"])
	# culatazo: todo el nido tiembla un píxel hacia atrás (a la derecha) al disparar
	at.x += roundf(recoil)
	var rows: Dictionary = meta.get("rows", {})
	var src := Rect2(dir * fr[0], 0, fr[0], fr[1])
	if empty and rows.has("vacio"):
		src = Rect2(0, rows["vacio"] * fr[1], fr[0], fr[1])
	elif rows.has("danado"):
		var row: int = [0, rows["danado"], rows["destrozado"]][_state()]
		src = Rect2(dir * fr[0], row * fr[1], fr[0], fr[1])
	draw_texture_rect_region(SHEET, Rect2(at, size), src, tint)
	if muzzle_flash > 0.0 and not empty:
		var m: Vector2 = _local(meta["muzzles"][dir]) + AIMS[dir] * 2.0
		draw_circle(m, 3.5, Color(1, 0.85, 0.3))
		draw_circle(m, 2.0, Color(1, 1, 0.85))
