extends CharacterBody2D
## Tanque: avanza hacia el jugador y dispara obuses hacia su pecho (el cañón está alto: el obús baja un poco; se
## esquivan saltando o cuerpo a tierra). Tres tipos muy distintos (tools/sprites/tanks.py: dibujo de ChatGPT del
## alto de Massa, orugas animadas con PixelLab): comunista (estilo T-34), israelí (estilo Merkava) y estadounidense
## (estilo Abrams). Al destruirlo queda la chatarra en la calle, echando humo y fuego.
## El tipo viene del nivel (["tank", x, y, tipo]) o, si no, se alterna según la x.

const Bullet = preload("res://scripts/bullet.gd")
const SpriteUtil = preload("res://scripts/sprite_util.gd")

## vida, velocidad, tiempo entre disparos, obuses por disparo (ráfaga), velocidad del obús,
## tamaño de la explosión del disparo y puntos al destruirlo
const TYPES := {
	"comunista": {"hp": 20, "speed": 22.0, "rate": 2.3, "burst": 1, "shell": 150.0, "boom": 5.0, "score": 2000},
	"israeli": {"hp": 34, "speed": 12.0, "rate": 3.2, "burst": 1, "shell": 120.0, "boom": 9.0, "score": 3000},
	"usa": {"hp": 16, "speed": 44.0, "rate": 1.4, "burst": 2, "shell": 200.0, "boom": 5.0, "score": 2500},
}
const ORDER := ["comunista", "israeli", "usa"]
const BURST_GAP := 0.25

var kind := ""
var cfg: Dictionary
var info: Dictionary
var tex: Texture2D
var tex_roto: Texture2D
var roto := false  # destruido: queda la chatarra
var max_hp := 20
var hp := 20
var dir := -1
var shoot_t := 1.6
var burst_left := 0
var burst_t := 0.0
var flash := 0.0
var recoil := 0.0
var anim_t := 0.0
var main


func _ready() -> void:
	main = get_tree().get_first_node_in_group("level")
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	if not TYPES.has(kind):
		kind = ORDER[int(position.x / 120.0) % ORDER.size()]
	cfg = TYPES[kind]
	info = SpriteUtil.meta("res://assets/sprites/tanks_meta.json")[kind]
	tex = load("res://assets/sprites/tank_%s.png" % kind)
	tex_roto = load("res://assets/sprites/tank_%s_roto.png" % kind)
	max_hp = cfg["hp"]
	hp = max_hp
	var hull := SpriteUtil.v(info["hull"])
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(hull.x - 10.0, hull.y * 0.8)
	cs.shape = r
	cs.position = Vector2(0, -r.size.y / 2)
	add_child(cs)


func _physics_process(delta: float) -> void:
	flash -= delta
	recoil = maxf(recoil - delta * 20.0, 0.0)
	velocity.y += 900.0 * delta
	if roto:
		anim_t += delta
		velocity.x = 0.0
		move_and_slide()
		if position.x < main.cam_left - 120:
			queue_free()
		queue_redraw()
		return
	var p = main.player
	var on_screen: bool = position.x > main.cam_left + 10 and position.x < main.cam_left + 470
	var dx: float = p.position.x - position.x
	dir = 1 if dx > 0 else -1
	velocity.x = dir * cfg["speed"] if on_screen and absf(dx) > 120.0 else 0.0
	if velocity.x != 0.0:
		anim_t += delta
	move_and_slide()
	shoot_t -= delta
	if shoot_t <= 0.0 and on_screen and not p.dead:
		shoot_t = cfg["rate"]
		burst_left = cfg["burst"]
		burst_t = 0.0
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_left -= 1
			burst_t = BURST_GAP
			_shoot()
	if position.x < main.cam_left - 80 or position.y > main.cam_y + 320:
		queue_free()
	queue_redraw()


func _muzzle() -> Vector2:
	var m := SpriteUtil.v(info["muzzle"])
	return Vector2(m.x * -dir, m.y)  # el sprite mira a la izquierda (dir = -1)


func _shoot() -> void:
	recoil = 3.0
	var b := Bullet.new()
	b.from_player = false
	b.kind = "shell"
	b.position = position + _muzzle()
	# hacia el pecho del jugador, pero siempre hacia delante y casi horizontal
	var to: Vector2 = main.player.position + Vector2(0, -22) - b.position
	var ang := clampf(atan2(to.y, absf(to.x)), -0.12, 0.35)
	b.vel = Vector2(dir * cos(ang), sin(ang)) * cfg["shell"]
	get_parent().add_child(b)
	Game.sfx("cannon", -6.0, 0.8 if kind == "israeli" else 1.0)
	main.explode(position + _muzzle(), cfg["boom"], false)


func take_damage(n: int) -> void:
	if is_queued_for_deletion() or roto:
		return
	hp -= n
	flash = 0.06
	Game.sfx("hit", -16.0, 0.7)
	if hp <= 0:
		main.add_score(cfg["score"])
		main.blast(position + Vector2(0, -16), 40.0, false, 8)
		main.explode(position + Vector2(-16, -30), 22.0, false)
		main.explode(position + Vector2(18, -10), 18.0, false)
		# queda la chatarra: ya no choca ni es enemigo
		roto = true
		burst_left = 0
		remove_from_group("enemy")
		collision_layer = 0


func _draw() -> void:
	if roto:
		_draw_roto()
		return
	var fr := SpriteUtil.v(info["frame"])
	var n: int = info["frames"]
	var f := int(anim_t * 10.0) % n
	# el sprite mira a la izquierda: se voltea cuando avanza a la derecha; el retroceso lo empuja hacia atrás
	draw_set_transform(Vector2(-dir * recoil, 0), 0.0, Vector2(-dir, 1))
	var tint := Color(4, 4, 4) if flash > 0.0 else Color.WHITE
	draw_texture_rect_region(tex, Rect2(-info["center_x"], -info["base"], fr.x, fr.y), Rect2(f * fr.x, 0, fr.x, fr.y), tint)
	draw_set_transform(Vector2.ZERO)
	# vida
	if hp < max_hp:
		var top: float = -float(info["hull"][1]) - 6.0
		draw_rect(Rect2(-14, top, 28, 2), Color(0.2, 0, 0))
		draw_rect(Rect2(-14, top, 28.0 * hp / max_hp, 2), Color(1, 0.3, 0.2))


## Chatarra: el dibujo del tanque destruido, con humo negro que sube y llamitas que titilan.
func _draw_roto() -> void:
	var r: Dictionary = info["roto"]
	var size := SpriteUtil.v(r["size"])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-dir, 1))
	draw_texture(tex_roto, Vector2(-r["center_x"], -r["base"]))
	draw_set_transform(Vector2.ZERO)
	var top := -float(r["base"]) + size.y * 0.35
	for i in 6:
		var k := fmod(anim_t * 0.45 + i / 6.0, 1.0)
		var x := (-14.0 + (i % 3) * 14.0) * -dir + sin(anim_t * 1.3 + i) * 3.0 + k * 10.0
		draw_circle(Vector2(x, top - k * 46.0).round(), 4.0 + k * 9.0, Color(0.13, 0.12, 0.12, 0.55 * (1.0 - k)))
	for i in 3:
		var fx := (-20.0 + i * 18.0) * -dir
		var h := 3.0 + absf(sin(anim_t * 11.0 + i * 2.1)) * 4.0
		draw_circle(Vector2(fx, top + 6.0 - h * 0.5).round(), h * 0.6, Color(1, 0.55, 0.12, 0.85))
		draw_circle(Vector2(fx, top + 6.0 - h * 0.3).round(), h * 0.3, Color(1, 0.9, 0.4))
