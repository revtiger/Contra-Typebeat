extends Node2D
## Jefe de la Misión 3: "La Presidenta Mecha" (personaje ficticio de parodia).
## Jefe por piezas estilo Metal Slug, con sprites de assets/sprites/mecha_* (tools/sprites/mecha.py).
## - Brazo ametralladora (se puede romper): ráfagas en abanico hacia el jugador
## - Dos cápsulas de misiles (se pueden romper): los misiles caen del cielo con marca de aviso
## - Pisotón: onda de choque rasante que hay que saltar
## - Torso: vida principal; la cabeza es el punto débil (daño doble)
## El origen del nodo está en el suelo, entre las patas.

const SpriteUtil = preload("res://scripts/sprite_util.gd")
const BossPart = preload("res://scripts/boss_part.gd")
const Bullet = preload("res://scripts/bullet.gd")
const Bomb = preload("res://scripts/bomb.gd")
const DIR := "res://assets/sprites/"

const HP := {"body": 220, "gatling": 30, "pod_front": 22, "pod_back": 22}

var main
var meta: Dictionary
var state := "wait"  # wait | enter | fight | dying
var hp := HP.duplicate()
var t := 0.0
var attack_t := 1.5
var pattern := 0
var burst_left := 0
var burst_t := 0.0
var stomp_t := -1.0
var die_t := 0.0
var bob := 0.0
var flash := {}
var parts := {}
var sprites := {}
var legs := []  # [upper, lower, pie, lado, es_trasera]


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	meta = SpriteUtil.meta(DIR + "mecha_meta.json")
	position = Vector2(main.boss_arena + 620, main.ground_y_at(main.level_end - 100))
	# patas traseras (más oscuras), luego delanteras
	for back in [true, false]:
		for side in [-1, 1]:
			var up := _sprite("leg_upper")
			var low := _sprite("leg_lower")
			if back:
				up.modulate = Color(0.55, 0.55, 0.6)
				low.modulate = Color(0.55, 0.55, 0.6)
			var foot := Vector2(side * (60 if back else 84), 0)
			legs.append([up, low, foot, side, back])
	sprites["hips"] = _sprite("hips")
	sprites["claw"] = _sprite("claw")
	sprites["torso"] = _sprite("torso")
	sprites["head"] = _sprite("head")
	sprites["pod_front"] = _sprite("pod")
	sprites["pod_back"] = _sprite("pod")
	sprites["gatling"] = _sprite("gatling0")
	sprites["claw"].modulate = Color(0.7, 0.7, 0.75)
	_part("body", sprites["torso"], Vector2(0, -34), Vector2(60, 62))
	_part("head", sprites["head"], Vector2(0, -20), Vector2(22, 30))
	_part("gatling", sprites["gatling"], Vector2(-30, 1), Vector2(72, 26))
	_part("pod_front", sprites["pod_front"], Vector2(0, -15), Vector2(26, 28))
	_part("pod_back", sprites["pod_back"], Vector2(0, -15), Vector2(26, 28))
	_layout()


func _sprite(piece: String) -> Sprite2D:
	var m: Dictionary = meta[piece]
	var s := SpriteUtil.part(DIR + "mecha_%s.png" % piece, SpriteUtil.v(m["pivot"]))
	add_child(s)
	return s


func _part(part_name: String, parent: Node2D, center: Vector2, size: Vector2) -> void:
	var b := BossPart.new()
	b.boss = self
	b.part_name = part_name
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = center
	b.add_child(cs)
	parent.add_child(b)
	parts[part_name] = b


## Coloca todas las piezas a partir del torso (con el balanceo) y resuelve las patas.
func _layout() -> void:
	var tor: Dictionary = meta["torso"]
	var piv := SpriteUtil.v(tor["pivot"])
	var hip_y := -88.0 + bob
	sprites["hips"].position = Vector2(0, hip_y)
	var torso_pos := Vector2(0, hip_y + 2)
	sprites["torso"].position = torso_pos
	var rel := func(key: String) -> Vector2: return torso_pos + SpriteUtil.v(tor[key]) - piv
	sprites["head"].position = rel.call("neck") + Vector2(0, 1)
	sprites["pod_front"].position = rel.call("pod_front")
	sprites["pod_back"].position = rel.call("pod_back")
	sprites["gatling"].position = rel.call("shoulder_front")
	sprites["claw"].position = rel.call("shoulder_back")
	sprites["claw"].rotation = sin(t * 1.3) * 0.12
	sprites["gatling"].rotation = _gatling_angle()
	var hips: Dictionary = meta["hips"]
	var hp_piv := SpriteUtil.v(hips["pivot"])
	for leg in legs:
		var side: int = leg[3]
		var joint := Vector2(0, hip_y) + SpriteUtil.v(hips["hip_back" if side > 0 else "hip_front"]) - hp_piv
		var foot: Vector2 = leg[2]
		if stomp_t >= 0.0 and side < 0 and not leg[4]:
			foot.y -= sin(clampf(stomp_t / 0.5, 0.0, 1.0) * PI) * 26.0
		var knee := joint.lerp(foot, 0.3) + Vector2(side * 22, -58)
		_bone(leg[0], joint, knee, meta["leg_upper"]["length"])
		_bone(leg[1], knee, foot, meta["leg_lower"]["length"])


func _bone(s: Sprite2D, a: Vector2, b: Vector2, length: float) -> void:
	var d := b - a
	s.position = a
	s.rotation = d.angle() - PI / 2.0
	s.scale.y = d.length() / length


## Ángulo del brazo ametralladora: apunta hacia el jugador (limitado).
func _gatling_angle() -> float:
	if main == null or main.player == null:
		return 0.0
	var g: Vector2 = sprites["gatling"].global_position
	var to: Vector2 = main.player.global_position + Vector2(0, -14) - g
	return clampf(Vector2.LEFT.angle_to(to), -0.9, 0.4)


func _physics_process(delta: float) -> void:
	t += delta
	for k in flash.keys():
		flash[k] -= delta
	var arena: float = main.boss_arena
	match state:
		"wait":
			if main.cam_left >= arena - 1.0:
				state = "enter"
				Game.sfx("boom", -6.0, 0.5)
		"enter":
			position.x = move_toward(position.x, arena + 350, 60.0 * delta)
			bob = sin(t * 6.0) * 2.0
			if int(t * 3.0) != int((t - delta) * 3.0):
				Juice.shake(2.0)
				Game.sfx("cannon", -10.0, 0.5)
			if position.x <= arena + 351:
				state = "fight"
		"fight":
			position.x = move_toward(position.x, arena + 350 + sin(t * 0.35) * 50.0, 20.0 * delta)
			bob = sin(t * 2.0) * 2.0
			_attack(delta)
		"dying":
			die_t -= delta
			bob = minf(bob + delta * 12.0, 30.0)
			if int(die_t * 8.0) != int((die_t + delta) * 8.0):
				main.explode(global_position + Vector2(randf_range(-60, 60), randf_range(-180, -40)), randf_range(12, 26))
			if die_t <= 0.0:
				main.blast(global_position + Vector2(0, -100), 70.0, false, 10)
				for i in 5:
					main.explode(global_position + Vector2(randf_range(-80, 80), randf_range(-160, -20)), randf_range(22, 36))
				Juice.hitstop(0.25)
				main.stage_clear()
				queue_free()
				return
	_layout()
	for k in sprites:
		var hit_key: String = "body" if k in ["torso", "hips"] else k
		if flash.get(hit_key, 0.0) > 0.0:
			sprites[k].modulate = Color(4, 4, 4)
		elif k != "claw":
			sprites[k].modulate = Color.WHITE if state != "dying" else Color(0.6, 0.5, 0.5)
	queue_redraw()


func _attack(delta: float) -> void:
	var p = main.player
	if p.dead:
		return
	if stomp_t >= 0.0:
		stomp_t += delta
		if stomp_t >= 0.5:
			stomp_t = -1.0
			_stomp_impact()
		return
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_t = 0.09
			burst_left -= 1
			var g: Sprite2D = sprites["gatling"]
			g.texture = load(DIR + ("mecha_gatling%d.png" % (burst_left % 2)))
			var muzzle: Vector2 = g.to_global(SpriteUtil.v(meta["gatling0"]["muzzle"]) - SpriteUtil.v(meta["gatling0"]["pivot"]))
			var dir: Vector2 = (p.global_position + Vector2(0, -14) - muzzle).normalized().rotated(sin(burst_left * 0.7) * 0.18)
			var b := Bullet.new()
			b.from_player = false
			b.life = 4.0
			b.vel = dir * 150.0
			b.position = muzzle
			main.add_child(b)
			Game.sfx("shot", -16.0, 0.8)
		return
	attack_t -= delta
	if attack_t > 0.0:
		return
	var ratio := float(hp["body"]) / HP["body"]
	attack_t = lerpf(0.7, 1.6, ratio)
	var options := ["stomp"]
	if hp["gatling"] > 0:
		options.append("gatling")
	if hp["pod_front"] > 0 or hp["pod_back"] > 0:
		options.append("missiles")
	pattern = (pattern + 1) % options.size()
	match options[pattern]:
		"gatling":
			burst_left = 12
		"missiles":
			_missiles(p.global_position.x)
		"stomp":
			stomp_t = 0.0
			Game.sfx("jet", -8.0, 1.6)


func _missiles(target_x: float) -> void:
	var offsets := []
	if hp["pod_front"] > 0:
		offsets += [-70.0, -30.0, 10.0]
	if hp["pod_back"] > 0:
		offsets += [-10.0, 30.0, 70.0]
	for pod in ["pod_front", "pod_back"]:
		if hp[pod] <= 0:
			continue
		var launch: Vector2 = sprites[pod].global_position + Vector2(0, -30)
		for i in 3:
			var m := SpriteUtil.part(DIR + "mecha_missile.png", SpriteUtil.v(meta["missile"]["pivot"]))
			m.position = launch + Vector2(i * 6 - 6, 0)
			main.add_child(m)
			var tw := m.create_tween()
			tw.tween_property(m, "position:y", -40.0, 0.5 + i * 0.08)
			tw.tween_callback(m.queue_free)
	Game.sfx("fire", -4.0, 1.4)
	for o in offsets:
		var b := Bomb.new()
		b.target_x = target_x + o
		b.position = Vector2(target_x + o, -30.0 - randf() * 40.0)
		main.add_child(b)


func _stomp_impact() -> void:
	Juice.shake(5.0)
	Game.sfx("boom", -4.0, 0.6)
	var foot: Vector2 = global_position + legs[2][2]
	for leg in legs:
		if leg[3] < 0 and not leg[4]:
			foot = global_position + leg[2]
	main.explode(foot + Vector2(0, -4), 14.0, false)
	var b := Bullet.new()
	b.from_player = false
	b.kind = "shell"
	b.vel = Vector2(-180.0, 0.0)
	b.position = foot + Vector2(-8, -7)
	main.add_child(b)


func part_damage(part_name: String, n: int) -> void:
	if state != "fight":
		return
	var key := "body" if part_name == "head" else part_name
	if hp[key] <= 0:
		return
	hp[key] -= n * (2 if part_name == "head" else 1)
	flash[key] = 0.05
	if part_name == "head":
		flash["head"] = 0.05
	Game.sfx("hit", -18.0, 0.7)
	if hp[key] <= 0:
		_break(key)


func _break(key: String) -> void:
	if key == "body":
		state = "dying"
		die_t = 2.8
		main.add_score(20000)
		Game.sfx("boom", 0.0, 0.6)
		Juice.hitstop(0.15)
		Juice.shake(6.0)
		for k in parts:
			parts[k].queue_free()
		parts.clear()
		return
	main.add_score(2500)
	var s: Sprite2D = sprites[key]
	main.blast(s.global_position + Vector2(0, -12), 30.0, false, 0)
	main.explode(s.global_position + Vector2(-10, -20), 18.0, false)
	Juice.hitstop(0.08)
	s.visible = false
	parts[key].queue_free()
	parts.erase(key)


func _draw() -> void:
	if state != "fight":
		return
	var y := -205.0
	draw_rect(Rect2(-50, y, 100, 5), Color(0.2, 0, 0))
	draw_rect(Rect2(-50, y, 100.0 * hp["body"] / HP["body"], 5), Color(1, 0.25, 0.2))
