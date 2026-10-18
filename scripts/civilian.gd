extends Node2D
## Vecino del pueblo (fase 1.1). Vive en un edificio de scripts/pueblo_casas.gd (generado por
## tools/sprites/pueblo.py con la puerta y las ventanas de cada uno):
##   pasea por la vereda frente a su puerta (idle / walk);
##   cuando llega la pelea (el jugador a menos de PANIC_PLAYER px o una explosión cerca) vuelve deprisa a
##   su puerta (home), la abre y entra (enter);
##   después se asoma por una ventana de su casa (peek): sube la cabeza, mira a un lado y al otro y se
##   agacha cuando hay una explosión cerca.
## No recibe balas ni bloquea a nadie: es decorado vivo. Sprites: assets/sprites/vecinos.png
## (tools/sprites/vecinos.py), una fila por vecino: fotograma 0 quieto y 1..8 caminando (PixelLab).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const PuebloCasas = preload("res://scripts/pueblo_casas.gd")

const SHEET := preload("res://assets/sprites/vecinos.png")
const SHEET_PATH := "res://assets/sprites/vecinos.png"
const FW := 40
const FH := 52
const FEET := Vector2(20, 50)
const WALK_SPEED := 16.0
const HOME_SPEED := 55.0
const STROLL := 34.0         # cuánto se aleja de su puerta al pasear
const PANIC_PLAYER := 210.0
const PANIC_BLAST := 260.0
const HEAD_H := 15.0         # alto de la cabeza y los hombros que se ve en la ventana
const DOOR_DARK := Color(0.09, 0.05, 0.04)

## índice en PuebloCasas.CASAS
var house := 0
var kind := 0
var state := "idle"  # idle | walk | home | enter | inside | peek
var dir := 1.0
var timer := 0.0
var door := Rect2()
var windows: Array[Rect2] = []
var win := Rect2()
var door_open := 0.0         # 0..1, puerta abierta (rectángulo oscuro)
var peek := 0.0              # 0..1, cuánto asoma la cabeza
var peek_target := 0.0
var look := 1.0
var level
var body: AnimatedSprite2D


func _ready() -> void:
	add_to_group("civil")
	z_index = -3  # delante de las casas, detrás de soldados y balas
	level = get_tree().get_first_node_in_group("level")
	var h: Array = PuebloCasas.CASAS[house]
	var d: Array = h[1]
	door = Rect2(d[0], d[1], d[2] - d[0], d[3] - d[1])
	for w in h[2]:
		windows.append(Rect2(w[0], w[1], w[2] - w[0], w[3] - w[1]))
	kind = h[3]
	var anims := {
		"idle": [kind, 1, 1, false],
		"walk": [kind, 9, 9, true],
		"hurry": [kind, 9, 16, true],
	}
	body = SpriteUtil.sprite(SpriteUtil.frames(SHEET_PATH, FW, FH, anims), FEET)
	add_child(body)
	position.x = door.get_center().x + randf_range(-STROLL, STROLL)
	dir = -1.0 if randf() < 0.5 else 1.0
	timer = randf_range(0.3, 2.0)
	body.play("idle")


func _physics_process(delta: float) -> void:
	if state in ["idle", "walk"] and level and level.player and not level.player.dead:
		if absf(level.player.position.x - position.x) < PANIC_PLAYER:
			panic()
	var cx := door.get_center().x
	match state:
		"idle":
			timer -= delta
			if timer <= 0.0:
				state = "walk"
				var off := position.x - cx
				dir = -signf(off) if absf(off) > STROLL * 0.6 else (-1.0 if randf() < 0.5 else 1.0)
				timer = randf_range(1.2, 2.8)
				body.play("walk")
		"walk":
			position.x += dir * WALK_SPEED * delta
			timer -= delta
			if timer <= 0.0 or absf(position.x - cx) > STROLL:
				state = "idle"
				timer = randf_range(1.0, 3.0)
				body.play("idle")
		"home":
			dir = signf(cx - position.x)
			position.x = move_toward(position.x, cx, HOME_SPEED * delta)
			door_open = move_toward(door_open, 1.0, delta * 4.0)
			if absf(position.x - cx) < 0.5:
				state = "enter"
				timer = 0.35
				body.play("idle")
		"enter":
			# se mete por la puerta: se desvanece y la puerta se cierra
			timer -= delta
			body.modulate.a = clampf(timer / 0.35, 0.0, 1.0)
			if timer <= 0.0:
				body.visible = false
				state = "inside"
				timer = randf_range(0.6, 1.4)
		"inside":
			door_open = move_toward(door_open, 0.0, delta * 3.0)
			timer -= delta
			if timer <= 0.0 and not windows.is_empty():
				state = "peek"
				win = windows[randi() % windows.size()]
				peek_target = 1.0
				timer = randf_range(1.0, 2.0)
		"peek":
			door_open = move_toward(door_open, 0.0, delta * 3.0)
			peek = move_toward(peek, peek_target, delta * 2.5)
			timer -= delta
			if timer <= 0.0:
				if peek_target == 0.0:
					peek_target = 1.0  # vuelve a asomarse tras agacharse
					timer = randf_range(1.0, 2.0)
				else:
					look = -look  # mira hacia el otro lado
					timer = randf_range(0.9, 1.8)
	body.flip_h = dir < 0.0
	if level and position.x < level.cam_left - 300.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	if door_open > 0.0:
		var r := Rect2(door.position - position, door.size)
		var w := r.size.x * door_open
		draw_rect(Rect2(r.position.x + (r.size.x - w) / 2.0, r.position.y, w, r.size.y), DOOR_DARK)
	if state == "peek" and peek > 0.0:
		_draw_head()


## Cabeza y hombros del vecino (de su fotograma quieto) asomando por el borde de abajo de la ventana:
## se recorta a la ventana para que parezca que está detrás del vidrio.
func _draw_head() -> void:
	var w := Rect2(win.position - position, win.size)
	draw_rect(w, Color(0.12, 0.08, 0.06, 0.55))
	var cell := Rect2(0, kind * FH, FW, FH)
	var top_in_cell := 3.0  # las figuras empiezan cerca de y=3 en su celda
	var shown := HEAD_H * peek
	var dest_x := w.position.x + w.size.x / 2.0 - FW / 2.0
	var dest_y := w.end.y - shown
	# región de la hoja: desde lo alto de la cabeza, solo lo que cabe dentro de la ventana
	var src_h := minf(shown, w.end.y - maxf(dest_y, w.position.y))
	var src_y := top_in_cell + maxf(0.0, w.position.y - dest_y)
	var x0 := maxf(dest_x, w.position.x)
	var x1 := minf(dest_x + FW, w.end.x)
	if src_h <= 0.0 or x1 <= x0:
		return
	var sx := x0 - dest_x
	var src := Rect2(cell.position.x + sx, cell.position.y + src_y, x1 - x0, src_h)
	if look < 0.0:
		# mira al otro lado: espejo alrededor del centro de la ventana
		var c := w.position.x + w.size.x / 2.0
		draw_set_transform(Vector2(2.0 * c, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(SHEET, Rect2(x0, maxf(dest_y, w.position.y), x1 - x0, src_h), src)
	draw_set_transform(Vector2.ZERO)


## Vuelve a su casa.
func panic() -> void:
	if state in ["idle", "walk"]:
		state = "home"
		body.play("hurry")
		# un saltito de susto
		var tw := create_tween()
		tw.tween_property(body, "position:y", -5.0, 0.08)
		tw.tween_property(body, "position:y", 0.0, 0.1)
	elif state == "peek":
		# se agacha en la ventana
		peek_target = 0.0
		timer = randf_range(0.7, 1.2)


## Llamado por level.explode(): las explosiones cercanas los asustan (o los hacen agacharse).
static func scare_all(tree: SceneTree, pos: Vector2) -> void:
	for c in tree.get_nodes_in_group("civil"):
		if c.global_position.distance_to(pos) < PANIC_BLAST:
			c.panic()
