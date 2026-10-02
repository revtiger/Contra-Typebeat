extends RefCounted
## Sintetizador de efectos y música estilo 8 bits. Todo se genera por código (sin archivos de audio).

const RATE := 22050


static func _wav(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


static func _osc(wave: String, ph: float) -> float:
	var p := fmod(ph, 1.0)
	match wave:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"saw":
			return p * 2.0 - 1.0
		"tri":
			return absf(p * 4.0 - 2.0) - 1.0
	return sin(ph * TAU)


## Tono con barrido de frecuencia f0 -> f1, mezcla de ruido y caída lineal.
static func _tone(dur: float, f0: float, f1: float, wave: String, vol: float, noise := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ph := 0.0
	for i in n:
		var k := float(i) / n
		ph += lerpf(f0, f1, k) / RATE
		var s := lerpf(_osc(wave, ph), rng.randf_range(-1.0, 1.0), noise)
		buf[i] = s * vol * (1.0 - k)
	return buf


## Explosión: ruido filtrado más un golpe grave.
static func _boom(dur: float, vol: float, cutoff: float, thump: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var y := 0.0
	var ph := 0.0
	for i in n:
		var k := float(i) / n
		y += (rng.randf_range(-1.0, 1.0) - y) * cutoff * (1.0 - k * 0.7)
		ph += lerpf(thump, thump * 0.3, k) / RATE
		var s := y * 2.5 + sin(ph * TAU) * pow(1.0 - k, 3.0)
		buf[i] = clampf(s, -1.0, 1.0) * vol * pow(1.0 - k, 1.5)
	return buf


static func _seq(notes: Array, wave: String, vol: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	for nt in notes:
		buf.append_array(_tone(nt[1], nt[0], nt[0], wave, vol if nt[0] > 0 else 0.0))
	return buf


static func make(sound: String) -> AudioStreamWAV:
	match sound:
		"shot": return _wav(_tone(0.08, 1100, 250, "square", 0.35, 0.35))
		"laser": return _wav(_tone(0.22, 2200, 180, "sine", 0.5))
		"fire": return _wav(_tone(0.18, 320, 90, "saw", 0.4, 0.55))
		"jump": return _wav(_tone(0.12, 220, 620, "square", 0.25))
		"hit": return _wav(_tone(0.04, 1400, 700, "square", 0.25))
		"boom": return _wav(_boom(0.9, 0.9, 0.18, 90))
		"small_boom": return _wav(_boom(0.35, 0.7, 0.35, 140))
		"cannon": return _wav(_boom(0.3, 0.8, 0.25, 70))
		"death": return _wav(_tone(0.7, 700, 60, "square", 0.35))
		"pickup": return _wav(_seq([[523, 0.06], [659, 0.06], [784, 0.06], [1046, 0.14]], "square", 0.3))
		"move": return _wav(_tone(0.04, 520, 520, "square", 0.2))
		"select": return _wav(_seq([[660, 0.05], [990, 0.1]], "square", 0.3))
		"beep": return _wav(_seq([[1600, 0.05], [0, 0.04], [1600, 0.05]], "square", 0.3))
		"whistle": return _wav(_tone(0.9, 1500, 450, "sine", 0.25))
		"jet": return _wav(_boom(1.6, 0.5, 0.06, 40))
		"type": return _wav(_tone(0.02, 900, 900, "square", 0.12))
		"knife": return _wav(_tone(0.1, 3200, 700, "saw", 0.3, 0.6))
	return _wav(_tone(0.1, 440, 440, "square", 0.2))


static func _midi(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## Bucle de música: bajo pulsante, arpegio, bombo, caja y charles.
static func music(track: String) -> AudioStreamWAV:
	var bpm := 150.0
	var root := 45  # La
	var chords := [[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -1, 2]]  # Am F G E
	var four_floor := true
	match track:
		"menu":
			bpm = 118.0
			four_floor = false
		"desert":
			bpm = 162.0
			root = 50  # Re
			chords = [[0, 3, 7], [1, 5, 8], [-2, 2, 5], [-5, -1, 2]]  # frigio: Dm Eb C A
		"city":
			bpm = 156.0
			root = 43  # Sol
			chords = [[0, 3, 7], [-2, 2, 5], [-4, 0, 3], [-5, -1, 2]]  # Gm F Eb D
		"boss":
			bpm = 172.0
			root = 40
			chords = [[0, 3, 7], [1, 4, 8], [0, 3, 7], [6, 9, 13]]
	var step := 60.0 / bpm / 4.0
	var steps := 64
	var n := int(steps * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ph_bass := 0.0
	var ph_lead := 0.0
	var hp := 0.0
	for i in n:
		var t := float(i) / RATE
		var si := int(t / step)
		var pos := (t - si * step) / step
		var bar := (si / 16) % 4
		var beat := si % 16
		var ch: Array = chords[bar]
		# bajo en corcheas, octava alterna
		var bn: float = root + ch[0] - 12 + (12 if (si / 2) % 2 == 1 else 0)
		ph_bass += _midi(bn) / RATE
		var bass := _osc("square", ph_bass) * 0.14 * (1.0 - 0.6 * fmod(t / (step * 2), 1.0))
		# arpegio en semicorcheas
		var ln: float = root + 24 + ch[si % 3]
		ph_lead += _midi(ln) / RATE
		var lead := _osc("tri", ph_lead) * (0.07 if track != "menu" else 0.05) * (1.0 - pos * 0.8)
		# batería
		var dr := 0.0
		var kick := (beat % 4 == 0) if four_floor else (beat == 0 or beat == 10)
		if kick:
			var kt := pos * step
			dr += sin(TAU * (150.0 - 110.0 * minf(kt / 0.08, 1.0)) * kt) * maxf(0.0, 1.0 - kt / 0.14) * 0.5
		var white := rng.randf_range(-1.0, 1.0)
		if beat == 4 or beat == 12:
			dr += white * maxf(0.0, 1.0 - pos * 1.6) * 0.18
		hp = white - hp * 0.5
		if beat % 2 == 1:
			dr += hp * maxf(0.0, 1.0 - pos * 4.0) * 0.04
		buf[i] = bass + lead + dr
	return _wav(buf, true)
