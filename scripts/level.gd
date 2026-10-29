extends Node2D
## Escena de una misión: construye el nivel desde levels.gd, cámara, HUD, explosiones y estado de la partida.

const Levels = preload("res://scripts/levels.gd")
const Player = preload("res://scripts/player.gd")
const CineLlegada = preload("res://scripts/cinematica_llegada.gd")
const Soldier = preload("res://scripts/soldier.gd")
const Turret = preload("res://scripts/turret.gd")
const Boss = preload("res://scripts/boss.gd")
const Heli = preload("res://scripts/heli.gd")
const Helicoptero = preload("res://scripts/helicoptero.gd")
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
const Greybox = preload("res://scripts/greybox.gd")
const Edificios = preload("res://scripts/edificios.gd")
const JumpHitbox = preload("res://scripts/jump_hitbox.gd")
const TiradorVentana = preload("res://scripts/tirador_ventana.gd")
const Zona = preload("res://scripts/zona.gd")
const Caja = preload("res://scripts/caja.gd")
const PuebloCasas = preload("res://scripts/pueblo_casas.gd")
const Canal = preload("res://scripts/canal.gd")
const Estacion = preload("res://scripts/estacion.gd")
const Tren = preload("res://scripts/tren.gd")
## En altura: de pie en una plataforma a ALTURA_MIN px o más sobre la calle. Arriba salen ALTURA_SPAWN veces
## menos soldados por la calle, pero hay emboscadas (ventana o asaltante desde arriba) cada EMBOSCADA_T s
const ALTURA_MIN := 80.0
const ALTURA_SPAWN := 4.0
const EMBOSCADA_T := Vector2(4.0, 7.0)
const ModoTest = preload("res://scripts/modo_test.gd")
## Lo que no aparece solo en el greybox del modo test (enemigos y cápsulas): se sacan con F2, F3 y F4 (modo_test.gd)
const TEST_SKIP := ["sniper", "grenadier", "turret", "tank", "miniboss", "jet", "boss", "capsule"]

const SCREEN_W := 480.0
const SCREEN_H := 270.0
## Cámara vertical: sube CAM_UP de lo que el jugador está por encima del suelo (al saltar se ve lo de arriba),
## suavizado con CAM_LERP
const CAM_UP := 0.8
const CAM_LERP := 8.0
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
## Cámara vertical (cam_y = borde de arriba): baja con el suelo (cam_bajada, el canal de la 1.1: el jugador se ve
## siempre a la misma altura; hasta cam_y_max, 0 en las fases donde no se mueve) y sube al saltar o subirse a algo
## (cam_subida)
var cam_y := 0.0
var cam_y_max := 0.0
var cam_bajada := 0.0
var cam_subida := 0.0
## Mundo del greybox (F1 en modo test): la fase con los datos de "greybox" de su plantilla (edificios, jump hitbox,
## museo…) en vez del escenario del juego (levels.gd). Sin datos propios es la misma fase vista en bloques.
var mundo_greybox := false
## edificios del greybox (scripts/edificios.gd), si la fase tiene semilla "buildings"
var buildings: Array = []
## todas las plataformas de la fase: las de la plantilla y las de los edificios ([x, ancho, y])
var platforms: Array = []
var shake_amt := 0.0
var lock_left := INF
## Borde izquierdo mínimo de la cámara: 0, o la arena cuando un jefe la bloquea por los dos lados
var cam_min := 0.0
var boss_announced := false
var state := "play"  # cine | play | over | clear
var spawn_t := 2.5
var next_entity := 0
var hud := Hud.new()
var time_left := START_TIME
var time_acc := 0.0
var banner_t := 2.5
var test_boss := false  # modo test: hay un jefe sacado con F3 vivo
var en_altura := false
var emboscadas := not Game.test  # en modo test se activan con F9
var emboscada_t := 2.0


func _ready() -> void:
	add_to_group("level")
	add_to_group("main")
	data = Levels.LIST[Game.level]
	if Game.route.has("interior"):
		data = Levels.interior(Game.route["interior"], data)  # dentro de un edificio grande (zona.gd)
	mundo_greybox = Game.greybox
	if mundo_greybox and data.has("greybox"):
		data = data.merged(data["greybox"], true)
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

	# las cuestas después de los tramos llanos: su dibujo puede pasarse por encima del tramo de al lado (el pilar de
	# la esquina de las rampas del canal)
	for g in ground:
		if not (g.size() > 3 and g[3] != g[2]):
			_add_block(Rect2(g[0], g[2], g[1] - g[0], FONDO - g[2]), false)
	for g in ground:
		if g.size() > 3 and g[3] != g[2]:
			_add_slope(g)
	for p in data["platforms"]:
		_add_block(Rect2(p[0], p[2], p[1], 8), true)
	platforms = data["platforms"].duplicate()
	if data.get("buildings", -1) >= 0:
		# apoyan detrás de la vereda (23 px sobre el suelo, como las casas del pueblo)
		buildings = Edificios.generar(data["buildings"], 0.0, level_end, ground_y_at(0.0) - 23.0, ground_y_at(0.0),
			data.get("big", {}))
		for b in buildings:
			for p in b["plataformas"]:
				_add_block(Rect2(p[0], p[2], p[1], 8), true)
				platforms.append(p)
			for s in b["saltos"]:
				var j := JumpHitbox.new()
				j.position = Vector2(s[0], s[1])
				add_child(j)
			if b["tipo"] == "grande":
				_add_zona("puerta", b["x"] + b["w"] / 2.0, Vector2(40, 62), "ENTRAR: ARRIBA", b["interior"])
	if data.get("interior", false):
		_add_zona("salida", level_end - 40.0, Vector2(32, 80), "SALIDA")
	if theme == "pueblo" and not mundo_greybox:
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
		# estación del tren: la señal y la barrera van en la pantalla fija del tren (la x de la entidad "tren")
		var estacion := Estacion.new()
		estacion.x0 = PuebloCasas.ESTACION[0]
		estacion.x1 = PuebloCasas.ESTACION[1]
		for e in entities:
			if e[0] == "tren":
				estacion.lock_x = e[1]
		add_child(estacion)

	player = Player.new()
	player.position = Vector2(60, 200)
	player.died.connect(_on_player_died)
	add_child(player)
	if not Game.carry.is_empty():
		player.apply_carry(Game.carry)  # viene de la calle o de un interior
		Game.carry = {}

	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()

	# modo bloques (F1): encima del mundo y debajo del HUD
	var greybox := Greybox.new()
	greybox.level = self
	add_child(greybox)
	if Game.test:
		var modo_test := ModoTest.new()
		modo_test.level = self
		add_child(modo_test)

	var ui := CanvasLayer.new()
	add_child(ui)
	hud.level = self
	ui.add_child(hud)
	hud.banner_text = data["name"] + "\n¡VAMOS!"
	Game.play_music(data["music"])
	if _want_cine():
		_start_cine()
	if Game.route.has("vuelta_x"):
		_volver_de_interior(Game.route["vuelta_x"])
	elif Game.route.has("f1_x"):
		_volver_tras_f1(Game.route["f1_x"])


## Cinemática de llegada (1.1, el pueblo): la primera vez en la partida. La prueba automática solo la pone con
## el argumento "cine" (las demás pruebas empiezan jugando).
func _want_cine() -> bool:
	if theme != "pueblo" or Game.seen_cine.has("llegada") or Game.test or not Game.route.is_empty():
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
	# Terreno (capa 1); las plataformas que se atraviesan desde abajo van en el grupo "plataforma"
	body.collision_layer = 1
	body.collision_mask = 0
	if one_way:
		body.add_to_group("plataforma")
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
	# Terreno (capa 1) que se atraviesa desde abajo, como las plataformas (ARQUITECTURA.md, ARQ-11)
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("plataforma")
	body.position = Vector2(x0, y)
	platforms.append([x0, x1 - x0, y])
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
		# cámara centrada en el jugador (se puede retroceder, estilo Cuphead); al principio y al final de la
		# fase se queda en el borde y el jugador se mueve libre por esa mitad de pantalla
		cam_left = clampf(player.position.x - SCREEN_W * 0.5, cam_min, minf(boss_arena, lock_left))
		var gy := ground_y_at(player.position.x)
		var suelo := gy if gy < 900.0 else CALLE_Y
		# baja con el suelo que hay bajo el jugador (no con sus saltos): al bajar la rampa del canal la pantalla
		# baja con él y al subir la otra vuelve a su sitio
		var want := clampf(suelo - CALLE_Y, 0.0, cam_y_max)
		cam_bajada = lerpf(cam_bajada, want, 1.0 - exp(-10.0 * delta))
		if absf(cam_bajada - want) < 0.3:
			cam_bajada = want
		# al saltar (o subido a algo) sube parte de lo que sube el jugador
		var alto := clampf(suelo - player.position.y, 0.0, 200.0)
		cam_subida = lerpf(cam_subida, alto * CAM_UP, 1.0 - exp(-CAM_LERP * delta))
		cam_y = cam_bajada - cam_subida
	shake_amt = maxf(shake_amt - 18.0 * delta, 0.0)
	camera.position = Vector2(roundf(cam_left), roundf(cam_y))
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * shake_amt
	player.cam_left = cam_left
	player.cam_y = cam_y

	_spawn_entities()
	if state == "play" and not player.dead and mundo_greybox:
		_update_altura(delta)  # azoteas y emboscadas: solo en el mundo del greybox
	if state == "play" and not (Game.test and mundo_greybox) and cam_left < boss_arena - 150:
		spawn_t -= delta
		if spawn_t <= 0.0:
			spawn_t = randf_range(1.0, 2.4) * (ALTURA_SPAWN if en_altura else 1.0)
			var from_left := randf() < 0.2
			spawn_soldier(from_left, not from_left and randf() < 0.15)
	if boss and cam_left >= boss_arena - 1.0 and state == "play" and not boss_announced:
		boss_announced = true
		cam_min = boss_arena  # la arena se cierra por los dos lados hasta que cae el jefe
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
		if Game.test and mundo_greybox and e[0] in TEST_SKIP and not data.get("interior", false):
			continue
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
			"tren":
				n = Tren.new()  # se queda esperando a que la cámara llegue a su x (tren.gd)
			"helicoptero":
				n = Helicoptero.new()  # se pone solo a la derecha de la pantalla, arriba
			"jet":
				n = Jet.new()
				pos = Vector2(cam_left + SCREEN_W + 40, cam_y + 26)
			"boss":
				n = _make_boss(e[3])
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
				spawn_capsule(e[3], e[2])
				continue
		n.position = pos
		add_child(n)


## Jefe de la fase según su tipo ("pol:<id>", "wall", "heli" o "mecha"); queda como level.boss.
func _make_boss(kind: String):
	var n
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
	return n


## Soldado corredor (o granadero) que entra corriendo por un lado de la pantalla: los que salen solos y los
## de F2 en modo test.
func spawn_soldier(from_left: bool, grenadier := false) -> void:
	var s := Soldier.new()
	s.dir = 1 if from_left else -1
	if grenadier:
		s.mode = "grenadier"
	var sx: float = cam_left - 10 if from_left else cam_left + SCREEN_W + 10
	# entra corriendo por el suelo (no cae del cielo); sobre un foso, desde arriba como antes
	var gy := ground_y_at(sx)
	s.position = Vector2(sx, gy - 1.0 if gy < 900.0 else cam_y + 90.0)
	add_child(s)


## Zona (capa 7, zona.gd) apoyada en el suelo en x.
func _add_zona(tipo: String, x: float, size: Vector2, etiqueta: String, interior := "") -> void:
	var z := Zona.new()
	z.tipo = tipo
	z.size = size
	z.etiqueta = etiqueta
	z.interior = interior
	z.position = Vector2(x, ground_y_at(x))
	add_child(z)


## Puerta de un edificio grande: al interior (otra escena con los datos de Levels.INTERIORES).
func enter_interior(id: String) -> void:
	if state != "play":
		return
	state = "ruta"  # no vuelve a entrar mientras cambia la escena
	Game.sfx("select", -6.0)
	Game.go_route({"interior": id, "salida": data["big"]["salida"]}, player)


## Final del interior: de vuelta a la calle, más adelante (el atajo), con la recompensa de puntos.
func exit_interior() -> void:
	if state != "play":
		return
	state = "ruta"
	Game.add_score(5000)
	Game.sfx("pickup")
	Game.go_route({"vuelta_x": Game.route["salida"]}, player)


## De vuelta del interior: el héroe aparece en x, la cámara con él, y lo que queda detrás ya no sale.
func _volver_de_interior(x: float) -> void:
	Game.route = {}
	player.position = Vector2(x, ground_y_at(x) - 1.0)
	cam_left = clampf(x - SCREEN_W * 0.5, 0.0, boss_arena)
	while next_entity < entities.size() and entities[next_entity][1] < x:
		next_entity += 1
	show_banner("¡ATAJO! +5000", 2.0)


## Modo test (F1): cambia entre el juego y el mundo del greybox recargando la fase en la misma x, con el mismo
## estado del héroe (Game.carry). Dentro de un interior sigue dentro.
func cambiar_mundo() -> void:
	if state != "play":
		return
	state = "ruta"
	Game.greybox = not Game.greybox
	var r := Game.route.duplicate()
	r["f1_x"] = player.position.x
	Game.go_route(r, player)


## Tras F1: el héroe aparece donde estaba y lo que queda detrás ya no sale.
func _volver_tras_f1(x: float) -> void:
	Game.route.erase("f1_x")
	player.position = Vector2(x, ground_y_at(x) - 1.0)
	cam_left = clampf(x - SCREEN_W * 0.5, 0.0, boss_arena)
	while next_entity < entities.size() and entities[next_entity][1] < x:
		next_entity += 1
	show_banner("GREYBOX" if mundo_greybox else "JUEGO", 1.0)


## En altura (de pie en una plataforma alta; en el aire no cambia) y emboscadas mientras se está arriba.
func _update_altura(delta: float) -> void:
	if player.is_on_floor():
		en_altura = player._bridge_below() != null and ground_y_at(player.position.x) - player.position.y >= ALTURA_MIN
	if not en_altura or not emboscadas or cam_min > 0.0:
		emboscada_t = maxf(emboscada_t, 2.0)  # al subir, la primera tarda un poco
		return
	emboscada_t -= delta
	if emboscada_t <= 0.0:
		emboscada_t = randf_range(EMBOSCADA_T.x, EMBOSCADA_T.y)
		var tipos := ["ventana", "asalto"]
		tipos.shuffle()
		for t in tipos:
			if (t == "ventana" and _emboscada_ventana()) or (t == "asalto" and _emboscada_asalto()):
				return


## Un soldado se asoma por una ventana en pantalla, ni pegada al héroe ni muy lejos de su altura.
func _emboscada_ventana() -> bool:
	var p: Vector2 = player.position
	var candidatas := []
	for b in buildings:
		if b["x"] + b["w"] < cam_left or b["x"] > cam_left + SCREEN_W:
			continue
		for v in Edificios.ventanas(b):
			var c: Vector2 = v.get_center()
			if absf(c.x - p.x) > 70.0 and c.x > cam_left + 20.0 and c.x < cam_left + SCREEN_W - 20.0 \
					and c.y > cam_y + 40.0 and c.y < cam_y + SCREEN_H - 30.0 and absf(c.y - (p.y - 20.0)) < 120.0:
				candidatas.append(v)
	if candidatas.is_empty():
		return false
	var t := TiradorVentana.new()
	t.ventana = candidatas.pick_random()
	add_child(t)
	return true


## Un asaltante cae desde arriba en el mismo techo que el héroe, a un lado de él.
func _emboscada_asalto() -> bool:
	var techo = player._bridge_below()
	if techo == null:
		return false
	var ancho: float = techo.get_child(0).shape.size.x
	var x0: float = techo.position.x + 10.0
	var x1: float = techo.position.x + ancho - 10.0
	var lado := 1.0 if randf() < 0.5 else -1.0
	var x := clampf(player.position.x + lado * randf_range(28.0, 44.0), x0, x1)
	if absf(x - player.position.x) < 16.0:
		x = clampf(player.position.x - lado * 36.0, x0, x1)
	var s := Soldier.new()
	s.mode = "asalto"
	s.position = Vector2(x, techo.position.y)
	add_child(s)
	return true


## Modo test (F2 al azar, F7 granadero, F8 francotirador): soldado que entra corriendo por la derecha, se
## planta dentro de la pantalla y ataca como los del nivel.
func test_spawn_enemy(mode := "") -> void:
	var s := Soldier.new()
	s.mode = mode if mode != "" else ("sniper" if randf() < 0.5 else "grenadier")
	s.dir = -1
	s.state = "enter"
	s.plant_x = cam_left + randf_range(280.0, 440.0)
	var sx: float = cam_left + SCREEN_W + 10
	var gy := ground_y_at(sx)
	s.position = Vector2(sx, gy - 1.0 if gy < 900.0 else ground_y_at(cam_left + SCREEN_W - 1) - 1.0)
	add_child(s)


## Cápsula voladora que entra por la izquierda y suelta el arma (H, R, F, L, S) o bombas (B) al dispararle.
func spawn_capsule(weapon: String, y := 60.0) -> void:
	var c := Pickup.new()
	c.weapon = weapon
	c.position = Vector2(cam_left - 10, cam_y + y)  # y en la pantalla (la cámara baja en el canal)
	add_child(c)


## Modo test (F3): el jefe de la fase aparece aquí mismo. La pantalla actual pasa a ser su arena (la cámara se
## queda quieta) hasta que muere; entonces la fase sigue en vez de terminar (stage_clear).
func test_spawn_boss() -> void:
	if test_boss:
		show_banner("YA HAY UN JEFE", 1.0)
		return
	var kind := ""
	for e in data["entities"]:
		if e[0] == "boss":
			kind = e[3]
	if kind == "":
		show_banner("ESTA FASE NO TIENE JEFE", 1.0)
		return
	test_boss = true
	boss_arena = cam_left
	boss_announced = false
	var n = _make_boss(kind)
	n.position = Vector2(cam_left + SCREEN_W - 110, ground_y_at(cam_left + SCREEN_W - 110))
	add_child(n)


## ¿Hay Terreno (capa 1) en pos? Las plataformas solo cuentan al caer sobre ellas (se atraviesan desde abajo).
## Lo usan las granadas para explotar al tocar suelo, paredes o plataformas.
func touches_terrain(pos: Vector2, rising: bool) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = pos
	q.collision_mask = 1
	for hit in get_world_2d().direct_space_state.intersect_point(q, 8):
		if not (rising and hit["collider"].is_in_group("plataforma")):
			return true
	return false


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
	cam_min = minf(x, cam_left)  # no deja volver atrás mientras dura el mini jefe
	show_banner("¡ALERTA!\n" + title, 2.0)
	reset_time()
	Game.play_music("boss")


func unlock_camera(texto := "¡MINI JEFE DERROTADO!") -> void:
	lock_left = INF
	cam_min = 0.0
	show_banner(texto, 1.5)
	Game.play_music(data["music"])


func add_score(n: int) -> void:
	Game.add_score(n)


func shake(amount: float) -> void:
	shake_amt = minf(maxf(shake_amt, amount), 6.0)


## Efecto visual de explosión, con sonido y temblor proporcionales al tamaño.
## Granada enemiga: arco hasta target_x, con marca de aviso en el suelo (bomb.gd). Daña al jugador. Una de cada
## cuatro (Bomb.PARRY_CHANCE) parpadea en blanco y se puede devolver golpeándola a tiempo.
func throw_grenade(from: Vector2, target_x: float) -> void:
	var gy := ground_y_at(target_x)
	if gy > 900.0:
		gy = 262.0
	# 25-10-2026: ×1,25 la velocidad y ×1,25² la gravedad (antes -230 y 380): mismo arco, llega antes
	var vy := -288.0
	var g := 594.0
	var time := (-vy + sqrt(vy * vy + 2.0 * g * maxf(gy - from.y, 0.0))) / g
	var b := Bomb.new()
	b.target_x = target_x
	b.vel = Vector2((target_x - from.x) / time, vy)
	b.gravity = g
	b.parryable = randf() < Bomb.PARRY_CHANCE
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
	player.respawn(Vector2(safe_x(cam_left + SCREEN_W * 0.5), cam_y + 20))  # en el centro, donde mira la cámara
	reset_time()


func stage_clear() -> void:
	if state != "play":
		return
	if Game.test:
		# modo test: el jefe de F3 cae pero la fase sigue; la cámara vuelve a avanzar
		if test_boss:
			test_boss = false
			boss = null
			boss_arena = level_end - SCREEN_W
			cam_min = 0.0
			show_banner("¡JEFE DERROTADO!", 1.5)
			Game.play_music(data["music"])
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
