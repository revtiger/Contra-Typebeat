extends CharacterBody2D
## Jefe político (caricatura, historia "ONU: Trying to save the world").
## Cada fase termina con uno: minijefe en X.1 y X.2, jefe final en X.3.
## Sprite estático de PixelLab (assets/sprites/pol_<id>.png, mirando a la izquierda) animado por código.
## Espera fuera de pantalla, entra andando cuando la cámara llega a la arena, pelea y al morir
## "recibe su merecido": sale volando dando vueltas (sin gore). Luego:
##   - normal: main.stage_clear()
##   - transform = "mecha": se transfigura en la Presidenta Mecha (mecha.gd)
##   - after = "ritual": aparecen los jefes finales, pentagrama y fusión (ritual.gd)
## Las habilidades son PROVISIONALES: combinaciones de ataques genéricos hasta definirlas en historia.md.
## Ojo: no tiene variable "state" a propósito (la prueba automática trata así al jefe como uno de suelo).

const Bullet = preload("res://scripts/bullet.gd")
const Bomb = preload("res://scripts/bomb.gd")
const Soldier = preload("res://scripts/soldier.gd")
const DIR := "res://assets/sprites/"

## id: {name, hp, attacks, final?, transform?, after?, float?}
## Ataques: burst (ráfaga a la altura del pecho), spread (abanico), lob (granadas en arco),
## rain (bombas del cielo con aviso), minions (soldados), dash (embestida), wave (onda rasante: saltar),
## hop (salto y abanico al caer)
const POLS := {
	"massa": {"name": "SERGIO MASSA", "hp": 55, "attacks": ["spread", "minions", "burst"]},
	"kirchner": {"name": "CRISTINA KIRCHNER", "hp": 65, "attacks": ["rain", "burst", "lob"]},
	"milei": {"name": "JAVIER MILEI", "hp": 110, "attacks": ["dash", "wave", "spread", "rain"], "final": true},
	"amlo": {"name": "AMLO", "hp": 60, "attacks": ["lob", "burst", "minions"]},
	"salinas": {"name": "CARLOS SALINAS DE GORTARI", "hp": 65, "attacks": ["rain", "spread", "minions"]},
	"sheinbaum": {"name": "CLAUDIA SHEINBAUM", "hp": 60, "attacks": ["spread", "lob", "burst"], "final": true, "transform": "mecha"},
	"biden": {"name": "JOE BIDEN", "hp": 65, "attacks": ["wave", "burst", "lob"]},
	"obama": {"name": "BARACK OBAMA", "hp": 70, "attacks": ["hop", "spread", "burst"]},
	"trump": {"name": "DONALD TRUMP", "hp": 130, "attacks": ["rain", "dash", "minions", "burst", "spread"], "final": true},
	"merkel": {"name": "ANGELA MERKEL", "hp": 70, "attacks": ["burst", "lob", "wave"]},
	"scholz": {"name": "OLAF SCHOLZ", "hp": 75, "attacks": ["wave", "spread", "minions"]},
	"merz": {"name": "FRIEDRICH MERZ", "hp": 130, "attacks": ["dash", "rain", "burst", "spread"], "final": true},
	"lider": {"name": "LÍDER DE LA ORDEN MUNDIAL", "hp": 110, "attacks": ["spread", "rain", "minions", "hop"], "final": true, "after": "ritual"},
	"fusion": {"name": "LA ORDEN FUSIONADA", "hp": 260, "attacks": ["spread", "rain", "wave", "burst", "minions"], "final": true, "float": true},
}

var id := "massa"
var data: Dictionary
var main
var sprite := Sprite2D.new()
var size := Vector2(40, 90)
var phase := "wait"  # wait | enter | fight | dash | dying
var hp := 60
var max_hp := 60
var t := 0.0
var attack_t := 1.2
var pattern := -1
var burst_left := 0
var burst_t := 0.0
var flash := 0.0
var dir := -1
var home_x := 0.0
var dash_t := 0.0
var dash_target := 0.0
var die_t := 0.0
var hop_air := false
var floating := false
var base_y := 0.0


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	data = POLS[id]
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	floating = data.get("float", false)
	max_hp = data["hp"]
	hp = max_hp
	var tex: Texture2D = load(DIR + "pol_%s.png" % id)
	sprite.texture = tex
	sprite.centered = false
	size = tex.get_size()
	sprite.offset = Vector2(-size.x / 2.0, -size.y)
	add_child(sprite)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(size.x * 0.55, size.y * 0.85)
	cs.shape = r
	cs.position = Vector2(0, -r.size.y / 2.0)
	add_child(cs)
	var arena: float = main.boss_arena
	home_x = arena + 370.0
	base_y = main.ground_y_at(main.level_end - 100)
	if phase == "wait":
		position = Vector2(arena + 560.0, base_y - (30.0 if floating else 0.0))


func _physics_process(delta: float) -> void:
	t += delta
	flash -= delta
	var p = main.player
	match phase:
		"wait":
			if main.cam_left >= main.boss_arena - 1.0:
				phase = "enter"
		"enter":
			position.x = move_toward(position.x, home_x, 90.0 * delta)
			if position.x <= home_x + 1.0:
				phase = "fight"
		"fight":
			dir = 1 if p.position.x > position.x else -1
			if not p.dead:
				_attack(delta, p)
		"dash":
			dash_t += delta
			if dash_t < 0.5:
				# aviso: tiembla antes de embestir
				sprite.position.x = sin(t * 60.0) * 2.0
			else:
				sprite.position.x = 0.0
				position.x = move_toward(position.x, dash_target, 330.0 * delta)
				if absf(position.x - dash_target) < 1.0:
					if dash_target == home_x:
						phase = "fight"
					else:
						dash_target = home_x
			_contact(p)
		"dying":
			die_t += delta
			rotation += delta * 9.0 * -dir
			velocity.y += 500.0 * delta
			position += velocity * delta
			if int(die_t * 6.0) != int((die_t - delta) * 6.0):
				main.explode(global_position + Vector2(randf_range(-20, 20), randf_range(-40, 0)), randf_range(8, 16), false)
			if die_t > 1.6:
				_after_death()
			return
	if phase == "enter" and not floating:
		# entra desde fuera del nivel (allí no hay suelo): sin gravedad hasta llegar
		position.y = base_y
	elif phase in ["fight", "dash", "enter"]:
		if floating:
			position.y = base_y - 30.0 + sin(t * 1.6) * 12.0
		else:
			velocity.x = 0.0
			velocity.y += 900.0 * delta
			var was_air := not is_on_floor()
			move_and_slide()
			if position.y > base_y + 40.0:
				position.y = base_y
				velocity.y = 0.0
			if hop_air and was_air and is_on_floor():
				hop_air = false
				_hop_land()
	sprite.flip_h = dir > 0
	sprite.modulate = Color(4, 4, 4) if flash > 0.0 else (Color(1, 0.6, 0.6) if _enraged() and int(t * 4.0) % 2 == 0 else Color.WHITE)
	queue_redraw()


func _enraged() -> bool:
	return data.get("final", false) and hp < max_hp / 2


func _attack(delta: float, p) -> void:
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_left -= 1
			burst_t = 0.09
			var from := position + Vector2(dir * size.x * 0.3, -size.y * 0.32)
			_shoot(from, Vector2(dir, randf_range(-0.05, 0.05)).normalized() * 160.0)
		return
	attack_t -= delta
	if attack_t > 0.0:
		return
	var attacks: Array = data["attacks"]
	pattern = (pattern + 1) % attacks.size()
	attack_t = lerpf(0.9, 1.7, float(hp) / max_hp) * (0.75 if _enraged() else 1.0)
	match attacks[pattern]:
		"burst":
			burst_left = 12 if _enraged() else 8
		"spread":
			var from := position + Vector2(dir * size.x * 0.3, -size.y * 0.6)
			var n := 7 if _enraged() else 5
			for i in n:
				var a := (i - (n - 1) / 2.0) * 0.2
				_shoot(from, (p.position + Vector2(0, -12) - from).normalized().rotated(a) * 125.0)
		"lob":
			for o in ([-60.0, 0.0, 60.0] if _enraged() else [-40.0, 20.0]):
				main.throw_grenade(position + Vector2(dir * 10, -size.y * 0.8), p.position.x + o)
		"rain":
			var offsets := [-80.0, -30.0, 20.0, 70.0] if not _enraged() else [-110.0, -60.0, -10.0, 40.0, 90.0]
			for o in offsets:
				var b := Bomb.new()
				b.target_x = p.position.x + o
				b.position = Vector2(p.position.x + o, -20.0 - randf() * 40.0)
				main.add_child(b)
			Game.sfx("whistle", -8.0)
		"minions":
			for i in 2:
				var s := Soldier.new()
				s.dir = -1
				s.position = Vector2(main.cam_left + 480.0 + 10.0 + i * 24.0, 90)
				main.add_child(s)
		"dash":
			if floating:
				burst_left = 10
			else:
				phase = "dash"
				dash_t = 0.0
				dash_target = main.boss_arena + 60.0
				Game.sfx("jet", -8.0, 1.8)
		"wave":
			var b := Bullet.new()
			b.from_player = false
			b.kind = "shell"
			b.vel = Vector2(-180.0, 0.0)
			b.position = Vector2(position.x - size.x * 0.4, base_y - 7.0)
			main.add_child(b)
			main.shake(3.0)
			Game.sfx("cannon", -6.0, 0.7)
		"hop":
			if floating or not is_on_floor():
				_hop_land()
			else:
				velocity.y = -340.0
				hop_air = true
				Game.sfx("jump", -6.0, 0.7)


func _hop_land() -> void:
	main.shake(3.0)
	var from := position + Vector2(0, -size.y * 0.5)
	for i in 8:
		_shoot(from, Vector2.from_angle(PI + i * PI / 7.0) * 120.0)


func _contact(p) -> void:
	if p.dead:
		return
	if absf(p.position.x - position.x) < size.x * 0.35 and p.position.y > position.y - size.y * 0.8:
		p.hit()


func _shoot(from: Vector2, v: Vector2) -> void:
	var b := Bullet.new()
	b.from_player = false
	b.life = 3.5
	b.vel = v
	b.position = from
	main.add_child(b)
	Game.sfx("shot", -18.0, 0.7)


func take_damage(n: int) -> void:
	if phase in ["wait", "enter", "dying"]:
		return
	hp -= n
	flash = 0.05
	Game.sfx("hit", -16.0, 0.8)
	if hp <= 0:
		_die()


func _die() -> void:
	phase = "dying"
	die_t = 0.0
	collision_layer = 0
	remove_from_group("enemy")
	var final: bool = data.get("final", false)
	main.add_score(15000 if final else 5000)
	Juice.hitstop(0.12)
	main.shake(5.0)
	main.explode(global_position + Vector2(0, -size.y * 0.5), 26.0)
	Game.sfx("death", -4.0, 0.7)
	velocity = Vector2(-dir * 140.0, -300.0)
	if data.has("transform"):
		main.show_banner("¡TRANSFIGURACIÓN!", 2.0)
		velocity = Vector2(0, -120.0)
	elif data.has("after"):
		main.show_banner("¿ESTO ES TODO...?", 2.0)
	else:
		main.show_banner("¡RECIBIÓ SU MERECIDO!\n" + data["name"], 1.6)


## Qué pasa cuando termina de salir volando.
func _after_death() -> void:
	if data.get("transform", "") == "mecha":
		var m = preload("res://scripts/mecha.gd").new()
		main.add_child(m)
		main.boss = m
		main.reset_time()
		main.show_banner("¡LA PRESIDENTA MECHA!", 2.0)
		Game.sfx("boom", -2.0, 0.5)
	elif data.get("after", "") == "ritual":
		var r = preload("res://scripts/ritual.gd").new()
		main.add_child(r)
		main.boss = null
	else:
		main.stage_clear()
	queue_free()


func _draw() -> void:
	if phase not in ["fight", "dash"]:
		return
	var w := 60.0 if not data.get("final", false) else 90.0
	var y := -size.y - 8.0
	draw_rect(Rect2(-w / 2.0, y, w, 4), Color(0.2, 0, 0))
	draw_rect(Rect2(-w / 2.0, y, w * maxf(hp, 0) / max_hp, 4), Color(1, 0.25, 0.2))
