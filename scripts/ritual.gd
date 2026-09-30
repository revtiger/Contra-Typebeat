extends Node2D
## Final del nivel secreto: tras vencer al líder de la Orden Mundial aparecen los jefes finales
## de cada país en las puntas de un pentagrama, giran hacia el centro y se fusionan en el
## verdadero jefe final (politician.gd, id "fusion").

const Politician = preload("res://scripts/politician.gd")
const DIR := "res://assets/sprites/"
const BOSSES := ["milei", "sheinbaum", "trump", "merz", "lider"]
const RADIUS := 78.0

var main
var t := 0.0
var ghosts: Array[Sprite2D] = []
var spawned := false


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	position = Vector2(main.boss_arena + 300.0, 125.0)
	z_index = 4
	for i in BOSSES.size():
		var s := Sprite2D.new()
		s.texture = load(DIR + "pol_%s.png" % BOSSES[i])
		s.modulate = Color(1, 0.4, 0.4, 0.0)
		s.position = _point(i)
		add_child(s)
		ghosts.append(s)
	main.show_banner("¡LA ORDEN SE REÚNE!", 2.5)
	Game.stop_music()
	Game.sfx("boom", -6.0, 0.4)


## Punta i del pentagrama (empieza arriba).
func _point(i: int, r := RADIUS) -> Vector2:
	return Vector2.from_angle(-PI / 2.0 + i * TAU / 5.0) * r


func _physics_process(delta: float) -> void:
	t += delta
	for i in ghosts.size():
		var g := ghosts[i]
		if t < 1.5:
			g.modulate.a = clampf(t - i * 0.2, 0.0, 1.0) * 0.85
		elif t < 3.2:
			# giran y se acercan al centro
			var k := (t - 1.5) / 1.7
			var ang := -PI / 2.0 + i * TAU / 5.0 + k * k * TAU * 1.5
			g.position = Vector2.from_angle(ang) * RADIUS * (1.0 - k)
			g.scale = Vector2.ONE * (1.0 - k * 0.6)
			g.modulate = Color(1, 0.4 + k * 0.6, 0.4 + k * 0.6, 0.85)
	if t > 1.5 and int(t * 5.0) != int((t - delta) * 5.0):
		Game.sfx("beep", -10.0, 0.5 + t * 0.2)
		main.shake(1.5 + t)
	if t >= 3.2 and not spawned:
		spawned = true
		for g in ghosts:
			g.queue_free()
		ghosts.clear()
		Juice.hitstop(0.2)
		main.shake(6.0)
		main.explode(position, 40.0)
		var f := Politician.new()
		f.id = "fusion"
		main.add_child(f)
		f.phase = "fight"
		f.position = Vector2(main.boss_arena + 370.0, f.base_y - 30.0)
		main.boss = f
		main.reset_time()
		main.show_banner("¡JEFE FINAL!\nLA ORDEN FUSIONADA", 2.5)
		Game.play_music("boss")
	if t > 4.2:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var grow := clampf(t / 1.0, 0.0, 1.0)
	var fade := 1.0 if t < 3.2 else clampf(1.0 - (t - 3.2), 0.0, 1.0)
	if fade <= 0.0:
		return
	var glow := 0.6 + 0.4 * sin(t * 10.0)
	var c := Color(1, 0.15, 0.1, fade * glow)
	draw_arc(Vector2.ZERO, RADIUS * grow + 4, 0, TAU * grow, 48, c, 2)
	# estrella de cinco puntas: une cada punta con la que está a dos de distancia
	var n := int(grow * 5.0 + 0.999)
	for i in n:
		draw_line(_point(i) * grow, _point((i + 2) % 5) * grow, c, 2)
	if t > 3.0:
		draw_circle(Vector2.ZERO, (t - 3.0) * 200.0, Color(1, 1, 1, fade * 0.8))
