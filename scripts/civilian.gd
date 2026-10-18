extends Node2D
## Vecino del pueblo (fase 1.1): pasea por la vereda y, cuando se acerca la pelea (el jugador a menos de
## PANIC_PLAYER px o una explosión a menos de PANIC_BLAST px), sale corriendo hacia el lado contrario y
## desaparece al salir de pantalla. No recibe balas ni bloquea a nadie: es decorado vivo.
## Sprites: assets/sprites/vecinos.png (tools/sprites/vecinos.py), una fila por vecino:
## fotograma 0 quieto y 1..8 caminando (PixelLab).

const SpriteUtil = preload("res://scripts/sprite_util.gd")

const SHEET := "res://assets/sprites/vecinos.png"
const FW := 40
const FH := 52
const KINDS := 12
const WALK_SPEED := 18.0
const RUN_SPEED := 95.0
const PANIC_PLAYER := 170.0
const PANIC_BLAST := 260.0

## fila de vecinos.png (0..11); -1 = al azar
var kind := -1
var state := "idle"  # idle | walk | run
var dir := 1.0
var home := 0.0
var timer := 0.0
var level
var body: AnimatedSprite2D


func _ready() -> void:
	add_to_group("civil")
	z_index = -2  # delante de las casas, detrás de soldados y balas
	level = get_tree().get_first_node_in_group("level")
	if kind < 0:
		kind = randi() % KINDS
	var anims := {
		"idle": [kind, 1, 1, false],
		"walk": [kind, 9, 9, true],
		"run": [kind, 9, 18, true],
	}
	body = SpriteUtil.sprite(SpriteUtil.frames(SHEET, FW, FH, anims), Vector2(FW / 2.0, FH - 2))
	add_child(body)
	home = position.x
	dir = -1.0 if randf() < 0.5 else 1.0
	timer = randf_range(0.5, 2.5)
	body.play("idle")


func _physics_process(delta: float) -> void:
	if state != "run" and level and level.player and not level.player.dead:
		if absf(level.player.position.x - position.x) < PANIC_PLAYER:
			panic(level.player.position.x)
	match state:
		"idle":
			timer -= delta
			if timer <= 0.0:
				state = "walk"
				# vuelve hacia su sitio si se alejó
				dir = signf(home - position.x) if absf(home - position.x) > 30.0 else (-1.0 if randf() < 0.5 else 1.0)
				timer = randf_range(1.5, 3.5)
				body.play("walk")
		"walk":
			position.x += dir * WALK_SPEED * delta
			timer -= delta
			if timer <= 0.0:
				state = "idle"
				timer = randf_range(1.0, 3.0)
				body.play("idle")
		"run":
			position.x += dir * RUN_SPEED * delta
			if level and absf(position.x - (level.cam_left + 240.0)) > 330.0:
				queue_free()
	body.flip_h = dir < 0.0


## Sale corriendo alejándose de from_x.
func panic(from_x: float) -> void:
	if state == "run":
		return
	state = "run"
	dir = 1.0 if position.x >= from_x else -1.0
	# un saltito de susto
	var tw := create_tween()
	tw.tween_property(body, "position:y", -6.0, 0.08)
	tw.tween_property(body, "position:y", 0.0, 0.1)
	body.play("run")


## Llamado por level.explode(): las explosiones cercanas también los asustan.
static func scare_all(tree: SceneTree, pos: Vector2) -> void:
	for c in tree.get_nodes_in_group("civil"):
		if c.global_position.distance_to(pos) < PANIC_BLAST:
			c.panic(pos.x)
