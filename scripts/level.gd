extends Node2D
## Escena de una misión: construye el nivel desde levels.gd, cámara, HUD, explosiones y estado de la partida.

const Levels = preload("res://scripts/levels.gd")
const Player = preload("res://scripts/player.gd")
const CineLlegada = preload("res://scripts/cinematica_llegada.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Turret = preload("res://scripts/turret.gd")
const Boss = preload("res://scripts/boss.gd")
const Heli = preload("res://scripts/heli.gd")
const Tank = preload("res://scripts/tank.gd")
const Barrel = preload("res://scripts/barrel.gd")
const Mine = preload("res://scripts/mine.gd")
const Jet = preload("res://scripts/jet.gd")
const Miniboss = preload("res://scripts/miniboss.gd")
const Mecha = preload("res://scripts/mecha.gd")
const Politician = preload("res://scripts/politician.gd")
const Door = preload("res://scripts/door.gd")
const Massa = preload("res://scripts/massa.gd")
const Hud = preload("res://scripts/hud.gd")
const Bomb = preload("res://scripts/bomb.gd")
const Pickup = preload("res://scripts/pickup.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Background = preload("res://scripts/background.gd")
const Explosion = preload("res://scripts/explosion.gd")
const Civilian = preload("res://scripts/civilian.gd")
const Caja = preload("res://scripts/caja.gd")
const PuebloCasas = preload("res://scripts/pueblo_casas.gd")
const Canal = preload("res://scripts/canal.gd")

const SCREEN_W := 480.0
const SCREEN_H := 270.0
const START_TIME := 60
const TIME_TICK := 4.0  # como en Metal Slug: TIME baja 1 cada 4 s
const CALLE_Y := 230.0  # altura normal del suelo: con el jugador ahí la cámara está arriba del todo
const FONDO := 440.0    # borde de abajo de los bloques de suelo (más abajo de lo que llega a ver la cámara)

var data: Dictionary
var theme := "jungle"
var country := "mx"
var ground: Array
var level_end := 0.0
var boss_arena := 0.0
var entities: Array
var player
var boss
var camera := Camera2D.new()
var cam_left := 0.0
## La cámara baja con el suelo (el canal de la 1.1): el jugador se ve siempre a la misma altura de la pantalla.
## cam_y_max = cuánto puede bajar (0 en las fases donde no se mueve en vertical).
var cam_y := 0.0
var cam_y_max := 0.0
var shake_amt := 0.0
var lock_left := INF
var boss_announced := false
var state := "play"  # cine | play | over | clear
var spawn_t := 2.5
var next_entity := 0
var hud := Hud.new()
var time_left := START_TIME
var time_acc := 0.0
var banner_t := 2.5


func _ready() -> void:
	add_to_group("level")
	add_to_group("main")
	data = Levels.LIST[Game.level]
	theme = data["theme"]
	country = data.get("country", "mx")
	ground = data["ground"]
	level_end = data["end"]
	cam_y_max = data.get("cam_y_max", 0.0)
	boss_arena = level_end - SCREEN_W
	entities = data["entities"].duplicate()
	entities.sort_custom(func(a, b): return a[1] < b[1])
	RenderingServer.set_default_clear_color(Color.BLACK)
	Juice.reset()

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	var sky := Background.new()
	sky.kind = "sky"
	sky.theme = theme
	sky.country = country
	sky.main = self
	sky_layer.add_child(sky)
	add_child(sky_layer)
	var layers := [["mountains", 0.85, -9], ["jungle", 0.55, -8], ["water", 0.0, -5]]
	if theme == "desert":
		layers = [["mesas", 0.85, -9], ["dunes", 0.55, -8], ["chasm", 0.0, -5]]
	elif theme == "city":
		layers = [["colonial", 0.85, -9], ["ruins", 0.55, -8], ["sewer", 0.0, -5]]
	elif theme == "snow":
		layers = [["alps", 0.85, -9], ["pines", 0.55, -8], ["ice", 0.0, -5], ["snowfall", 1.0, 3]]
	elif theme == "base":
		layers = [["vault", 0.85, -9], ["machines", 0.55, -8], ["abyss", 0.0, -5]]
	elif theme == "pueblo":
		layers = [["pueblo", 0.0, -9], ["aves", 0.0, -9], ["casas", 0.0, -8]]
	elif theme == "quebrada":
		layers = [["panorama", 0.0, -9], ["chasm", 0.0, -5]]
	elif theme == "baires":
		layers = [["panorama", 0.0, -9], ["sewer", 0.0, -5]]
	for k in layers:
		var bg := Background.new()
		bg.kind = k[0]
		bg.factor = k[1]
		bg.z_index = k[2]
		bg.theme = theme
		bg.country = country
		bg.main = self
		add_child(bg)

	for g in ground:
		if g.size() > 3 and g[3] != g[2]:
			_add_slope(g)
		else:
			_add_block(Rect2(g[0], g[2], g[1] - g[0], FONDO - g[2]), false)
	for p in data["platforms"]:
		_add_block(Rect2(p[0], p[2], p[1], 8), true)
	if theme == "pueblo":
		# techos y toldos de los edificios: se camina por encima (el dibujo ya está en la calle de fondo); en el
		# canal no, porque ahí las casas se alejan
		for c in PuebloCasas.CASAS:
			for r in [c[4], c[5]]:
				if r.size() == 3 and (r[1] < PuebloCasas.CANAL[0] or r[0] > PuebloCasas.CANAL[1]):
					_add_ledge(r[0], r[1], r[2])
		var canal := Canal.new()
		canal.x0 = PuebloCasas.CANAL[0]
		canal.x1 = PuebloCasas.CANAL[1]
		canal.bajo = CALLE_Y + cam_y_max
		add_child(canal)

	player = Player.new()
	player.position = Vector2(60, 200)
	player.died.connect(_on_player_died)
	add_child(player)

	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	hud.level = self
	ui.add_child(hud)
	hud.banner_text = data["name"] + "\n¡VAMOS!"
	Game.play_music(data["music"])
	if _want_cine():
		_start_cine()


## Cinemática de llegada (1.1, el pueblo): la primera vez en la partida. La prueba automática solo la pone con
## el argumento "cine" (las demás pruebas empiezan jugando).
func _want_cine() -> bool:
	if theme != "pueblo" or Game.seen_cine.has("llegada"):
		return false
	return not Game.autoplay or "cine" in OS.get_cmdline_user_args()


func _start_cine() -> void:
	Game.seen_cine["llegada"] = true
	state = "cine"
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	hud.banner_text = ""
	add_child(CineLlegada.new())


## La cinemática termina (o se salta): el soldado aparece donde aterrizó y empieza la fase.
func end_cine(x: float) -> void:
	state = "play"
	player.position = Vector2(x, ground_y_at(x))
	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.invuln = 1.5
	hud.visible = true
	show_banner(data["name"] + "
¡VAMOS!", 2.5)


func _add_block(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8 if one_way else 1
	body.collision_mask = 0
	body.position = rect.position
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = rect.size
	cs.shape = sh
	cs.position = rect.size / 2
	cs.one_way_collision = one_way
	body.add_child(cs)
	var vis := Terrain.new()
	vis.size = rect.size
	vis.one_way = one_way
	vis.theme = theme
	body.add_child(vis)
	add_child(body)


## Saliente invisible que se atraviesa desde abajo (techos y toldos del pueblo, que ya están dibujados en el fondo).
func _add_ledge(x0: float, x1: float, y: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8
	body.collision_mask = 0
	body.position = Vector2(x0, y)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(x1 - x0, 6)
	cs.shape = sh
	cs.position = sh.size / 2
	cs.one_way_collision = true
	body.add_child(cs)
	add_child(body)


## Cuesta: tramo de suelo [x0, x1, y_inicio, y_fin] con colisión en polígono (el jugador y los
## enemigos suben y bajan andando; la pendiente no debe pasar de ~35°).
func _add_slope(g: Array) -> void:
	var w: float = g[1] - g[0]
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(g[0], 0)
	var cp := CollisionPolygon2D.new()
	cp.polygon = PackedVector2Array([Vector2(0, g[2]), Vector2(w, g[3]), Vector2(w, FONDO), Vector2(0, FONDO)])
	body.add_child(cp)
	var vis := Terrain.new()
	vis.size = Vector2(w, FONDO)
	vis.top0 = g[2]
	vis.top1 = g[3]
	vis.theme = theme
	body.add_child(vis)
	add_child(body)


func _physics_process(delta: float) -> void:
	if state == "cine":
		camera.position = Vector2.ZERO
		return
	if not player.dead:
		cam_left = clampf(maxf(cam_left, player.position.x - SCREEN_W * 0.4), 0.0, minf(boss_arena, lock_left))
		# en vertical sigue al suelo que hay bajo el jugador (no a sus saltos): al bajar la rampa del canal la
		# pantalla baja con él y al subir la otra vuelve a su sitio
		var want := clampf(ground_y_at(player.position.x) - CALLE_Y, 0.0, cam_y_max)
		cam_y = lerpf(cam_y, want, 1.0 - exp(-10.0 * delta))
		if absf(cam_y - want) < 0.3:
			cam_y = want
	shake_amt = maxf(shake_amt - 18.0 * delta, 0.0)
	camera.position = Vector2(roundf(cam_left), roundf(cam_y))
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake_amt
	player.cam_left = cam_left
	player.cam_y = cam_y

	_spawn_entities()
	if state == "play" and cam_left < boss_arena - 150:
		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = randf_range(1.0, 2.4)
			var from_left := randf() < 0.2
			var s := Soldier.new()
			s.dir = 1 if from_left else -1
			if not from_left and randf() < 0.15:
				s.mode = "grenadier"
			var sx: float = cam_left - 10 if from_left else cam_left + SCREEN_W + 10
			# entra corriendo por el suelo (no cae del cielo); sobre un foso, desde arriba como antes
			var gy := ground_y_at(sx)
			s.position = Vector2(sx, gy - 1.0 if gy < 900.0 else cam_y + 90.0)
			add_child(s)
	if boss and cam_left >= boss_arena - 1.0 and state == "play" and not boss_announced:
		boss_announced = true
		Game.play_music("boss")
		var title := "¡JEFE FINAL!" if data.get("boss_role", "final") == "final" else "¡MINI JEFE!"
		show_banner(title + "\n" + data["boss_name"], 2.0)
		reset_time()

	_tick_time(delta)
	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0 and state == "play":
			hud.banner_text = ""

	if state == "over":
		if Input.is_action_just_pressed("restart"):
			Game.retry_level()
		elif Input.is_action_just_pressed("quit_menu"):
			Game.to_menu()
	elif state == "clear" and banner_t <= 0.0 and Game.accept_pressed():
		Game.next_level()



func _spawn_entities() -> void:
	while next_entity < entities.size() and entities[next_entity][1] < cam_left + SCREEN_W + 40:
		var e: Array = entities[next_entity]
		next_entity += 1
		var n
		var pos := Vector2(e[1], e[2])
		match e[0]:
			"sniper", "grenadier":
				n = Soldier.new()
				n.mode = e[0]
			"turret":
				n = Turret.new()
			"barrel":
				n = Barrel.new()
			"mine":
				n = Mine.new()
			"tank":
				n = Tank.new()
				if e.size() > 3:
					n.kind = e[3]  # comunista, israeli o usa (si no, se alterna según la x)
			"miniboss":
				n = Miniboss.new()
				n.kind = e[3]
			"jet":
				n = Jet.new()
				pos = Vector2(cam_left + SCREEN_W + 40, cam_y + 26)
			"boss":
				var kind: String = e[3]
				if kind == "pol:massa":
					n = Massa.new()  # primer jefe con animaciones completas
				elif kind.begins_with("pol:"):
					n = Politician.new()
					n.id = kind.substr(4)
				else:
					match kind:
						"wall": n = Boss.new()
						"heli": n = Heli.new()
						_: n = Mecha.new()
				boss = n
			"vecino":
				n = Civilian.new()
				n.house = e[3]
			"door":
				n = Door.new()
				n.number = e[3]
			"caja":
				n = Caja.new()
				if e.size() > 3:
					n.alto = e[3]
			"tiempo":
				# control a mitad de fase: el reloj vuelve a 60
				reset_time()
				continue
			"capsule":
				n = Pickup.new()
				n.weapon = e[3]
				pos = Vector2(cam_left - 10, cam_y + e[2])
		n.position = pos
		add_child(n)


func ground_y_at(x: float) -> float:
	for g in ground:
		if x >= g[0] and x <= g[1]:
			if g.size() > 3:
				return lerpf(g[2], g[3], (x - g[0]) / maxf(1.0, g[1] - g[0]))
			return g[2]
	return 999.0


func safe_x(x: float) -> float:
	for g in ground:
		if x < g[0]:
			return g[0] + 20.0
		if x <= g[1] - 10:
			return x
	return x


## TIME: baja 1 cada TIME_TICK segundos; a 0 el jugador muere. Pitido en los últimos 10.
func _tick_time(delta: float) -> void:
	if state != "play" or player.dead:
		return
	time_acc += delta
	if time_acc < TIME_TICK:
		return
	time_acc -= TIME_TICK
	time_left -= 1
	if time_left <= 10 and time_left > 0:
		Game.sfx("beep", -10.0, 1.3)
	if time_left <= 0:
		player.hit(true)


func reset_time() -> void:
	time_left = START_TIME
	time_acc = 0.0


func show_banner(text: String, duration: float) -> void:
	if state == "play":
		hud.banner_text = text
		banner_t = duration


## Bloquea la cámara en x (mini jefe) hasta que se llame a unlock_camera().
func lock_camera(x: float, title: String) -> void:
	lock_left = x
	show_banner("¡ALERTA!\n" + title, 2.0)
	reset_time()
	Game.play_music("boss")


func unlock_camera() -> void:
	lock_left = INF
	show_banner("¡MINI JEFE DERROTADO!", 1.5)
	Game.play_music(data["music"])


func add_score(n: int) -> void:
	Game.add_score(n)


func shake(amount: float) -> void:
	shake_amt = minf(maxf(shake_amt, amount), 6.0)


## Efecto visual de explosión, con sonido y temblor proporcionales al tamaño.
## Granada enemiga: arco hasta target_x, con marca de aviso en el suelo (bomb.gd). Daña al jugador.
func throw_grenade(from: Vector2, target_x: float) -> void:
	var gy := ground_y_at(target_x)
	if gy > 900.0:
		gy = 262.0
	var vy := -230.0
	var g := 380.0
	var time := (-vy + sqrt(vy * vy + 2.0 * g * maxf(gy - from.y, 0.0))) / g
	var b := Bomb.new()
	b.target_x = target_x
	b.vel = Vector2((target_x - from.x) / time, vy)
	b.position = from
	add_child(b)


func explode(pos: Vector2, radius := 12.0, sound := true) -> void:
	var e := Explosion.new()
	e.position = pos
	e.r = radius
	add_child(e)
	Civilian.scare_all(get_tree(), pos)
	if sound:
		if radius >= 20.0:
			Game.sfx("boom", -4.0, randf_range(0.85, 1.1))
		else:
			Game.sfx("small_boom", -9.0, randf_range(0.9, 1.2))
	shake(radius * 0.12)


## Explosión que hace daño: a enemigos (si hurt_enemies) y objetos en el radio y, si hurt_player, al jugador.
## Las granadas y bombas enemigas no dañan a los suyos (hurt_enemies = false).
func blast(pos: Vector2, radius: float, hurt_player := true, damage := 5, hurt_enemies := true) -> void:
	explode(pos, radius)
	var targets := get_tree().get_nodes_in_group("prop")
	if hurt_enemies:
		targets += get_tree().get_nodes_in_group("enemy")
	for n in targets:
		if n.has_method("take_damage") and n.global_position.distance_to(pos) < radius + 8.0:
			n.call_deferred("take_damage", damage)
	if hurt_player and (player.position + Vector2(0, -10)).distance_to(pos) < radius * 0.75:
		player.hit()


func _on_player_died() -> void:
	Game.lives -= 1
	if Game.lives <= 0:
		state = "over"
		Game.save_record()
		Game.stop_music()
		hud.banner_text = "GAME OVER\nPuntos: %d\n\nEnter: reintentar   Q: menú" % Game.score
		return
	player.respawn(Vector2(safe_x(cam_left + 50), cam_y + 20))
	reset_time()


func stage_clear() -> void:
	if state != "play":
		return
	state = "clear"
	banner_t = 1.5
	Game.save_record()
	Game.stop_music()
	Game.sfx("pickup")
	var title := "¡FASE %s SUPERADA!" % data.get("phase", "")
	if data.get("boss_role", "") == "door":
		title = "¡PUERTA %s ABIERTA!" % data["phase"].substr(2)
	elif not Game.has_next_level():
		title = "¡APOCALIPSIS DETENIDO!"
	elif data.get("boss_role", "") == "final":
		title = "¡%s %s!" % [data["zone"], data["freed"]]
	hud.banner_text = "%s\nPuntos: %d   Récord: %d\n\nPulsa para ver el mapa" % [title, Game.score, Game.record]
