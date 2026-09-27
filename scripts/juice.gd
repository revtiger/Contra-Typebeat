extends Node
## Autoload "Juice": sensación de impacto. Hitstop (congelar el juego un instante al golpear)
## y temblor de cámara a través de la escena de nivel actual.

var _stop_until := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Congela el juego `duration` segundos reales (casi parado). Varias llamadas seguidas no se acumulan:
## gana la que termina más tarde.
func hitstop(duration := 0.04) -> void:
	if Game.autoplay:
		return
	var end_ms := Time.get_ticks_msec() + int(duration * 1000.0)
	if end_ms <= _stop_until:
		return
	_stop_until = end_ms
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if Time.get_ticks_msec() >= _stop_until:
		Engine.time_scale = 1.0


func shake(amount: float) -> void:
	var lvl = get_tree().current_scene
	if lvl and lvl.has_method("shake"):
		lvl.shake(amount)


## Por si una escena cambia en mitad de un hitstop.
func reset() -> void:
	_stop_until = 0
	Engine.time_scale = 1.0
