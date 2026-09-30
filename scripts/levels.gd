extends RefCounted
## Datos de las misiones. Para añadir una, copia un bloque y cambia los números.
##
## ground:    [x_inicio, x_fin, y_superficie]. Los huecos entre tramos son fosos (muerte).
## platforms: [x, ancho, y]. Puentes/salientes que se atraviesan desde abajo.
## entities:  [tipo, x, y, extra]. Aparecen cuando la cámara se acerca a su x.
##   sniper, turret, barrel, mine, tank: y = suelo donde apoyan
##   grenadier: soldado que se para a lanzar granadas
##   capsule: extra = lo que suelta: arma (H, R, F, L, S) o B (+10 bombas)
##   jet: bombardeo aéreo que apunta a donde está el jugador
##   miniboss: extra = "comandante" o "camion" (sin usar desde que se quitó Bolivia). Bloquea la cámara hasta que muere
##   boss: extra = "wall" (muro), "heli" (helicóptero, sin usar) o "mecha" (Presidenta Mecha). El nombre que se anuncia va en "boss_name"
## Referencia de alturas: el salto sube ~70 px; los tramos de suelo pueden subir hasta ~35 px.

const LIST := [
	{
		"name": "MISIÓN 1: TRIPLE FRONTERA",
		"boss_name": "LA FORTALEZA ROJA",
		"theme": "jungle",
		"music": "level",
		"end": 4300,
		"ground": [
			[0, 900, 230], [948, 1500, 230], [1500, 1900, 200], [1948, 2600, 230],
			[2648, 3400, 230], [3440, 4300, 230],
		],
		"platforms": [
			[300, 120, 175], [600, 110, 175], [680, 80, 125], [1080, 150, 175], [1250, 90, 125],
			[1560, 100, 150], [2080, 120, 175], [2240, 120, 125], [2780, 160, 175], [2900, 110, 125],
			[3600, 120, 175],
		],
		"entities": [
			["sniper", 340, 175], ["turret", 700, 230], ["capsule", 900, 60, "H"], ["sniper", 1130, 175],
			["turret", 1250, 230], ["sniper", 1280, 125], ["turret", 1720, 200], ["sniper", 1600, 150],
			["turret", 2290, 125], ["sniper", 2120, 175], ["capsule", 2600, 60, "S"],
			["capsule", 1700, 60, "B"], ["grenadier", 1150, 230], ["grenadier", 2050, 230],
			["miniboss", 2420, 230, "comandante"], ["capsule", 3200, 60, "R"], ["grenadier", 3300, 230],
			["sniper", 2820, 175], ["turret", 3000, 230], ["turret", 2950, 125], ["sniper", 3500, 230],
			["sniper", 3640, 175], ["boss", 4190, 230, "wall"],
		],
	},
	{
		"name": "MISIÓN 2: FRONTERA NORTE",
		"boss_name": "LA PRESIDENTA MECHA",
		"theme": "city",
		"music": "city",
		"end": 4000,
		"ground": [
			[0, 800, 230], [850, 1400, 230], [1400, 1700, 205], [1700, 2200, 230], [2250, 2900, 230],
			[2900, 3200, 210], [3250, 4000, 230],
		],
		"platforms": [
			[250, 110, 175], [600, 100, 175], [680, 90, 125], [1000, 120, 175], [1180, 100, 130],
			[1500, 90, 150], [1850, 120, 175], [2000, 100, 125], [2400, 120, 175], [2550, 110, 130],
			[3000, 100, 160], [3350, 120, 175],
		],
		"entities": [
			# tramo 1: calle en ruinas
			["sniper", 290, 175], ["barrel", 470, 230], ["barrel", 484, 230], ["grenadier", 560, 230],
			["capsule", 700, 60, "H"], ["sniper", 720, 125], ["tank", 1100, 230], ["sniper", 1210, 130],
			# tramo 2: plaza y mini jefe
			["turret", 1560, 205], ["jet", 1450, 0], ["barrel", 1760, 230], ["barrel", 1774, 230],
			["grenadier", 1900, 230], ["capsule", 1800, 60, "B"], ["miniboss", 2150, 230, "comandante"],
			# tramo 3: avenida bombardeada
			["capsule", 2350, 60, "R"], ["sniper", 2440, 175], ["sniper", 2590, 130], ["mine", 2700, 230],
			["tank", 2800, 230], ["turret", 3050, 210], ["jet", 2950, 0], ["grenadier", 3150, 210],
			["capsule", 3250, 60, "S"], ["sniper", 3380, 175], ["barrel", 3460, 230], ["barrel", 3474, 230],
			["boss", 3900, 230, "mecha"],
		],
	},
]
