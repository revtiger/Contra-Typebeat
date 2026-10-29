extends Node2D
## Estación del tren de la 1.1 (tramo 3b, de x0 a x1; idea de Eduardo, 28-10-2026). Decorado: detrás de las vías, la
## boletería, el cartel y el tanque de agua; las vías a lo largo de toda la estación; y, delante de las vías (nodo
## "frente"), la señal del paso a nivel y la barrera, que baja y hace parpadear las luces mientras pasa el tren
## (tren.gd, estado "aviso" o "pasa"). El andén donde camina el jugador lo dibuja terrain.gd.
## Sprites: tools/sprites/tren.py (ChatGPT).

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const VIAS := preload("res://assets/sprites/estacion_vias.png")
const BOLETERIA := preload("res://assets/sprites/estacion_boleteria.png")
const TANQUE := preload("res://assets/sprites/estacion_tanque.png")
const CARTEL := preload("res://assets/sprites/estacion_cartel.png")
const SENAL := preload("res://assets/sprites/estacion_senal.png")
const BARRERA_ARRIBA := preload("res://assets/sprites/estacion_barrera_arriba.png")
const BARRERA_ABAJO := preload("res://assets/sprites/estacion_barrera_abajo.png")
const VIAS_Y := 198.0  # borde de arriba de la tira de las vías; las ruedas apoyan en VIAS_Y + "riel" (tren_meta.json)
const FONDO_Y := 202.0  # donde apoyan la boletería, el cartel y el tanque (del otro lado de las vías)

var x0 := 0.0
var x1 := 0.0
var lock_x := 0.0  # pantalla fija del tren: la señal y la barrera van en su lado derecho, por donde entra
var frente := Node2D.new()
var t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	z_index = -7  # detrás del tren (-6) y delante de las casas del fondo (-8)
	frente.z_index = 2  # relativo: -5, delante del tren
	frente.draw.connect(_draw_frente)
	add_child(frente)


func _process(delta: float) -> void:
	t += delta
	if main.cam_left + 480.0 > lock_x and main.cam_left < lock_x + 480.0:
		frente.queue_redraw()


func _draw() -> void:
	draw_texture(BOLETERIA, Vector2(x0 + 280.0, FONDO_Y - BOLETERIA.get_height()))
	draw_texture(CARTEL, Vector2(x0 + 720.0, FONDO_Y - CARTEL.get_height()))
	draw_texture(TANQUE, Vector2(x0 + 1150.0, FONDO_Y - TANQUE.get_height()))
	draw_texture(CARTEL, Vector2(x0 + 1700.0, FONDO_Y - CARTEL.get_height()))
	# vías de punta a punta (alineadas con la x del mundo)
	var tw := float(VIAS.get_width())
	var x := x0 - 60.0 - fposmod(x0 - 60.0, tw)
	while x < x1 + 60.0:
		draw_texture(VIAS, Vector2(x, VIAS_Y))
		x += tw


func _draw_frente() -> void:
	var tren = get_tree().get_first_node_in_group("tren")
	var activo: bool = tren != null and tren.estado != "espera"
	var base := VIAS_Y + VIAS.get_height() + 2.0
	# barrera: baja mientras pasa el tren
	var bx := lock_x + 380.0  # centro del poste
	var barrera := BARRERA_ABAJO if activo else BARRERA_ARRIBA
	var poste: float = SpriteUtil.meta("res://assets/sprites/tren_meta.json")["estacion"][
		"barrera_abajo" if activo else "barrera_arriba"]["poste"]
	frente.draw_texture(barrera, Vector2(bx - poste, base - barrera.get_height()))
	# señal con sus dos luces rojas que parpadean alternadas
	var sx := lock_x + 430.0
	frente.draw_texture(SENAL, Vector2(sx - SENAL.get_width() / 2.0, base - SENAL.get_height()))
	if activo:
		var lado := -1.0 if int(t * 3.0) % 2 == 0 else 1.0
		var luz := Vector2(sx + lado * 6.0, base - SENAL.get_height() * 0.6)
		frente.draw_circle(luz, 5.0, Color(1, 0.25, 0.1, 0.35))
		frente.draw_circle(luz, 2.5, Color(1, 0.75, 0.5))
