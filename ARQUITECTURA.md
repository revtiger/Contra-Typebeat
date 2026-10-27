# Arquitectura de ONU: Outbreak

Última revisión: 26-10-2026 · Godot 4.7.2

Este documento fija las **reglas de arquitectura** del proyecto. Todo el equipo puede editar cualquier archivo y proponer ideas, pero las reglas de aquí se respetan hasta que el equipo las cambie. Cada regla tiene un número (`ARQ-NN`) para poder citarla.

## 0. Cómo se usan estas reglas

### Estados

| Marca | Significa |
|---|---|
| ✅ | Regla aprobada por el equipo. Es obligatoria |
| ☐ | Por definir. Lo que hay hoy es provisional: se puede usar, pero no se amplía ni se cambia sin hablarlo |

### Dos tipos de aviso

| Aviso | Cuándo | Qué pasa |
|---|---|---|
| 🛑 **BLOQUEO** | El cambio rompe una regla ✅ | No se hace. Se usa la alternativa que permite la regla o, si el equipo decide que la regla está mal, **primero se cambia este documento** (en su propio PR) y después se implementa |
| ⚠ **WARNING** | El cambio es delicado: un cambio drástico de arte, algo de un tema ☐ por definir, renombrar o mover archivos, cambiar el largo de un mapa… | Se avisa antes de hacerlo y solo se sigue si la persona lo confirma. Se menciona en el PR |

**Principio:** las reglas se cambian, no se saltan. Nada de "solo por esta vez".

### Instrucciones para la IA (Claude Code u otra)

1. Antes de escribir código o tocar arte, comprueba si el cambio afecta a alguna regla de este documento.
2. Si rompe una regla ✅, **detente antes de hacer el cambio** y muestra un 🛑 BLOQUEO. Aunque la persona insista, no lo hagas: ofrece la alternativa o propón cambiar la regla primero.
3. Si es delicado, muestra un ⚠ WARNING y espera la confirmación.
4. Usa siempre este formato:

```
🛑 BLOQUEO DE ARQUITECTURA · ARQ-11 (Terreno solo para pisar y chocar)
Qué ibas a hacer: poner el área de daño del pinchazo en la capa Terreno (1).
Por qué no se puede: Terreno es solo para lo que el jugador y los enemigos pisan o chocan.
Alternativa: ponerla en HitboxEnemigo (16), con máscara MainHurtbox (2).
¿Sigo con la alternativa o quieres proponer un cambio de la regla?
```

5. Las excepciones escritas en este documento **no son violaciones**: no las "corrijas".

---

## 1. Capas de colisión ✅

Aprobadas por el equipo tal como están. Los nombres están en *Project Settings > Layer Names > 2D Physics*.

| Nº | Nombre | Valor en el código | Qué contiene | Con qué interactúa |
|---|---|---|---|---|
| 1 | **Terreno** | `1` | Suelo, cuestas, paredes y plataformas (también las que se atraviesan desde abajo) | Lo pisan el jugador y los enemigos; frena las balas |
| 2 | **MainHurtbox** | `2` | Zona donde el jugador recibe daño (hoy, el propio cuerpo del jugador) | La golpean HitboxEnemigo; la detectan Interactivos y Zonas |
| 3 | **EnemyHurtbox** | `4` | Zona donde reciben daño los enemigos (soldados, tanques, nidos, minijefes, jefes) y lo que el jugador puede romper (barriles, minas, cápsulas voladoras) | La golpea HitboxJugador |
| 4 | **HitboxJugador** | `8` | Ataques del jugador: balas de todas las armas y granadas | Afecta solo a EnemyHurtbox y Terreno |
| 5 | **HitboxEnemigo** | `16` | Ataques enemigos (balas, obuses, billetes de Massa) y peligros del mapa (minas) | Afecta solo a MainHurtbox y Terreno |
| 6 | **Interactivos** | `32` | Objetos especiales del mapa: armas y cajas de bombas para recoger, jump hitbox (puntos de doble salto) | Solo reaccionan al jugador |
| 7 | **Zonas** | `64` | Áreas invisibles que disparan eventos (`zona.gd`): puerta del edificio grande, salida del interior | Solo detectan al jugador (MainHurtbox) |

### Reglas

- **ARQ-10 ✅ Cada capa solo para su uso.** Un objeto va en la capa que describe la tabla según **lo que hace**, no según lo que parece.
- **ARQ-11 ✅ Terreno solo para pisar y chocar.** En la capa 1 solo va lo que el jugador y los enemigos pisan o contra lo que chocan (suelo, cuestas, paredes, plataformas). 🛑 No van hitbox, hurtbox, sensores, zonas ni objetos interactivos.
- **ARQ-12 ✅ Choque físico solo con Terreno.** El jugador y los enemigos solo chocan físicamente con Terreno; entre ellos se atraviesan, como en Metal Slug.
- **ARQ-13 ✅ Cada ataque solo daña a su objetivo.** HitboxJugador afecta solo a EnemyHurtbox y Terreno. HitboxEnemigo afecta solo a MainHurtbox y Terreno. Un peligro que daña a los dos bandos puede afectar a la vez a MainHurtbox y EnemyHurtbox.
- **ARQ-14 ✅ Interactivos y Zonas solo detectan al jugador.**
- **ARQ-15 ✅ Tipos por grupo o script, no por capa.** Dentro de Interactivos y Zonas, cada tipo (arma, jump hitbox, puerta…) se distingue por su grupo o su script. 🛑 Una capa nueva es un cambio de regla.
- **ARQ-16 ✅ Capas por valor.** En el código cada capa se escribe con su **valor** (1, 2, 4, 8, 16, 32, 64), no con su número, y con un comentario con su nombre: `collision_layer = 32  # Interactivos`.
- **ARQ-17 ✅ Todo cambio de capas se apunta aquí.** Si un script nuevo usa una capa, se añade a la tabla "Quién usa cada capa" en el mismo PR.

### Excepciones aprobadas (no son violaciones)

| Excepción | Dónde | Por qué |
|---|---|---|
| La mina está en dos capas: HitboxEnemigo + EnemyHurtbox `16 \| 4` | `mine.gd` | Es un peligro y además se puede disparar |
| Los barriles y las cápsulas voladoras están en EnemyHurtbox | `barrel.gd`, `pickup.gd` | El jugador los rompe a tiros (☐ falta confirmar si tendrán capa propia) |
| Las plataformas atravesables son Terreno con el grupo `plataforma` | `level.gd`, `edificios.gd` | Se distinguen por grupo y colisión "one-way" (☐ provisional) |
| El cuerpo del jugador y de cada enemigo es su propia hurtbox | `player.gd`, enemigos | Hasta que se separen cuerpo y zona de daño (☐ pendiente) |
| El sensor de contacto del héroe (`hurt`) no tiene capa y mira EnemyHurtbox | `player.gd` | Daño por contacto provisional (☐ pendiente) |
| Las explosiones no usan capas: dañan por distancia y por grupo | `level.blast()` | Así una explosión daña a todo lo que está en su radio |
| Granadas y jump hitbox se detectan con consultas de física, no con señales | `level.touches_terrain()`, `player._try_jump_hitbox()` | Para comprobar el contacto solo en el momento justo |

### Quién usa cada capa en el código

| Script | Capa (valor) | Detecta (máscara) |
|---|---|---|
| `level.gd` (suelo y plataformas) | Terreno `1` | — |
| `player.gd` (cuerpo) | MainHurtbox `2` | Terreno `1` |
| `player.gd` (sensor de contacto `hurt`) | — | EnemyHurtbox `4` |
| `soldier.gd`, `massa.gd`, `politician.gd`, `miniboss.gd`, `tank.gd`, `turret.gd`, `boss.gd`, `heli.gd`, `boss_part.gd` | EnemyHurtbox `4` | Terreno `1` (o nada si no se mueven) |
| `barrel.gd` | EnemyHurtbox `4` | — |
| `mine.gd` | HitboxEnemigo + EnemyHurtbox `16 \| 4` | MainHurtbox `2` |
| `pickup.gd` (cápsula voladora) | EnemyHurtbox `4` | — |
| `pickup.gd` (objeto en el suelo) | Interactivos `32` | MainHurtbox `2` |
| `jump_hitbox.gd` | Interactivos `32` | — (el héroe lo busca con una consulta desde su zona de agarre y su cuerpo) |
| `zona.gd` (puerta de edificio grande, salida de interior) | Zonas `64` | MainHurtbox `2` |
| `tirador_ventana.gd` | EnemyHurtbox `4` solo mientras está asomado | — |
| `bullet.gd` del jugador | HitboxJugador `8` | Terreno + EnemyHurtbox `1 \| 4` |
| `bullet.gd` enemiga | HitboxEnemigo `16` | Terreno + MainHurtbox `1 \| 2` |
| `grenade.gd` (granada del jugador) | HitboxJugador `8` | — ; explota solo al tocar Terreno (`level.touches_terrain()`) |
| `bomb.gd` (granadas y bombas enemigas) | — | Explota al tocar Terreno (`level.touches_terrain()`); no al tocar al jugador |
| `massa_shot.gd` | HitboxEnemigo `16` (los billetes decorativos, ninguna) | MainHurtbox `2` |

### Pendientes de colisión ☐

1. **Plataformas atravesables:** hoy son Terreno con el grupo `plataforma`. Para bajar (Abajo + Saltar), el jugador ignora esa plataforma durante 0,35 s, y las balas la atraviesan. Falta decidir cómo funcionan definitivamente.
2. **Cuerpo y zona de daño separados:** cuando se definan, cada personaje tendrá su cuerpo (solo para pisar Terreno) y un área aparte en su capa de daño.
3. **Daño por contacto:** según las reglas, debería ser una HitboxEnemigo de contacto en cada enemigo, no un sensor del jugador.
4. **Barriles:** confirmar si se quedan en EnemyHurtbox o tienen una capa propia de objetos destructibles.
5. **Interactivos y Zonas:** decidir cómo se colocan en el diseño final (a mano o con un generador) y los demás tipos de zona (elegir ruta, cinemáticas…).

---

## 2. Capas visuales ☐ por definir (3 o 4 capas)

El equipo aún decide si serán 3 o 4 capas. Mientras tanto, el orden de hoy es **provisional**:

| Capa visual | Qué va | Orden (hoy) |
|---|---|---|
| **Fondo ambiental** | Lo lejano, con parallax: cielo, sol, aves, montañas | `CanvasLayer -10` (cielo) y `z -9` |
| **Fondo principal** | Edificios y escenario cercano: fachadas, selva, ruinas; detalles bajo el suelo; vecinos y puertas | `z -8` a `z -1` |
| **Personajes y objetos de juego** | Terreno, jugador, enemigos, jefes, objetos, efectos (polvo, sangre), balas, avisos de bomba, explosiones | `z 0` a `z 10` |
| **Primer plano** (quizá no se quede) | Lo que pasa por delante del jugador | Reservado: `z 20` o más. Hoy no hay nada |
| HUD y pausa (no es escenario) | Interfaz | `CanvasLayer 1` y `CanvasLayer 100` |

- **ARQ-20 ✅ Arte y reglas separados.** Cambiar el arte (un sprite, un fondo, el orden de dibujo) nunca cambia las reglas del juego, y al revés. Las capas visuales no tienen colisión.
- **ARQ-21 ☐ Mientras no se decida**, las cosas nuevas van en el rango de la tabla que les corresponde. ⚠ Crear una capa visual nueva, usar el Primer plano o cambiar los rangos de `z` es un WARNING.

Pendientes: decidir 3 o 4 capas; si la nieve que cae (`snowfall`, hoy en `z 3`) va al Primer plano; fijar el orden dentro de "Personajes" (hoy jugador, enemigos, jefe y terreno comparten `z 0` y va delante el que se creó después).

### Greybox (modo test)

En **modo test** la fase se ve con bloques grises etiquetados en vez del arte (`scripts/greybox.gd`). **F1** cambia entre los dos. Es una capa opaca en `z 50`, por encima del mundo y por debajo del HUD; en producción siempre se ve el arte.

- **Escenario en grises**, de lejos (oscuro) a cerca (claro): edificios con su número, tipo y pisos, ventanas, puertas y flechas "SIGUE ARRIBA"; vereda, suelo y plataformas con su altura. Cuadrícula de 16 px contada desde el suelo (y = 230).
- **Personajes y objetos:** su caja de colisión real con el borde del color de su capa, su nombre y su medida.
- **Del héroe:** línea de tiro (amarillo), zona para devolver granadas (círculo rojo) y zona de agarre de los jump hitbox (círculo cian, se inclina hacia el más cercano).
- **Colores por capa:** verde = MainHurtbox, rojo = EnemyHurtbox, amarillo = HitboxJugador, magenta = HitboxEnemigo, cian = Interactivos, azul = Zonas. Contorno blanco tenue = áreas sin capa.

---

## 3. Arte (pixel art)

"Arte" es **todo el pixel art**: diseño de los personajes, jefes y enemigos, fondos, escenarios, props, efectos, fuente, logo y HUD.

- **ARQ-30 ✅ El arte actual es el diseño a respetar.** ⚠ Cualquier cambio drástico es un WARNING: se avisa antes, se deja un antes/después en `referencias/antes-despues/` (ARQ-60) y se menciona en el PR. Es drástico:
  - cambiar el diseño, la silueta, la paleta o las proporciones de un personaje, enemigo o jefe;
  - cambiar el tamaño de fotograma o el punto de los pies (48x48 con los pies en (24, 46));
  - cambiar la escala de un escenario (por ejemplo `ESCALA` 1.2 en `pueblo.py`) o el orden de sus piezas (`CALLE`);
  - quitar, sustituir o redibujar fondos o props;
  - cambiar la resolución interna (480x270).

  **No es drástico:** retocar píxeles sueltos, corregir un fotograma, añadir una animación nueva respetando el diseño, o un efecto nuevo.
- **ARQ-31 ✅ Los PNG salen de su generador.** Los PNG de `assets/sprites/` los generan los scripts de `tools/sprites/`. Se cambian editando el generador y ejecutándolo, o retocando el PNG en Aseprite. Si se mueve el arma en un sprite, se regenera su `*_meta.json`. Las imágenes originales (`tools/sprites/pixellab/`, `chatgpt/`, `spritefusion/`) no se borran ni se sobrescriben.
- **ARQ-32 ✅ Una sola fuente.** Todo el texto usa `scripts/pixel_font.gd` (`PixelFont`); nunca la fuente por defecto de Godot.

---

## 4. Largo de los mapas (escenas)

Una **escena** es una pantalla de juego: **480 px** de ancho (`SCREEN_W`).

- **ARQ-40 ✅ Todo mapa mide un número exacto de escenas.** El largo de cada fase y de cada interior (`"end"` en `scripts/levels.gd`) es un múltiplo exacto de 480 px y se escribe como `N * SCREEN_W`. La arena del jefe es siempre la última escena.
- **ARQ-41 ✅ El arte de los escenarios se trabaja por escenas.** El arte nuevo de un escenario se diseña y se reparte en escenas enteras de 480 px.
- **ARQ-42 ✅ El largo de la fase 1.1 está fijado: 31 escenas (14 880 px).** ⚠ Cambiar el largo de cualquier fase es un WARNING.

| Mapa | Escenas | Píxeles | Estado |
|---|---|---|---|
| 1.1 Pueblo de la pampa | 31 | 14 880 | ✅ fijado (26-10-2026: antes 15 000, 31,25 escenas) |
| Demás fases (plantillas sin `"end"` propio, `END`) | 7 | 3 360 | Provisional (26-10-2026: antes 3 000, 6,25 escenas; se alargó para no meter enemigos en la arena del jefe) |
| Interior del MUSEO | 3 | 1 440 | Provisional (26-10-2026: antes 1 500) |

Pendiente ⚠: el arte de la calle de la 1.1 llega a **5 856 px (12,2 escenas)**; el resto de la fase solo tiene suelo, para trabajar en greybox. Para que cuadre en escenas enteras habría que dejarlo en 12 escenas (5 760 px, recortando 96 px) o en 13 (6 240 px, añadiendo 384 px). Es un cambio de arte (ARQ-30) y lo decide el equipo.

---

## 5. Archivos y nombres

- **ARQ-50 ✅ Se respeta la estructura de carpetas actual.** ⚠ Mover o renombrar un archivo existente es un WARNING: rompe los `preload` y las ramas de los demás.
- **ARQ-51 ✅ Se respeta la nomenclatura actual.** La persona puede elegir el nombre; si no lo hace, la IA elige el más claro siguiendo estas reglas.

### Estructura

| Carpeta | Qué va | Nombres |
|---|---|---|
| `scripts/` | Un script por entidad o sistema | `<nombre>.gd` y su `<nombre>.gd.uid` (los dos se suben) |
| `scenes/` | Una escena por pantalla (`intro`, `menu`, `select`, `map`, `level`); el contenido se crea por código | `<pantalla>.tscn` |
| `assets/sprites/` | Sprites del juego, generados | ver tabla de prefijos |
| `tools/sprites/` | Generadores en Python | `<tema>.py` |
| `tools/sprites/<pixellab\|chatgpt\|spritefusion>/<tema>/` | Imágenes originales de cada herramienta | carpeta por tema |
| `docs/` | `diseno.md` (diseño vivo), `historia.md`, `plan-metal-slug.md` | — |
| `docs/propuestas/<tema>/` | Propuestas que aún no tocan el juego, con su `README.md` | carpeta por tema |
| `tests/` | Prueba automática (`autoplay.gd`) | — |
| `referencias/` | Medidas y antes/después para el equipo (ARQ-60) | ver sección 6 |
| Raíz | `ARQUITECTURA.md`, `CLAUDE.md`, `README.md` y la configuración de Godot | — |

### Nombres

- **Archivos y carpetas:** minúsculas con guion bajo (`tirador_ventana.gd`), sin espacios, tildes ni ñ.
- **Idioma:** lo nuevo se nombra en español, como los scripts más recientes (`edificios`, `zona`, `polvo`, `tirador_ventana`). Los nombres en inglés que ya existen (`player`, `soldier`, `bullet`…) no se renombran.
- **Código GDScript:** tabuladores, tipado estático cuando se pueda, comentarios en español (`##` para documentar), constantes en `MAYUSCULAS_CON_GUION`, variables y funciones en `minusculas_con_guion`, funciones internas con `_` delante. Sin `class_name`: los scripts se cargan con `const Nombre = preload("res://scripts/nombre.gd")`. Los cambios de valor se anotan con fecha: `# 26-10-2026: antes 240`.
- **Controles:** las acciones de entrada se registran solo en `Game._setup_input()` (`scripts/game.gd`); las teclas del modo test, solo en `scripts/modo_test.gd`. ⚠ Usar una tecla ya ocupada es un WARNING.
- **Ramas:** `<persona>/<tema>`, por ejemplo `eduardo/nivel-2`.

### Prefijos de sprites (`assets/sprites/`)

| Prefijo | Qué es | Ejemplo |
|---|---|---|
| `player_<héroe>_<parte>` | Soldados jugables | `player_junnie_body.png` |
| `soldier_<país o tema>` | Soldados enemigos | `soldier_ar.png` |
| `boss_<id>` | Jefes animados | `boss_massa.png` |
| `pol_<id>` | Políticos con sprite estático | `pol_milei.png` |
| `tank_<tipo>`, `turret_<tipo>`, `mecha_<pieza>` | Vehículos y piezas | `tank_usa.png` |
| `bg_<tema>`, `ground_<tema>` | Fondo y suelo de un escenario | `bg_pueblo.png` |
| `<tema>_tramo_NN` | Trozos de un escenario largo | `pueblo_tramo_03.png` |
| `cine_<cosa>` | Cinemáticas | `cine_heli.png` |
| `<nombre>_meta.json` | Filas de animación, pivotes y bocas de cañón de una hoja | `soldier_ar_meta.json` |

---

## 6. Carpeta `referencias/` (antes y después)

- **ARQ-60 ✅ Los antes/después van a `referencias/antes-despues/`.** Cuando alguien pide un cambio y quiere ver el antes y el después, la IA deja el resultado en `referencias/antes-despues/<AAAA-MM-DD>_<tema>/`:
  - `antes.png` y `despues.png` (o `antes_1.png`, `despues_1.png`… si son varias);
  - `nota.md`: qué cambió, quién lo pidió y en qué rama.

  Se sube en el mismo PR, para que todo el equipo lo vea.
- `referencias/` tiene un `.gdignore`: Godot no la importa y no va dentro del `.exe`. No se borra.

---

## 7. Fusiones (merge)

- **ARQ-70 ✅ Antes de fusionar, la IA revisa los riesgos y los lista.** No hace falta analizar todo el proyecto, solo lo que cambió en cada rama desde su punto común con `main` y lo que depende de eso:
  1. **Conflictos de texto:** los marca git. Se revisan uno a uno.
  2. **Conflictos ocultos** (git fusiona sin quejarse, pero juntas se rompen):
     - una función, constante, grupo o archivo renombrado o borrado que la otra rama sigue usando;
     - la misma tecla o acción usada para dos cosas;
     - una capa de colisión usada de otra forma (sección 1);
     - el largo de un mapa o la posición de entidades cambiados en las dos ramas (sección 4);
     - la misma escena `.tscn` / `.tres` editada en las dos ramas;
     - el mismo sprite regenerado en las dos ramas;
     - cambios en `project.godot`, en los autoloads (`game.gd`, `juice.gd`) o en `levels.gd`.
  3. **Reglas:** que ningún cambio rompa este documento.
  4. **Comprobación:** después de fusionar, compilar el proyecto y correr la prueba automática (`CLAUDE.md`, "Probar").
- **ARQ-71 ✅ Cómo se resuelven.** Los `.tscn` / `.tres` no se mezclan a mano: se elige una versión y se rehace el cambio de la otra. Los PNG y `*_meta.json` no se mezclan: se vuelve a ejecutar el generador. Si un conflicto toca código de otra persona, se resuelve con ella.
- **Formato del informe:**

```
RIESGOS DE FUSIÓN · rama eduardo/tienda → main
1. ⚠ scripts/game.gd: las dos ramas añaden una acción en Shift ("slide" y "tienda"). Propuesta: mover "tienda" a Tab.
2. 🛑 scripts/trampa.gd: área de daño en Terreno (ARQ-11). Propuesta: HitboxEnemigo (16).
3. ✅ Sin conflictos de texto. Compila sin errores.
```
