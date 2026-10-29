extends StaticBody2D
## Soldado que viaja en el tren de la estación (tren.gd, 1.1): es hijo del tren y se mueve con él.
## - "ventana": se asoma por una ventana del vagón de pasajeros, dispara dos tiros y se vuelve a esconder. Solo se le
##   puede dar mientras está asomado.
## - "pie": de pie en la plataforma, detrás de los cajones (se ve de la cintura para arriba); dispara ráfagas cortas.
## - "granada": en la baranda del furgón de cola, tira granadas al andén.
## De un tiro muere: el de la ventana cae dentro del vagón; los de pie salen despedidos al andén.
## Sprite: la hoja del soldado de Argentina (soldier_ar.png y sus caras), que mira a la derecha.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Sangre = preload("res://scripts/sangre.gd")
const CARAS := 4  # variantes de cara (soldier_ar_1..4.png)
const VENTANA_PIES := 22.0  # los pies, tantos px por debajo del alféizar: asoma del pecho para arriba
const ASOMA_T := 0.15       # lo que tarda en asomarse
const BALA_V := 170.0

var modo := "ventana"
var ventana := Rect2()  # (solo "ventana") el hueco de la ventana, en coordenadas del tren
var main
var meta: Dictionary
var hoja: Texture2D
var estado := "escondido"  # escondido | asomado ("ventana"); los demás modos siempre están a la vista
var estado_t := 0.0
var tiro_t := 0.0
var tiros := 0
var lanza_t := 0.0
var fire_t := 0.0
var dir := -1
var pose := 0  # fotograma de apuntar: 0 al frente, 3 en diagonal hacia abajo
var vivo := true


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	meta = SpriteUtil.meta("res://assets/sprites/soldier_ar_meta.json")
	var cara := randi() % (CARAS + 1)
	hoja = load("res://assets/sprites/soldier_ar.png" if cara == 0 else "res://assets/sprites/soldier_ar_%d.png" % cara)
	add_to_group("enemy")
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	if modo == "ventana":
		position = Vector2(ventana.get_center().x, ventana.end.y + VENTANA_PIES)
		collision_layer = 0  # escondido: no se le puede dar
		r.size = Vector2(12, 18)
		cs.position = Vector2(0, -VENTANA_PIES - 9.0)
		z_index = 1  # delante del vagón (se asoma por la ventana)
		estado_t = randf_range(0.6, 2.4)
	else:
		collision_layer = 4  # EnemyHurtbox
		r.size = Vector2(14, 26)
		cs.position = Vector2(0, -36)
		z_index = -1  # detrás del vagón: los cajones y la baranda lo tapan de la cintura para abajo
		tiro_t = randf_range(0.8, 1.8)
	cs.shape = r
	add_child(cs)


func _physics_process(delta: float) -> void:
	if not vivo:
		return
	fire_t -= delta
	lanza_t -= delta
	var p = main.player
	var to: Vector2 = p.global_position + Vector2(0, -16) - (global_position + Vector2(0, -34))
	dir = 1 if to.x > 0.0 else -1
	pose = 3 if to.y > absf(to.x) * 0.4 else 0
	match modo:
		"ventana":
			estado_t -= delta
			if estado == "escondido" and estado_t <= 0.0:
				estado = "asomado"
				estado_t = 1.5
				collision_layer = 4  # EnemyHurtbox
				tiros = 2
				tiro_t = 0.45
			elif estado == "asomado":
				tiro_t -= delta
				if tiro_t <= 0.0 and tiros > 0 and not p.dead:
					tiros -= 1
					tiro_t = 0.4
					_disparar()
				if estado_t <= 0.0:
					estado = "escondido"
					estado_t = randf_range(1.0, 2.4)
					collision_layer = 0
		"pie":
			tiro_t -= delta
			if tiro_t <= 0.0 and not p.dead:
				if tiros <= 0:
					tiros = 2
				_disparar()
				tiros -= 1
				tiro_t = 0.22 if tiros > 0 else randf_range(1.3, 2.0)
		"granada":
			tiro_t -= delta
			if tiro_t <= 0.0 and not p.dead:
				tiro_t = 2.6
				lanza_t = 0.3
				main.throw_grenade(global_position + Vector2(-dir * 4, -42), p.global_position.x + randf_range(-24.0, 24.0))
	queue_redraw()


func _disparar() -> void:
	var m: Array = meta["muzzles"][pose]
	var b := Bullet.new()
	b.from_player = false
	b.position = global_position + Vector2(m[0] * dir, m[1])
	b.vel = (Vector2(dir, 0) if pose == 0 else Vector2(dir, 1).normalized()) * BALA_V
	main.add_child(b)
	fire_t = 0.07
	Game.sfx("shot", -20.0, 0.75)


func take_damage(_n: int) -> void:
	if not vivo or (modo == "ventana" and estado != "asomado"):
		return
	vivo = false
	collision_layer = 0
	remove_from_group("enemy")
	main.add_score(200)
	Sangre.salpicar(main, global_position + Vector2(0, -34), Vector2(-dir, -0.4), 8)
	if modo != "ventana":
		# sale despedido al andén con la muerte del soldado de Argentina
		var s := Soldier.new()
		s.mode = "sniper"
		s.dir = dir
		s.position = global_position + Vector2(0, -10)
		main.add_child.call_deferred(s)
		s.call_deferred("take_damage", 99)
	queue_free()


func _draw() -> void:
	var fr := SpriteUtil.v(meta["frame"])
	var feet := SpriteUtil.v(meta["feet"])
	var rows: Dictionary = meta["rows"]
	var src := Rect2(pose * fr.x, rows["aim"] * fr.y, fr.x, fr.y)
	if modo == "granada":
		var f := int(meta["throw_release"]) if lanza_t > 0.0 else 0
		src = Rect2(f * fr.x, rows["throw"] * fr.y, fr.x, fr.y)
	var at := -feet
	if modo == "ventana":
		if estado != "asomado":
			return
		# sube desde el alféizar al asomarse; por debajo del alféizar no se dibuja
		var sube := clampf((1.5 - estado_t) / ASOMA_T, 0.0, 1.0)
		at.y += roundf((1.0 - sube) * 18.0)
		var corte := feet.y - VENTANA_PIES - (at.y + feet.y)
		if corte <= 0.0:
			return
		src.size.y = corte
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1))
	draw_texture_rect_region(hoja, Rect2(at, src.size), src)
	draw_set_transform(Vector2.ZERO)
	if fire_t > 0.0 and modo != "granada":
		var m: Array = meta["muzzles"][pose]
		var c := Vector2(m[0] * dir, m[1])
		draw_circle(c, 3.5, Color(1, 0.6, 0.15))
		draw_circle(c, 2.0, Color(1, 0.95, 0.6))
