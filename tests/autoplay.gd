extends SceneTree
## Prueba automática: juega el nivel sola y guarda capturas.
## Uso: godot --path . --script res://tests/autoplay.gd -- <carpeta_capturas>

var frame := 0
var main
var out_dir := "user://shots"
var invincible := true


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2 and "boss" in OS.get_cmdline_user_args():
		main.player.position = Vector2(3700, 200)
		main.cam_left = 3500.0
	if main.player:
		if invincible:
			main.player.invuln = 1.0
			main.lives = 3
		Input.action_press("right")
		Input.action_press("shoot")
		if frame % 50 == 0:
			Input.action_press("jump")
		elif frame % 50 == 25:
			Input.action_release("jump")
		if main.cam_left >= main.BOSS_ARENA - 1.0:
			Input.action_release("right")
		if frame % 200 > 150:
			Input.action_press("up")
		else:
			Input.action_release("up")
	if frame % 120 == 0:
		var img := root.get_texture().get_image()
		img.save_png("%s/shot_%04d.png" % [out_dir, frame])
		print("frame %d  x=%.0f cam=%.0f score=%d state=%s" % [frame, main.player.position.x, main.cam_left, main.score, main.state])
	return frame > 6000 or main.state == "clear"
