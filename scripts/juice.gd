extends Node
## Autoload "Juice": sensación de impacto. Hitstop (congelar el juego un instante al golpear)
## y temblor de cámara a través de la escena de nivel actual.
##
## El hitstop se deshace comprobando el reloj real en cada fotograma (_process corre siempre,
## también con el juego ralentizado o en pausa). Antes se usaba un temporizador y, si terminaba
## una milésima antes de lo previsto, el juego se quedaba en cámara lenta para siempre.

const SLOW_SCALE := 0.05
const MAX_STOP := 0.3  # seguridad: nunca más de 0,3 s congelado

var _stop_until := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if Engine.time_scale < 1.0 and Time.get_ticks_msec() >= _stop_until:
		Engine.time_scale = 1.0


## Congela el juego `duration` segundos reales. Varias llamadas seguidas no se acumulan:
## gana la que termina más tarde.
func hitstop(duration := 0.04) -> void:
	var end_ms := Time.get_ticks_msec() + int(minf(duration, MAX_STOP) * 1000.0)
	if end_ms <= _stop_until and Engine.time_scale < 1.0:
		return
	_stop_until = end_ms
	Engine.time_scale = SLOW_SCALE


func shake(amount: float) -> void:
	var lvl = get_tree().current_scene
	if lvl and lvl.has_method("shake"):
		lvl.shake(amount)


## Por si una escena cambia en mitad de un hitstop.
func reset() -> void:
	_stop_until = 0
	Engine.time_scale = 1.0
