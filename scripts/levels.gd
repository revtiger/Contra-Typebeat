extends RefCounted
## Fases de la campaña "ONU: Trying to save the world" (docs/historia.md).
## 5 zonas x 3 fases = 15. Game.level es el índice en LIST (0 = fase 1.1).
## Cada fase usa una plantilla de terreno (TEMPLATES) y termina en su jefe:
##   minijefe en X.1 y X.2, jefe final en X.3 (politician.gd); en el nivel secreto,
##   las fases 5.1 y 5.2 terminan en una puerta (door.gd) y la 5.3 en el líder de la Orden.
##
## ground:    [x_inicio, x_fin, y_superficie]. Los huecos entre tramos son fosos (muerte).
## platforms: [x, ancho, y]. Puentes/salientes que se atraviesan desde abajo.
## entities:  [tipo, x, y, extra]. Aparecen cuando la cámara se acerca a su x.
##   sniper, turret, barrel, mine, tank: y = suelo donde apoyan
##   grenadier: soldado que se para a lanzar granadas
##   capsule: extra = lo que suelta: arma (H, R, F, L, S) o B (+10 bombas)
##   jet: bombardeo aéreo que apunta a donde está el jugador
##   boss: extra = "pol:<id>" (politician.gd), "wall", "heli" o "mecha"
##   door: extra = número de puerta (nivel secreto)
## Referencia de alturas: el salto sube ~70 px; los tramos de suelo pueden subir hasta ~35 px.

const END := 3000

## zona, bandera (country), música, y las 3 fases: [lugar, plantilla, jefe]
const ZONES := [
	{"zone": "ARGENTINA", "country": "ar", "freed": "LIBERADA", "phases": [
		["MONTE MISIONERO", "jungle", "massa"],
		["QUEBRADA DE HUMAHUACA", "desert", "kirchner"],
		["BUENOS AIRES · CASA ROSADA", "city", "milei"],
	]},
	{"zone": "MÉXICO", "country": "mx", "phases": [
		["SELVA DEL SURESTE", "jungle", "amlo"],
		["DESIERTO DEL NORTE", "desert", "salinas"],
		["CAPITAL · PALACIO NACIONAL", "city", "sheinbaum"],
	]},
	{"zone": "EUA", "country": "us", "phases": [
		["FRONTERA DE TEXAS", "desert", "biden"],
		["PANTANOS DE FLORIDA", "jungle", "obama"],
		["WASHINGTON · CASA BLANCA", "city", "trump"],
	]},
	{"zone": "ALEMANIA", "country": "de", "freed": "LIBERADA", "phases": [
		["SELVA NEGRA", "snow", "merkel"],
		["ALPES BÁVAROS", "snow", "scholz"],
		["BERLÍN · BUNDESTAG", "city", "merz"],
	]},
	{"zone": "NIVEL SECRETO: ONU", "country": "un", "phases": [
		["SÓTANOS DE LA ONU", "base", "door:1"],
		["LABORATORIO DE LA ORDEN", "base", "door:2"],
		["SALA DEL CONSEJO SECRETO", "base", "lider"],
	]},
]

const MUSIC := {"jungle": "level", "desert": "desert", "city": "city", "snow": "level", "base": "city"}

const TEMPLATES := {
	"jungle": {
		"ground": [[0, 900, 230], [948, 1500, 230], [1500, 1900, 200], [1948, 2400, 230], [2448, END, 230]],
		"platforms": [
			[300, 120, 175], [600, 110, 175], [680, 80, 125], [1080, 150, 175], [1250, 90, 125],
			[1560, 100, 150], [2080, 120, 175], [2240, 120, 125],
		],
		"entities": [
			["sniper", 340, 175], ["turret", 700, 230], ["capsule", 900, 60, "H"], ["sniper", 1130, 175],
			["turret", 1250, 230], ["sniper", 1280, 125], ["turret", 1720, 200], ["sniper", 1600, 150],
			["capsule", 1700, 60, "B"], ["grenadier", 1150, 230], ["grenadier", 2050, 230],
			["turret", 2290, 125], ["sniper", 2120, 175], ["capsule", 2300, 60, "S"], ["grenadier", 2380, 230],
		],
	},
	"desert": {
		"ground": [[0, 700, 230], [748, 1300, 230], [1300, 1650, 198], [1650, 2100, 230], [2148, END, 230]],
		"platforms": [
			[250, 100, 175], [520, 90, 175], [900, 120, 175], [1060, 90, 125], [1400, 100, 145],
			[1800, 110, 175], [1960, 90, 125], [2250, 120, 175],
		],
		"entities": [
			["sniper", 280, 175], ["barrel", 420, 230], ["barrel", 434, 230], ["mine", 610, 230],
			["capsule", 700, 60, "L"], ["sniper", 940, 175], ["barrel", 1000, 230], ["mine", 1150, 230],
			["sniper", 1090, 125], ["jet", 1250, 0], ["grenadier", 1200, 230],
			["turret", 1580, 198], ["barrel", 1480, 198], ["barrel", 1494, 198], ["sniper", 1430, 145],
			["tank", 1900, 230], ["sniper", 1990, 125], ["mine", 1760, 230], ["capsule", 2150, 60, "R"],
			["barrel", 2240, 230], ["barrel", 2254, 230], ["sniper", 2280, 175],
		],
	},
	"city": {
		"ground": [[0, 800, 230], [850, 1400, 230], [1400, 1700, 205], [1700, 2200, 230], [2250, END, 230]],
		"platforms": [
			[250, 110, 175], [600, 100, 175], [680, 90, 125], [1000, 120, 175], [1180, 100, 130],
			[1500, 90, 150], [1850, 120, 175], [2000, 100, 125],
		],
		"entities": [
			["sniper", 290, 175], ["barrel", 470, 230], ["barrel", 484, 230], ["grenadier", 560, 230],
			["capsule", 700, 60, "H"], ["sniper", 720, 125], ["tank", 1100, 230], ["sniper", 1210, 130],
			["turret", 1560, 205], ["jet", 1450, 0], ["barrel", 1760, 230], ["barrel", 1774, 230],
			["grenadier", 1900, 230], ["capsule", 1800, 60, "B"], ["sniper", 2030, 125],
			["capsule", 2250, 60, "S"], ["tank", 2350, 230],
		],
	},
	"snow": {
		"ground": [[0, 850, 230], [900, 1350, 230], [1350, 1650, 210], [1650, 2150, 230], [2200, END, 230]],
		"platforms": [
			[280, 110, 175], [620, 100, 175], [1000, 120, 175], [1180, 90, 128], [1450, 100, 160],
			[1800, 120, 175], [1960, 90, 128],
		],
		"entities": [
			["sniper", 320, 175], ["turret", 700, 230], ["capsule", 850, 60, "H"], ["grenadier", 1000, 230],
			["sniper", 1200, 128], ["tank", 1500, 210], ["mine", 1700, 230], ["capsule", 1750, 60, "B"],
			["sniper", 1840, 175], ["jet", 1900, 0], ["grenadier", 2000, 230], ["turret", 2120, 230],
			["capsule", 2250, 60, "F"], ["tank", 2380, 230],
		],
	},
	"base": {
		"ground": [[0, 700, 230], [750, 1300, 230], [1300, 1600, 205], [1600, 2100, 230], [2150, END, 230]],
		"platforms": [
			[250, 120, 175], [550, 100, 140], [900, 120, 175], [1100, 100, 130], [1400, 90, 150],
			[1750, 120, 175], [1950, 110, 130],
		],
		"entities": [
			["sniper", 290, 175], ["turret", 400, 230], ["barrel", 600, 230], ["barrel", 614, 230],
			["capsule", 800, 60, "L"], ["sniper", 950, 175], ["grenadier", 1100, 230], ["turret", 1450, 205],
			["mine", 1650, 230], ["capsule", 1700, 60, "B"], ["sniper", 1800, 175], ["tank", 1900, 230],
			["sniper", 2000, 130], ["turret", 2200, 230], ["capsule", 2250, 60, "R"], ["grenadier", 2300, 230],
		],
	},
}

static var LIST := _build()


static func _build() -> Array:
	var out := []
	for zi in ZONES.size():
		var z: Dictionary = ZONES[zi]
		for pi in 3:
			var ph: Array = z["phases"][pi]
			var tpl: Dictionary = TEMPLATES[ph[1]]
			var boss_id: String = ph[2]
			var entities: Array = _vary(tpl["entities"], zi + pi)
			var role := "final" if pi == 2 else "mini"
			var boss_name := ""
			if boss_id.begins_with("door:"):
				role = "door"
				entities.append(["door", END - 80, 230, int(boss_id.substr(5))])
			else:
				boss_name = preload("res://scripts/politician.gd").POLS[boss_id]["name"]
				entities.append(["boss", END - 110, 230, "pol:" + boss_id])
			out.append({
				"phase": "%d.%d" % [zi + 1, pi + 1],
				"zone": z["zone"],
				"freed": z.get("freed", "LIBERADO"),
				"country": z["country"],
				"place": ph[0],
				"name": "%d.%d %s: %s" % [zi + 1, pi + 1, z["zone"], ph[0]],
				"boss_name": boss_name,
				"boss_role": role,
				"theme": ph[1],
				"music": MUSIC[ph[1]],
				"end": END,
				"ground": tpl["ground"],
				"platforms": tpl["platforms"],
				"entities": entities,
			})
	return out


## Variación para que dos fases con la misma plantilla no sean idénticas:
## según v, algunos francotiradores pasan a granaderos, cambia el arma de las cápsulas
## y a partir de la zona 3 aparece un bombardeo extra.
static func _vary(src: Array, v: int) -> Array:
	var weapons := ["H", "S", "R", "L", "F"]
	var out := []
	var n := 0
	for e in src:
		var c: Array = e.duplicate()
		if c[0] == "sniper" and (n + v) % 3 == 0 and c[2] >= 228:
			c[0] = "grenadier"
		if c[0] == "capsule" and c[3] != "B":
			c[3] = weapons[(weapons.find(c[3]) + v) % weapons.size()]
		out.append(c)
		n += 1
	if v >= 3:
		out.append(["jet", 2100, 0])
	return out
