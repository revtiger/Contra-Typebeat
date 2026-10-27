extends RefCounted
## Edificios del greybox, generados al azar con semilla fija (con la misma semilla siempre salen iguales, así se
## pueden poner triggers, caminos e interacciones en un edificio concreto por su número).
## La fase los pide con "buildings": <semilla> en su plantilla (levels.gd); level.gd los guarda en level.buildings
## y greybox.gd los dibuja. Los edificios no tienen colisión: son escenario; sus techos y balcones sí (plataformas).
##
## Cada edificio: {"id", "tipo", "x", "w", "pisos", "h", "base", "plataformas", "saltos"} (base = y donde apoya,
## h = alto en px; plataformas = [[x, ancho, y]] que se atraviesan desde abajo; saltos = [[x, y]] centros de los
## jump hitbox que llevan a ellas). El edificio grande (tipo "grande") lleva además "nombre" e "interior".
##
## Plataformas y jump hitbox (provisional, al azar, para definir la mecánica):
## - fuera del barrio: techo de algunas casas y balcón del primer piso de algunos edificios (103 px sobre la
##   calle: no se llega con el salto normal de 72 px); a veces otro balcón en el segundo piso (salto encadenado).
## - barrio de azoteas (BARRIO): casas y edificios bajos pegados, todos con el techo como plataforma y jump hitbox
##   para subir al de al lado si es más alto: se pueden recorrer unas 5 pantallas sin bajar a la calle.

## Alto de un piso: el héroe mide 48 px (≈1,75 m), así que un piso de 3 m son unos 80 px
const PISO := 80.0
## [peso al azar, pisos mín, pisos máx, ancho mín, ancho máx] (anchos en casillas de 16 px)
const TIPOS := {
	"casa": [35, 1, 1, 6, 10],
	"edificio": [40, 2, 4, 7, 12],
	"torre": [20, 5, 7, 8, 13],
	"rascacielos": [5, 12, 18, 11, 16],
}
## el primer rascacielos sale a partir de aquí (pronto, para verlo enseguida); después, como mucho uno cada
## RASCACIELOS_SEP px
const PRIMER_RASCACIELOS := 1100.0
const RASCACIELOS_SEP := 1600.0
## Barrio de azoteas: de dónde a dónde (x del mundo; 2600 px ≈ 5,4 pantallas)
const BARRIO := [1800.0, 4400.0]
## Altura del jump hitbox sobre la superficie desde la que se salta: con el salto completo (72 px) la zona de
## agarre del héroe (36 px sobre los pies) llega a unos 108 px; el hitbox va un poco por debajo, así solo se
## alcanza cerca de lo alto del salto completo
const ALCANCE := 102.0
const P_TECHO := 0.5  # casas con el techo como plataforma
const P_BALCON := 0.4  # edificios, torres y rascacielos con balcón en el primer piso
const P_CADENA := 0.15  # de esos, con otro balcón en el segundo piso (salto encadenado)


## grande: {"x", "w", "pisos", "nombre", "interior"} o {} (el edificio grande con otra ruta dentro).
static func generar(semilla: int, x0: float, x1: float, base: float, suelo: float, grande := {}) -> Array:
	var out := _edificios(semilla, x0, x1, base)
	if not grande.is_empty():
		out = _con_grande(out, grande, base)
	# otro generador para las plataformas: así los edificios no cambian al tocar esto
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 1000
	var anterior = null
	for b in out:
		b["plataformas"] = []
		b["saltos"] = []
		if b["tipo"] == "grande":
			anterior = null
			continue
		if en_barrio(b["x"]):
			# todo techo es plataforma; jump hitbox desde la calle al primero y desde un techo al siguiente si es
			# más alto (bajar no lo necesita)
			var techo: float = base - b["h"]
			b["plataformas"].append([b["x"], b["w"], techo])
			if anterior == null:
				b["saltos"].append([b["x"] + 8.0, suelo - ALCANCE])
			elif techo < anterior["base"] - anterior["h"]:
				b["saltos"].append([b["x"] - 12.0, base - anterior["h"] - ALCANCE])
			anterior = b
			continue
		anterior = null
		if b["tipo"] == "casa":
			if rng.randf() < P_TECHO:
				b["plataformas"].append([b["x"], b["w"], base - b["h"]])
				b["saltos"].append([b["x"] + 16.0 * rng.randi_range(0, 2), suelo - ALCANCE])
		elif rng.randf() < P_BALCON:
			var w1 := 16.0 * rng.randi_range(3, 6)
			var x1b: float = b["x"] + 16.0 * rng.randi_range(0, maxi(0, int((b["w"] - w1) / 16.0)))
			var y1 := base - PISO
			b["plataformas"].append([x1b, minf(w1, b["w"]), y1])
			b["saltos"].append([x1b + 8.0, suelo - ALCANCE])
			if b["pisos"] >= 3 and rng.randf() < P_CADENA:
				# segundo balcón, escalonado a la derecha del primero: se llega desde el primero con otro impulso
				var x2b := minf(x1b + w1 - 16.0, b["x"] + b["w"] - 48.0)
				b["plataformas"].append([x2b, 48.0, y1 - PISO])
				b["saltos"].append([x2b + 8.0, y1 - ALCANCE])
	return out


static func en_barrio(x: float) -> bool:
	return x >= BARRIO[0] and x < BARRIO[1]


## Ventanas de un edificio (Rect2 en el mundo): una fila por piso a partir del primero (en la planta baja va la
## puerta). Las dibuja greybox.gd y por ellas se asoman los tiradores de las emboscadas (tirador_ventana.gd).
static func ventanas(b: Dictionary) -> Array:
	var out := []
	for p in range(1, int(b["pisos"])):
		var suelo_piso: float = b["base"] - p * PISO
		var wx: float = b["x"] + 10.0
		while wx + 14.0 <= b["x"] + b["w"] - 8.0:
			out.append(Rect2(wx, suelo_piso - PISO + 22.0, 14.0, 26.0))
			wx += 28.0
	return out


static func _edificios(semilla: int, x0: float, x1: float, base: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var out := []
	var x := x0 + 16.0 * rng.randi_range(0, 2)
	var ultimo_rascacielos := -INF
	while x < x1:
		var tipo := _tipo(rng)
		var barrio := en_barrio(x)
		if barrio:
			# barrio de azoteas: solo casas y edificios de 2 pisos (techos a 103 y 183 px sobre la calle). Empieza
			# con una casa: desde la calle, salto + impulso (136 px) no llega a un techo de 2 pisos
			var primero: bool = out.is_empty() or not en_barrio(out[-1]["x"])
			tipo = "casa" if primero or rng.randf() < 0.5 else "edificio"
		elif ultimo_rascacielos == -INF and x >= PRIMER_RASCACIELOS:
			tipo = "rascacielos"
		elif tipo == "rascacielos" and x - ultimo_rascacielos < RASCACIELOS_SEP:
			tipo = "torre"
		if tipo == "rascacielos":
			ultimo_rascacielos = x
		var t: Array = TIPOS[tipo]
		var w := 16.0 * rng.randi_range(t[3], t[4])
		var pisos := 2 if barrio and tipo == "edificio" else rng.randi_range(t[1], t[2])
		out.append({"id": out.size() + 1, "tipo": tipo, "x": x, "w": minf(w, x1 - x), "pisos": pisos,
			"h": pisos * PISO, "base": base})
		# callejón entre edificios: 0 a 3 casillas (en el barrio, 0 a 2: se cruzan con un salto normal)
		x += w + 16.0 * rng.randi_range(0, 2 if barrio else 3)
	return out


## Quita los edificios que pisan el grande, lo mete en su sitio y renumera.
static func _con_grande(lista: Array, g: Dictionary, base: float) -> Array:
	var out := []
	var puesto := false
	for b in lista:
		if b["x"] + b["w"] > g["x"] - 16.0 and b["x"] < g["x"] + g["w"] + 16.0:
			continue
		if not puesto and b["x"] > g["x"]:
			out.append(_grande(g, base))
			puesto = true
		out.append(b)
	if not puesto:
		out.append(_grande(g, base))
	for i in out.size():
		out[i]["id"] = i + 1
	return out


static func _grande(g: Dictionary, base: float) -> Dictionary:
	return {"id": 0, "tipo": "grande", "nombre": g["nombre"], "interior": g["interior"], "x": float(g["x"]),
		"w": float(g["w"]), "pisos": int(g["pisos"]), "h": g["pisos"] * PISO, "base": base}


static func _tipo(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in TIPOS:
		total += TIPOS[k][0]
	var r := rng.randi_range(1, total)
	for k in TIPOS:
		r -= TIPOS[k][0]
		if r <= 0:
			return k
	return "casa"
