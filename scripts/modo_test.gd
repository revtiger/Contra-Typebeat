extends CanvasLayer
## Modo test (Game.test): teclas de desarrollo dentro de la fase y una línea de ayuda abajo.
## Sin F1 se ve el juego tal cual (el escenario con su arte, enemigos normales, sin ayuda ni teclas: para trabajar
## el arte sin ver comandos). F1 cambia al mundo del greybox (level.cambiar_mundo) y solo ahí se ven la ayuda y
## funcionan las demás teclas.
##   F1 greybox o arte   F2 soldado por la derecha   F3 jefe de la fase aquí mismo
##   F4 cápsula voladora con un arma al azar   F5 inmortal (sí / no)   F6 turbo: corre a 400 px/s (sí / no)
##   F7 granadero   F8 francotirador   F9 emboscadas de azotea (sí / no; empiezan apagadas en test)
## F2 (al azar), F7 y F8 sacan un soldado que entra por la derecha, se planta y ataca.
## En el greybox no salen enemigos solos: solo los de estas teclas (TEST_SKIP en level.gd).
## Se abre con el .exe de test o con: godot --path . -- test

const PixelFont = preload("res://scripts/pixel_font.gd")
const ARMAS := ["H", "R", "F", "L", "S"]

var level
var ayuda := Node2D.new()


func _ready() -> void:
	layer = 2  # encima del HUD
	add_child(ayuda)
	ayuda.draw.connect(_draw_ayuda)


func _process(_delta: float) -> void:
	ayuda.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or level.state != "play":
		return
	if key.physical_keycode == KEY_F1:
		level.cambiar_mundo()
		get_viewport().set_input_as_handled()
		return
	if not Game.greybox:
		return  # en el juego (sin F1) no hay más teclas de test
	match key.physical_keycode:
		KEY_F2:
			level.test_spawn_enemy()
		KEY_F3:
			level.test_spawn_boss()
		KEY_F4:
			level.spawn_capsule(ARMAS[randi() % ARMAS.size()])
		KEY_F5:
			level.player.god = not level.player.god
			level.show_banner("INMORTAL: " + ("SÍ" if level.player.god else "NO"), 1.0)
		KEY_F6:
			level.player.turbo = not level.player.turbo
			level.show_banner("TURBO: " + ("SÍ" if level.player.turbo else "NO"), 1.0)
		KEY_F7:
			level.test_spawn_enemy("grenadier")
		KEY_F8:
			level.test_spawn_enemy("sniper")
		KEY_F9:
			level.emboscadas = not level.emboscadas
			level.show_banner("EMBOSCADAS: " + ("SÍ" if level.emboscadas else "NO"), 1.0)
		_:
			return
	get_viewport().set_input_as_handled()


## Dos líneas de ayuda encima de la leyenda del greybox.
func _draw_ayuda() -> void:
	if not Game.greybox:
		return
	var h := PixelFont.size("white")
	var y := 270.0 - 3.0 * h - 10.0
	var p = level.player
	var lineas := [
		"TEST  F1 GREYBOX  F3 JEFE  F4 ARMA  F5 INMORTAL:%s  F6 TURBO:%s" % ["SÍ" if p.god else "NO", "SÍ" if p.turbo else "NO"],
		"ENEMIGOS  F2 AL AZAR  F7 GRANADERO  F8 FRANCOTIRADOR  F9 EMBOSCADAS:%s" % ("SÍ" if level.emboscadas else "NO"),
	]
	ayuda.draw_rect(Rect2(0, y - 2, 480, 2 * h + 4), Color(0.08, 0.08, 0.1, 0.85))
	for i in lineas.size():
		ayuda.draw_string(PixelFont.font("white"), Vector2(4, y + h - 2 + i * h), lineas[i], HORIZONTAL_ALIGNMENT_LEFT, -1, h, Color(1, 0.85, 0.3))
