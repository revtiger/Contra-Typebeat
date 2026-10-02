extends RefCounted
## Utilidades para usar las hojas de sprites de assets/sprites (generadas por tools/sprites/*.py).
## Cada hoja tiene una fila por animación y un fotograma por columna.

static var _frames_cache := {}
static var _meta_cache := {}


## Crea (o reutiliza) un SpriteFrames. anims = {nombre: [fila, fotogramas, fps, bucle]}.
static func frames(path: String, fw: int, fh: int, anims: Dictionary) -> SpriteFrames:
	var key := path + str(anims)
	if _frames_cache.has(key):
		return _frames_cache[key]
	var tex: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim_name in anims:
		var a: Array = anims[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, a[2])
		sf.set_animation_loop(anim_name, a[3])
		for i in a[1]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, a[0] * fh, fw, fh)
			sf.add_frame(anim_name, at)
	_frames_cache[key] = sf
	return sf


## AnimatedSprite2D con el origen en los pies del personaje (feet = píxel de los pies en el fotograma).
static func sprite(sf: SpriteFrames, feet: Vector2) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.centered = false
	s.offset = -feet
	return s


## Sprite2D de una pieza con su pivote (en píxeles de la imagen) en el origen del nodo.
static func part(path: String, pivot: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.offset = -pivot
	return s


static func meta(path: String) -> Dictionary:
	if not _meta_cache.has(path):
		_meta_cache[path] = JSON.parse_string(FileAccess.get_file_as_string(path))
	return _meta_cache[path]


static func v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])
