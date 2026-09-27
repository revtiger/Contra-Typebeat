# Documento de diseño: ONU: Outbreak

Autores: Gwyn y Eduardo · Última revisión: 27-09-2026 (v0.6)

> **Dirección nueva (27-09-2026):** el juego pasa a estilo Metal Slug. El plan de trabajo está en [`plan-metal-slug.md`](plan-metal-slug.md).

> Sustituye al borrador de Word ("Colibrí Veloz"), que era un ejemplo de plantilla. Se mantiene su estructura. Lo marcado con ☐ está por decidir.

## Resumen

**ONU: Outbreak** (antes Contra-Typebeat) es un run and gun 2D de desplazamiento lateral inspirado en Contra: un soldado recorre América de sur a norte disparando en 8 direcciones contra oleadas de enemigos, tanques y bombardeos. Cada misión tiene un mini jefe a mitad de camino y un jefe final, y entre misiones un mapa muestra la ruta.

**Historia:** ☐ por definir. Propuesta de Eduardo adaptada con personajes inventados en [`historia.md`](historia.md). El General Zarko y El Socio se descartaron, y Gwyn y Eduardo (los autores) no son personajes de la historia. La intro no cuenta historia: es de título, como la de Metal Slug 2.

**Soldados jugables (ficticios):** El Presi (traje y banda presidencial tricolor), La Tenienta (coleta y pañuelo rojo), El Chato (gorra azul hacia atrás) y Don Bigotes (veterano con casco, bigote canoso, parche y puro). Se eligen en ELIGE TU SOLDADO y cambian el sprite con el que se juega.

**Ruta de la campaña:** Argentina–Brasil (Triple Frontera) → Bolivia → frontera México–EE.UU. → EE.UU.: reunión secreta de la ONU en Nueva York (propuesta de Eduardo, próximamente).

| Aspecto | Definición |
|---|---|
| Género | Run and gun / acción arcade |
| Motor | Godot 4.7.2 |
| Plataforma | PC (Windows) ☐ ¿también navegador? |
| Duración de un nivel | 3 a 5 minutos (3 misiones jugables en la v0.5) |
| Público | Fans de los arcade clásicos que buscan reto |
| Meta del jugador | Llegar al final del nivel y vencer al jefe sin perder todas las vidas |

## Pilares de diseño

1. **Acción inmediata**: se dispara desde el primer segundo; nada de tutoriales largos.
2. **Difícil pero justo**: cada muerte se entiende; las balas enemigas son lentas y visibles.
3. **Una más**: reinicio instantáneo, puntuación y récord siempre visibles.

Cómo se aplican los pilares a los peligros: todo lo que mata avisa antes (marca roja de las bombas, pitido de las minas, obuses lentos que se esquivan tumbándose).

## Bucle de juego principal

Avanzar → aparecen enemigos → apuntar y disparar → esquivar balas saltando o tumbándose → recoger mejoras de arma → jefe al final del nivel.

Al morir se pierde el arma especial y se reaparece en el mismo punto con 2 s de invulnerabilidad. Sin vidas: Game Over, y con Enter se reintenta la misión al instante.

**HUD estilo Metal Slug:** arriba a la izquierda la puntuación, `1UP=` con las vidas y el recuadro metálico **ARMS** (munición, ∞ con la pistola) / **BOMB** (granadas), más el icono con la letra del arma especial; arriba al centro **TIME** con números cromados; arriba a la derecha el récord. Carteles con letra grande de degradado amarillo a rojo.

**TIME:** empieza en 60 y baja 1 cada 4 segundos. En los últimos 10 parpadea en rojo y pita; a 0 el jugador muere. Se reinicia al reaparecer, al aparecer un mini jefe y al llegar al jefe final.

**Flujo de pantallas:** intro estilo Metal Slug 2 (se salta con cualquier botón) → menú (Jugar, Elegir misión, Controles, Ver intro, Salir) → **ELIGE TU SOLDADO** (estilo Metal Slug X, cuenta atrás de 30) → **mapa** con la ruta → misión (mini jefe + jefe final) → "Misión cumplida" → **mapa** con el siguiente destino → … Si la siguiente misión aún no existe, el mapa la marca como "PRÓXIMAMENTE" y vuelve al menú. Esc pausa la partida.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta o stick |
| Apuntar arriba | Arriba | Cruceta arriba |
| Disparar hacia abajo (solo en el aire) | Abajo | Cruceta abajo |
| Agacharse (se puede avanzar agachado) | Abajo | Cruceta abajo |
| Saltar | Z / Espacio / K | A |
| Bajar de un puente | Abajo + Saltar | Abajo + A |
| Disparar (mantener) / cuchillo automático de cerca | X / J | X |
| Granada | C / L | B / Y |
| Pausa | Esc / P | Start |
| Reintentar tras Game Over | Enter / R | Start |
| Salir al menú (en pausa o Game Over) | Q | Select |

## Enemigos, armas y objetos

| Elemento | Tipo | Qué hace | Estado |
|---|---|---|---|
| Soldado corredor | Enemigo | Corre en línea recta, salta escalones, muere de 1 tiro. Algunos se asustan al verte (brazos arriba) y huyen | ✅ |
| Granadero | Enemigo | Se planta y lanza granadas en arco con marca de aviso | ✅ |
| Francotirador | Enemigo | Quieto, apunta en 8 direcciones, 2 tiros | ✅ |
| Torreta | Enemigo | Gira hacia el jugador (12 direcciones), 8 tiros | ✅ |
| Muro-fortaleza | Jefe (misión 1) | 2 cañones con ráfaga triple, suelta soldados, 70 de vida | ✅ |
| Tanque | Enemigo | Avanza y dispara obuses rasantes: se esquivan saltando o tumbándose. 20 de vida | ✅ |
| Barril explosivo | Objeto | Estalla al dispararle y daña todo alrededor; reacción en cadena | ✅ |
| Mina | Peligro | Al pisarla pita y explota 0,4 s después; si sigues corriendo te salvas | ✅ |
| Bombardeo aéreo | Evento | Un caza cruza y suelta 4 bombas; marcas rojas avisan dónde caen | ✅ |
| Helicóptero | Jefe (misión 2) | Ráfagas apuntadas, bombas con aviso y abanico de balas a media vida. 110 de vida | ✅ |
| Comandante Kruger | Mini jefe (misión 1) | Ametralladora a la altura del pecho (se esquiva tumbándose), granadas con aviso, salto con triple disparo. 45 de vida | ✅ |
| La Presidenta Mecha | Jefe (misión 3) | Mecha gigante por piezas con patas de araña: brazo ametralladora (ráfagas en abanico), dos cápsulas de misiles que caen con aviso y pisotón con onda que hay que saltar. Cada pieza se rompe por separado y se lleva su ataque; la cabeza es punto débil (daño doble) | ✅ |
| Camión lanzacohetes | Mini jefe (misión 2) | Cohetes que caen del cielo con marca en el suelo (5 a media vida) y artillero que apunta. 60 de vida | ✅ |
| Cápsula voladora | Objeto | Cruza la pantalla; al dispararle suelta un arma o una caja de bombas (B, +10). Si no se recoge, parpadea y desaparece a los 9 s | ✅ |
| Pistola | Arma | Munición infinita; es el arma a la que se vuelve | ✅ |
| H: ametralladora pesada | Arma | 200 balas, cadencia muy alta con algo de dispersión | ✅ |
| R: cohetes | Arma | 30 cohetes que buscan al enemigo más cercano y explotan | ✅ |
| F: llamas | Arma | 30 llamaradas cortas que crecen y atraviesan | ✅ |
| L: láser | Arma | 200 disparos que atraviesan enemigos | ✅ |
| S: escopeta | Arma | 30 disparos en abanico de corto alcance, mucho daño | ✅ |
| Granada | Arma | 10 por vida; rebota una vez y explota; no daña al jugador | ✅ |
| Cuchillo | Arma | Automático al disparar con un soldado pegado delante | ✅ |

Las armas especiales tienen **munición limitada**: al acabarse se vuelve a la pistola. Recoger la misma arma suma munición. Al morir se pierde el arma y las bombas vuelven a 10.

**Sensación de impacto (autoload `Juice`):** el juego se congela un instante (*hitstop*) al matar, con las explosiones de granada y al morir; la cámara tiembla con los disparos pesados y las explosiones; los soldados salen despedidos girando al morir.

## Niveles

Los mini jefes bloquean la cámara al aparecer hasta que se les derrota.

1. **Argentina–Brasil: Triple Frontera** ✅ (selva): fosos de agua, puentes, un escalón elevado, mini jefe Comandante Kruger y La Fortaleza Roja al final.
2. **Bolivia: Quebradas de Tupiza** ✅ (árido): mesetas rojas, dunas y cactus; cañones sin fondo, barriles, minas, 2 tanques, 2 bombardeos, mini jefe Camión lanzacohetes y el Helicóptero Cóndor al final.
3. **Frontera México–EE.UU.** ✅ (ciudad al atardecer): calles en ruinas, edificios coloniales con cúpulas, carteles de propaganda inventados, 2 tanques, 2 bombardeos, mini jefe Comandante Kruger y La Presidenta Mecha al final. ☐ Falta el tramo de la escuela del que se habló.
4. **EE.UU.: reunión secreta de la ONU** ☐ (próximamente).

## Estilo visual y sonido

- Pixel art a 480x270, fondos con parallax (cielo al atardecer, montañas, palmeras).
- **Intro estilo Metal Slug 2:** presentación tipo NEO GEO ("G·E, MAX 480x270 PIXEL POWER"), las letras gigantes de ONU caen de una en una y después OUTBREAK en piedra cincelada con golpe y polvo, y un fogonazo las pasa a oro sobre cielo azul con "SUPER SOLDADO-001", "PULSA START" y el copyright de G·E STUDIOS.
- **Letras de logo cinceladas** (`tools/sprites/logo.py`): cursiva, bisel y relieve 3D, en piedra, oro y acero. Se usan en la intro, el menú y los títulos de pantalla.
- **ELIGE TU SOLDADO estilo Metal Slug X:** marco de acero remachado, retratos de cómic (el elegido a color, el resto en sepia), placas con el nombre y cuenta atrás.
- **Sprites (v0.5):** el protagonista (traje, banda presidencial tricolor, mochila y rifle; cara inventada), los soldados (selva y desierto) y La Presidenta Mecha ya son sprites PNG en `assets/sprites/`. Los generan los programas de `tools/sprites/` y se pueden retocar en Aseprite. El protagonista tiene piernas y torso separados, como en Metal Slug. Siguen dibujados por código: torretas, tanques, mini jefes, jefes de las misiones 1 y 2 y objetos.
- Música y efectos generados por código (estilo 8 bits): tema de menú, uno por misión y uno de jefe. ☐ Sustituir por música compuesta si alguien se anima.

## Alcance del primer prototipo

| Entra | Queda para después |
|---|---|
| Nivel 1 completo con jefe ✅ | Más niveles |
| Movimiento, salto, tumbarse, 8 direcciones ✅ | Modo 2 jugadores |
| 5 armas ✅ | Sprites y animaciones |
| Formas simples ✅ | Opciones (volumen, pantalla completa) |
| Vidas, puntos, récord, Game Over ✅ | |
| Intro, menú, pausa, sonido y música ✅ (v0.2) | |
| Nivel 2 Desierto con jefe ✅ (v0.2) | |
| Intro estilo póster, mapa de campaña, mini jefes y armas que desaparecen ✅ (v0.3) | |
| Intro estilo Metal Slug 2, ELIGE TU SOLDADO con 4 soldados, logo cincelado, fuente única ✅ (v0.6) | |

## Preguntas abiertas

- ☐ Misión 3 (México–EE.UU.): empieza en una escuela, ¿y luego qué? ¿Qué papel tiene la escuela (base enemiga abandonada, refugio)?
- ✅ Personajes: **ficticios**. Se puede parodiar el cargo (banda presidencial, propaganda inventada), pero sin la cara, el nombre ni los lemas reales de personas concretas.
- ✅ Controles: **100 % Metal Slug** (sin disparo diagonal).
- ✅ Arte: sprites generados con IA que se van ajustando a mano en Aseprite.
- ☐ ¿Modo cooperativo de 2 jugadores en la misma pantalla?
- ☐ ¿Solo PC o también exportar a navegador?
- ☐ ¿Cuántos niveles para la primera versión completa?
- ☐ ¿Quién se encarga del arte y quién del sonido?
- ☐ ¿Se publica (itch.io, Steam) o es proyecto personal?
