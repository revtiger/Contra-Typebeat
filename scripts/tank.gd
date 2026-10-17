extends CharacterBody2D
## Tanque: avanza hacia el jugador y dispara obuses rasantes a la altura del pecho
## (se esquivan saltando o cuerpo a tierra). Tres tipos muy distintos, con sprites de PixelLab
## (tools/sprites/tanks.py): comunista (estilo T-34), israelí (estilo Merkava) y estadounidense (estilo Abrams).
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
	max_hp = cfg["hp"]
	hp = max_hp
	var hull := SpriteUtil.v(info["hull"])
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(minf(hull.x - 6, 46), minf(hull.y, 26))
	cs.shape = r
	cs.position = Vector2(0, -r.size.y / 2)
	add_child(cs)


func _physics_process(delta: float) -> void:
	flash -= delta
	recoil = maxf(recoil - delta * 20.0, 0.0)
	velocity.y += 900.0 * delta
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
	if position.x < main.cam_left - 80 or position.y > 320:
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
	b.vel = Vector2(dir * cfg["shell"], 0)
	b.position = position + _muzzle()
	get_parent().add_child(b)
	Game.sfx("cannon", -6.0, 0.8 if kind == "israeli" else 1.0)
	main.explode(position + _muzzle(), cfg["boom"], false)


func take_damage(n: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= n
	flash = 0.06
	Game.sfx("hit", -16.0, 0.7)
	if hp <= 0:
		main.add_score(cfg["score"])
		main.blast(position + Vector2(0, -12), 36.0, false, 8)
		main.explode(position + Vector2(-10, -20), 20.0, false)
		main.explode(position + Vector2(12, -6), 16.0, false)
		queue_free()


func _draw() -> void:
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
