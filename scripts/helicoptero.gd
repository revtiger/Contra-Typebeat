extends StaticBody2D
## Helicóptero de ataque enemigo (canal de la 1.1, pedido de Eduardo): entra por la derecha, sobrevuela al jugador
## cambiando de lado y le dispara ráfagas hacia abajo. Para apuntar gira pasando por las posiciones de la hoja una a
## una (perfil, tres cuartos, de frente…), así el giro se ve fluido. Al morir cae girando entre explosiones y estalla
## contra el suelo. Si sigue vivo después de VIDA_MAX segundos, se va por arriba.
## Sprites: tools/sprites/helicoptero.py (ChatGPT, hoja de giro de 5 posiciones; las aspas las dibuja este script).

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")
const SHEET := preload("res://assets/sprites/helicoptero.png")
const MAX_HP := 14
const VIDA_MAX := 17.0
## posiciones de la hoja: 0 perfil izquierda, 1 tres cuartos izquierda, 2 de frente, 3 tres cuartos derecha,
## 4 perfil derecha
const FRENTE := 2
const PASO_GIRO := 0.08    # s por posición al girar
const LADO_CADA := 4.5     # s que se queda de un lado del jugador antes de cruzar al otro
const SEPARACION := 75.0   # px a un lado del jugador
const ALTURA := 30.0       # px desde arriba de la pantalla (eje del rotor)
const APARTE := 135.0      # dos helicópteros no se acercan más que esto en x
const RAFAGA := 4
const RAFAGA_DT := 0.11
const ESPERA := 1.7        # s entre ráfagas
const VEL_BALA := 125.0
const ROTOR_R := 54.0      # largo de cada aspa del rotor principal
const ROTOR_VEL := 23.0    # rad/s

var hp := MAX_HP
var state := "enter"  # enter | fight | leave | dying
var t := 0.0
var vel := Vector2.ZERO
var pose := 0  # entra de perfil, mirando a la izquierda
var giro_t := 0.0
var lado := 1.0
var altura_extra := 0.0
var lado_t := LADO_CADA
var shoot_t := 1.2
var burst_left := 0
var burst_t := 0.0
var flash := 0.0
var muzzle_flash := 0.0
var fall_v := 0.0
var boom_t := 0.0
var meta: Dictionary
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	meta = SpriteUtil.meta("res://assets/sprites/helicoptero_meta.json")
	add_to_group("enemy")
	add_to_group("helicoptero")
	collision_layer = 4
	collision_mask = 0
	z_index = 3
	var fr := _frame()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(fr.x * 0.62, fr.y * 0.5)
	cs.shape = r
	cs.position = Vector2(fr.x * 0.5, fr.y * 0.55) - _rotor()
	add_child(cs)
	position = Vector2(main.cam_left + 540.0, main.cam_y + ALTURA - 10.0)
	# si ya hay otro, este va del otro lado del jugador y un poco más alto
	for h in get_tree().get_nodes_in_group("helicoptero"):
		if h != self:
			lado = -h.lado
			altura_extra = -10.0
	Game.sfx("jet", -6.0, 0.55)


func _frame() -> Vector2:
	return SpriteUtil.v(meta["frame"])


## El origen del nodo es el eje del rotor principal (así el giro no salta).
func _rotor() -> Vector2:
	return SpriteUtil.v(meta["rotor"])


func _local(p: Array) -> Vector2:
	return Vector2(p[0], p[1]) - _rotor()


func _physics_process(delta: float) -> void:
	t += delta
	flash -= delta
	muzzle_flash -= delta
	var p = main.player
	match state:
		"enter", "fight":
			_fly(delta, p)
			_turn(delta, p)
			if state == "enter" and position.x < main.cam_left + 440.0:
				state = "fight"
			if state == "fight":
				_attack(delta, p)
			if t > VIDA_MAX:
				state = "leave"
		"leave":
			vel = vel.lerp(Vector2(60, -90), 1.5 * delta)
			position += vel * delta
			if position.y < main.cam_y - 80.0 or position.x > main.cam_left + 600.0:
				queue_free()
		"dying":
			# cae dando vueltas: recorre las posiciones de la hoja como si girara sobre sí mismo
			fall_v += 170.0 * delta
			position += Vector2(vel.x * 0.4, fall_v) * delta
			giro_t -= delta
			if giro_t <= 0.0:
				giro_t = 0.06
				pose = (pose + 1) % 5
			boom_t -= delta
			if boom_t <= 0.0:
				boom_t = 0.15
				main.explode(position + Vector2(randf_range(-30, 30), randf_range(0, 24)), randf_range(8, 16))
			var gy: float = main.ground_y_at(position.x)
			if position.y + 20.0 >= gy:
				main.blast(Vector2(position.x, gy - 10.0), 40.0, false, 8)
				main.explode(position + Vector2(-18, 14), 26.0)
				main.explode(position + Vector2(16, 6), 22.0)
				queue_free()
	if position.x < main.cam_left - 120.0:
		queue_free()
	queue_redraw()


## Se mueve con inercia hasta su sitio: a un lado del jugador, a la altura de vuelo; cada tanto cruza al otro lado.
func _fly(delta: float, p) -> void:
	lado_t -= delta
	if lado_t <= 0.0:
		lado_t = LADO_CADA + randf_range(-1.0, 1.0)
		lado = -lado
	var want := Vector2(p.position.x + lado * SEPARACION, main.cam_y + ALTURA + altura_extra + sin(t * 1.6) * 4.0)
	var lo: float = main.cam_left + 70.0
	var hi: float = main.cam_left + 420.0
	want.x = clampf(want.x, lo, hi)
	# no se encima con otro helicóptero: manda el que llegó antes y este se pone a su lado (del lado que quepa)
	for h in get_tree().get_nodes_in_group("helicoptero"):
		if h != self and h.get_instance_id() < get_instance_id() and absf(h.position.x - want.x) < APARTE:
			var s := 1.0 if want.x >= h.position.x else -1.0
			want.x = h.position.x + APARTE * s
			if want.x < lo or want.x > hi:
				want.x = h.position.x - APARTE * s
			want.x = clampf(want.x, lo, hi)
	vel = vel.lerp((want - position) * 1.6, 2.2 * delta).limit_length(110.0)
	position += vel * delta


## Posición de la hoja que apunta al jugador, según el ángulo desde la vertical.
func _target_pose(p) -> int:
	var d: Vector2 = p.position + Vector2(0, -12) - position
	var a := rad_to_deg(atan2(d.x, maxf(d.y, 1.0)))
	if a < -50.0:
		return 0
	if a < -18.0:
		return 1
	if a <= 18.0:
		return FRENTE
	return 3 if a <= 50.0 else 4


## Gira una posición cada PASO_GIRO hacia la que apunta al jugador.
func _turn(delta: float, p) -> void:
	giro_t -= delta
	var want := _target_pose(p)
	if giro_t <= 0.0 and want != pose:
		giro_t = PASO_GIRO
		pose += signi(want - pose)


func _attack(delta: float, p) -> void:
	if p.dead:
		return
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_t = RAFAGA_DT
			burst_left -= 1
			_shoot(p)
		return
	shoot_t -= delta
	# solo empieza la ráfaga ya girado hacia el jugador
	if shoot_t <= 0.0 and pose == _target_pose(p):
		shoot_t = ESPERA
		burst_left = RAFAGA
		burst_t = 0.0


## Bala desde la boca del cañón, hacia el jugador pero sin salirse mucho de hacia dónde apunta el cañón.
func _shoot(p) -> void:
	var from := position + _local(meta["muzzles"][pose])
	var aim: Vector2 = SpriteUtil.v(meta["aims"][pose]).normalized()
	var to: Vector2 = (p.position + Vector2(0, -12) - from).normalized()
	var ang := clampf(aim.angle_to(to), -0.35, 0.35)
	var b := Bullet.new()
	b.from_player = false
	b.life = 3.0
	b.vel = aim.rotated(ang) * VEL_BALA
	b.position = from
	get_parent().add_child(b)
	muzzle_flash = 0.06
	Game.sfx("shot", -16.0, 0.7)


func take_damage(n: int) -> void:
	if state == "dying":
		return
	hp -= n
	flash = 0.05
	Game.sfx("hit", -16.0, 0.8)
	if hp <= 0:
		state = "dying"
		remove_from_group("enemy")
		remove_from_group("helicoptero")
		collision_layer = 0
		main.add_score(1500)
		Game.sfx("boom", -2.0, 0.8)
		main.shake(4.0)
		main.explode(position + Vector2(0, 14), 18.0)


func _draw() -> void:
	var fr := _frame()
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	draw_texture_rect_region(SHEET, Rect2(-_rotor(), fr), Rect2(pose * fr.x, 0, fr.x, fr.y), tint)
	_draw_rotor_cola()
	_draw_rotor()
	if muzzle_flash > 0.0 and state == "fight":
		var m := _local(meta["muzzles"][pose]) + SpriteUtil.v(meta["aims"][pose]) * 3.0
		draw_circle(m, 4.0, Color(1, 0.8, 0.25))
		draw_circle(m, 2.2, Color(1, 1, 0.85))
	# humo cuando está dañado o cayendo
	if hp < MAX_HP / 2 or state == "dying":
		for i in 4:
			var k := fmod(t * 1.4 + i * 0.25, 1.0)
			var c := Vector2(12.0 * (1.0 if pose < FRENTE else -1.0), 10.0)
			draw_circle(c + Vector2(k * 14.0, -k * 26.0), 3.0 + k * 6.0, Color(0.18, 0.17, 0.16, 0.55 * (1.0 - k)))


## Rotor principal: disco translúcido aplanado (visto casi de lado) y dos aspas que giran, con contorno oscuro y
## centro claro para que se lean sobre las casas, y estelas detrás.
func _draw_rotor() -> void:
	var disco := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		disco.append(Vector2(cos(a) * ROTOR_R, sin(a) * ROTOR_R * 0.14))
	draw_colored_polygon(disco, Color(0.85, 0.88, 0.85, 0.13))
	var ang := t * ROTOR_VEL
	for g in [2, 1, 0]:
		var a: float = ang - g * 0.32
		var tip := Vector2(cos(a) * ROTOR_R, sin(a) * ROTOR_R * 0.14)
		var alpha: float = [0.95, 0.4, 0.18][g]
		draw_line(-tip, tip, Color(0.08, 0.08, 0.07, alpha), 3.0)
		draw_line(-tip * 0.96, tip * 0.96, Color(0.55, 0.56, 0.52, alpha), 1.0)
	draw_rect(Rect2(-2, -1, 4, 3), Color(0.15, 0.15, 0.14))


## Rotor de cola: un disco que gira de cara a la cámara (de frente no se ve); más angosto de tres cuartos.
func _draw_rotor_cola() -> void:
	var tail = meta["tails"][pose]
	if tail == null:
		return
	var c := _local(tail)
	var sx := 1.0 if pose == 0 or pose == 4 else 0.6
	var disco := PackedVector2Array()
	for k in 12:
		var a := TAU * k / 12.0
		disco.append(c + Vector2(cos(a) * 8.0 * sx, sin(a) * 8.0))
	draw_colored_polygon(disco, Color(0.85, 0.88, 0.85, 0.15))
	for g in [1, 0]:
		var a: float = t * 31.0 - g * 0.5
		var d := Vector2(cos(a) * 8.0 * sx, sin(a) * 8.0)
		var alpha: float = 0.9 if g == 0 else 0.35
		draw_line(c - d, c + d, Color(0.08, 0.08, 0.07, alpha), 2.0)
		draw_line(c - d * 0.9, c + d * 0.9, Color(0.55, 0.56, 0.52, alpha), 1.0)
