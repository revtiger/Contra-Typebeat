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
##   miniboss: extra = "comandante" o "camion". Bloquea la cámara hasta que muere
##   boss: extra = "wall" (muro) o "heli" (helicóptero). El nombre que se anuncia va en "boss_name"
## Referencia de alturas: el salto sube ~70 px; los tramos de suelo pueden subir hasta ~35 px.

const LIST := [
	{
		"name": "MISIÓN 1: TRIPLE FRONTERA",
		"boss_name": "EL MURO DE ZARKO",
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
		"name": "MISIÓN 2: BOLIVIA",
		"boss_name": "HELICÓPTERO CÓNDOR",
		"theme": "desert",
		"music": "desert",
		"end": 4700,
		"ground": [
			[0, 700, 230], [748, 1300, 230], [1300, 1650, 198], [1650, 2100, 230], [2148, 2700, 230],
			[2700, 3050, 205], [3098, 3700, 230], [3748, 4700, 230],
		],
		"platforms": [
			[250, 100, 175], [520, 90, 175], [900, 120, 175], [1060, 90, 125], [1400, 100, 145],
			[1800, 110, 175], [1960, 90, 125], [2300, 120, 175], [2480, 100, 130], [2850, 120, 150],
			[3250, 110, 175], [3420, 100, 125], [3900, 120, 175],
		],
		"entities": [
			# tramo 1: aprender barriles y minas
			["sniper", 280, 175], ["barrel", 420, 230], ["barrel", 434, 230], ["mine", 610, 230],
			["capsule", 700, 60, "L"], ["sniper", 940, 175], ["barrel", 1000, 230], ["mine", 1150, 230],
			["sniper", 1090, 125], ["jet", 1250, 0], ["capsule", 1350, 60, "R"], ["grenadier", 1200, 230],
			# tramo 2: meseta y primer tanque
			["turret", 1580, 198], ["barrel", 1480, 198], ["barrel", 1494, 198], ["sniper", 1430, 145],
			["tank", 1900, 230], ["sniper", 1990, 125], ["mine", 1760, 230],
			# tramo 3: campamento y mini jefe
			["capsule", 2150, 60, "F"], ["barrel", 2240, 230], ["barrel", 2254, 230], ["barrel", 2268, 230],
			["sniper", 2510, 130], ["miniboss", 2640, 230, "camion"], ["mine", 2800, 230], ["turret", 2950, 205],
			["sniper", 2880, 150], ["capsule", 2900, 60, "B"], ["grenadier", 3000, 205],
			# tramo 4: tanque, barriles en cadena y último bombardeo
			["tank", 3350, 230], ["barrel", 3180, 230], ["barrel", 3194, 230], ["capsule", 3300, 60, "S"],
			["sniper", 3450, 125], ["mine", 3520, 230], ["mine", 3580, 230], ["jet", 3650, 0],
			["barrel", 3820, 230], ["sniper", 3930, 175],
			["boss", 4300, 60, "heli"],
		],
	},
]
