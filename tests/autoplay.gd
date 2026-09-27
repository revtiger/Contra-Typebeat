extends Node
## Prueba automática: juega sola y guarda capturas. La añade Game cuando se arranca con "autoplay".
##
## Uso:
##   godot --path . -- autoplay out=<carpeta> [level=0|1] [boss] [scene=intro]
## - level: misión a jugar (0 = jungla, 1 = desierto)
## - boss: empieza justo antes del jefe
## - scene=intro: no juega; solo captura la intro y el menú
## El jugador es invencible (salvo al caer a un foso) y la partida termina al completar la misión.

var out_dir := "user://shots"
var level_idx := 0
var boss := false
var only_intro := false
var frame := 0
var level_frame := 0
var last_scene = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out_dir = a.substr(4)
		elif a.begins_with("level="):
			level_idx = int(a.substr(6))
		elif a == "boss":
			boss = true
		elif a == "scene=intro":
			only_intro = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	if not only_intro:
		Game.start_game.call_deferred(level_idx)


func _shot(tag: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s_%04d.png" % [out_dir, tag, frame])


func _physics_process(_delta: float) -> void:
	frame += 1
	if only_intro:
		if frame % 60 == 0 and frame < 840:
			_shot("intro")
		if frame == 880:
			Input.action_press("down")
		if frame == 882:
			Input.action_release("down")
		if frame > 900:
			_shot("menu")
			get_tree().quit()
		return

	var lvl = get_tree().current_scene
	if lvl != null and lvl.is_in_group("map"):
		# mapa: captura y pulsar para continuar
		if frame % 150 == 100:
			_shot("mapa")
		if frame % 150 == 120:
			Input.action_press("restart")
		elif frame % 150 == 125:
			Input.action_release("restart")
		return
	if lvl != null and lvl.name == "Menu":
		_shot("menu_final")
		print("FIN: vuelta al menú. puntos=%d" % Game.score)
		get_tree().quit()
		return
	if lvl == null or not lvl.is_in_group("level"):
		return
	if lvl != last_scene:
		last_scene = lvl
		level_frame = 0
	level_frame += 1
	var p = lvl.player
	if level_frame == 3 and boss:
		p.position = Vector2(lvl.boss_arena - 60, 150)
		lvl.cam_left = lvl.boss_arena - 300
	p.invuln = 1.0
	Game.lives = 3
	var at_boss: bool = lvl.cam_left >= lvl.boss_arena - 1.0
	var heli: bool = at_boss and is_instance_valid(lvl.boss) and lvl.boss.get("state") != null
	if heli:
		# helicóptero: seguirlo por debajo y disparar hacia arriba
		var dx: float = lvl.boss.position.x - p.position.x
		Input.action_press("up")
		if absf(dx) > 12.0:
			Input.action_press("right" if dx > 0 else "left")
			Input.action_release("left" if dx > 0 else "right")
		else:
			Input.action_release("left")
			Input.action_release("right")
	elif lvl.lock_left < INF:
		# mini jefe: acercarse hasta ~60 px y quedarse mirándolo
		var mb = null
		for n in get_tree().get_nodes_in_group("enemy"):
			if n.get("home_x") != null:
				mb = n
		Input.action_release("left")
		Input.action_release("right")
		if mb:
			var mdx: float = mb.position.x - p.position.x
			if absf(mdx) > 60.0 or signf(mdx) != float(p.facing):
				Input.action_press("right" if mdx > 0 else "left")
	elif at_boss:
		# muro: quedarse quieto disparando a la derecha
		Input.action_release("right")
		Input.action_release("left")
	else:
		Input.action_press("right")
	Input.action_press("shoot")
	if level_frame % 50 == 0:
		Input.action_press("jump")
	elif level_frame % 50 == 25:
		Input.action_release("jump")
	if not heli:
		if level_frame % 200 > 150:
			Input.action_press("up")
		else:
			Input.action_release("up")
	if level_frame % 120 == 0:
		_shot("nivel%d" % Game.level)
		var boss_info := ""
		if is_instance_valid(lvl.boss) and lvl.cam_left >= lvl.boss_arena - 1.0:
			boss_info = "  jefe=%s vida=%d pos=%s" % [lvl.boss.get("state"), lvl.boss.hp, lvl.boss.position.round()]
		print("frame %d  x=%.0f cam=%.0f puntos=%d estado=%s arma=%s%s" % [
			level_frame, p.position.x, lvl.cam_left, Game.score, lvl.state, p.weapon, boss_info])
	if lvl.state == "clear" and "campaign" in OS.get_cmdline_user_args():
		# modo campaña: seguir a la siguiente misión pasando por el mapa
		if level_frame % 60 == 0:
			Input.action_press("restart")
		elif level_frame % 60 == 5:
			Input.action_release("restart")
		return
	if lvl.state == "clear" or level_frame > 9000:
		_shot("final")
		print("FIN: estado=%s puntos=%d frames=%d" % [lvl.state, Game.score, level_frame])
		get_tree().quit()
