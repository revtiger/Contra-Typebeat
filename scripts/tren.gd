extends Node2D
## Tren de la estación (1.1, tramo 3b; idea de Eduardo, 28-10-2026): cuando la cámara llega a lock_x se fija (como
## con un mini jefe), suena el silbato y la campana, baja la barrera (estacion.gd) y, a los AVISO_T s, un tren normal
## pasa despacio por las vías del fondo de derecha a izquierda, sin parar. Lleva soldados: se asoman por las ventanas
## del vagón de pasajeros, disparan desde la plataforma, saltan al andén por la puerta del vagón de carga y tiran
## granadas desde el furgón de cola (tren_tirador.gd). Cuando se va el último vagón, la cámara se suelta.
## El nivel lo pone con ["tren", x, y]: x = lock_x (borde izquierdo de la pantalla fija), y = fila donde apoyan las
## ruedas (el riel de delante de las vías).
## Sprites: tools/sprites/tren.py (ChatGPT).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const Tirador = preload("res://scripts/tren_tirador.gd")
const Soldier = preload("res://scripts/soldier.gd")
const VAGONES := ["locomotora", "pasajeros", "plataforma", "carga", "cola"]
const TEX := {
	"locomotora": preload("res://assets/sprites/tren_locomotora.png"),
	"pasajeros": preload("res://assets/sprites/tren_pasajeros.png"),
	"plataforma": preload("res://assets/sprites/tren_plataforma.png"),
	"carga": preload("res://assets/sprites/tren_carga.png"),
	"cola": preload("res://assets/sprites/tren_cola.png"),
}
const VEL := 34.0      # px/s: el tren entero tarda unos 30 s en cruzar la pantalla
const AVISO_T := 2.6   # s entre que se fija la pantalla y aparece la locomotora
const SEP := 3.0       # px entre vagones (los enganches)
const BAJAN := 3       # soldados que saltan del vagón de carga
const BAJAN_CADA := 1.1

var estado := "espera"  # espera | aviso | pasa
var estado_t := 0.0
var t := 0.0
var lock_x := 0.0
var meta: Dictionary
var offs := []      # x de cada vagón desde la cabeza del tren
var largo := 0.0
var humo := []      # [posición en el mundo, edad]
var humo_t := 0.0
var campana_t := 0.0
var bajados := 0
var bajar_t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("tren")
	meta = SpriteUtil.meta("res://assets/sprites/tren_meta.json")
	z_index = -6  # delante de la estación y las vías (estacion.gd, -7), detrás del jugador
	lock_x = position.x
	var x := 0.0
	for v in VAGONES:
		offs.append(x)
		x += float(meta["vagones"][v]["size"][0]) + SEP
	largo = x - SEP
	visible = false


func _physics_process(delta: float) -> void:
	t += delta
	estado_t -= delta
	match estado:
		"espera":
			# si la cámara ya pasó de largo (un salto, como el de la prueba que empieza en el jefe), no se activa
			if main.cam_left > lock_x + main.SCREEN_W:
				queue_free()
				return
			if main.cam_left >= lock_x - 1.0:
				main.lock_camera(lock_x, "TREN ENEMIGO")
				estado = "aviso"
				estado_t = AVISO_T
				Game.sfx("whistle", -4.0, 0.5)
		"aviso":
			_campana(delta)
			if estado_t <= 0.0:
				estado = "pasa"
				position.x = lock_x + main.SCREEN_W + 30.0
				visible = true
				_subir_soldados()
				Game.sfx("whistle", -2.0, 0.45)
		"pasa":
			_campana(delta)
			position.x -= VEL * delta
			_humo(delta)
			_bajar(delta)
			if position.x + largo < lock_x - 40.0:
				main.unlock_camera("¡EL TREN PASÓ!")
				queue_free()
	queue_redraw()


## Campana del paso a nivel: dos golpes cada 0,9 s mientras dura el aviso o pasa el tren.
func _campana(delta: float) -> void:
	campana_t -= delta
	if campana_t <= 0.0:
		campana_t = 0.9
		Game.sfx("beep", -14.0, 0.8)


## Tamaño de un vagón y su esquina de arriba a la izquierda (relativa a la cabeza del tren, las ruedas en y = 0).
func _vagon(i: int) -> Rect2:
	var s := SpriteUtil.v(meta["vagones"][VAGONES[i]]["size"])
	return Rect2(Vector2(offs[i], -s.y), s)


func _subir_soldados() -> void:
	# una ventana sí y otra no, para que no sea un muro de balas
	var pas := _vagon(1)
	var vs: Array = meta["vagones"]["pasajeros"]["ventanas"]
	for k in vs.size():
		if k % 2 == 0:
			var r: Array = vs[k]
			_tirador("ventana", Vector2.ZERO, Rect2(pas.position + Vector2(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1])))
	var pla := _vagon(2)
	var cub: float = meta["vagones"]["plataforma"]["cubierta"]
	for f in [0.3, 0.72]:
		_tirador("pie", pla.position + Vector2(pla.size.x * f, cub))
	var col := _vagon(4)
	_tirador("granada", col.position + Vector2(col.size.x * 0.86, float(meta["vagones"]["cola"]["cubierta"])))


func _tirador(modo: String, pos: Vector2, ventana := Rect2()) -> void:
	var s := Tirador.new()
	s.modo = modo
	s.ventana = ventana
	s.position = pos
	add_child(s)


## Por la puerta del vagón de carga saltan BAJAN soldados al andén cuando la puerta está en pantalla.
func _bajar(delta: float) -> void:
	if bajados >= BAJAN:
		return
	var car := _vagon(3)
	var p: Array = meta["vagones"]["carga"]["puerta"]
	var puerta := global_position + car.position + Vector2((p[0] + p[2]) / 2.0, p[3])
	if puerta.x < lock_x + 60.0 or puerta.x > lock_x + main.SCREEN_W - 60.0:
		return
	bajar_t -= delta
	if bajar_t > 0.0:
		return
	bajar_t = BAJAN_CADA
	bajados += 1
	var s := Soldier.new()
	if bajados == BAJAN:
		s.mode = "grenadier"
	s.dir = -1 if main.player.position.x < puerta.x else 1
	s.position = puerta - Vector2(0, 2)
	main.add_child(s)


## Humo de la chimenea: bocanadas que suben y se quedan atrás (el tren va a la izquierda).
func _humo(delta: float) -> void:
	humo_t -= delta
	if humo_t <= 0.0:
		humo_t = 0.12
		var c: Array = meta["vagones"]["locomotora"]["chimenea"]
		humo.append([global_position + _vagon(0).position + Vector2(c[0], c[1]), 0.0])
	for h in humo:
		h[1] += delta
		h[0] += Vector2(VEL * 0.55, -22.0 + h[1] * 6.0) * delta
	humo = humo.filter(func(h): return h[1] < 1.8)


func _draw() -> void:
	if not visible:
		return
	for i in VAGONES.size():
		var r := _vagon(i)
		# traqueteo: cada vagón sube y baja un píxel a su ritmo
		var bob := roundf(sin(t * 13.0 + i * 1.9) * 0.6)
		draw_texture(TEX[VAGONES[i]], (r.position + Vector2(0, bob)).round())
	for h in humo:
		var k: float = h[1] / 1.8
		var c: Vector2 = h[0] - global_position
		draw_circle(c.round(), 3.0 + k * 9.0, Color(0.85, 0.84, 0.82, 0.55 * (1.0 - k)))
