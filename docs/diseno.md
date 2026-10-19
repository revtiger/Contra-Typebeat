# Documento de diseño: ONU: Outbreak

Autores: Gwyn y Eduardo · Última revisión: 09-10-2026 (v0.7 en `main`; propuestas al día)

> **Dirección nueva (27-09-2026):** el juego pasa a estilo Metal Slug. El plan de trabajo está en [`plan-metal-slug.md`](plan-metal-slug.md).

> Sustituye al borrador de Word ("Colibrí Veloz"), que era un ejemplo de plantilla. Se mantiene su estructura. Lo marcado con ☐ está por decidir.

## Resumen

**ONU: Outbreak** (antes Contra-Typebeat) es un run and gun 2D de desplazamiento lateral inspirado en Contra y Metal Slug: un soldado recorre Argentina, México, EUA y Alemania hasta el nivel secreto de la ONU, disparando contra oleadas de enemigos, tanques y bombardeos. Cada país tiene 3 fases y cada fase termina con un jefe político; entre fases un mapa muestra la ruta.

**Historia:** ✅ aceptada (29-09-2026) la propuesta de Eduardo *ONU: Trying to save the world*: la Orden Mundial, 4 países (Argentina, México, EUA, Alemania) + nivel secreto en la ONU, con caricaturas de políticos reales. Detalle en [`historia.md`](historia.md). El General Zarko y El Socio se descartaron, y Gwyn y Eduardo (los autores) no son personajes de la historia. **Excepción (30-09-2026, decisión de Eduardo):** Eduardo y Eder sí son soldados jugables en ELIGE TU SOLDADO. La intro no cuenta historia: es de título, como la de Metal Slug 2.

**Soldados jugables (18-10-2026: quedan 3):** **Junnie** (pelo largo castaño, camiseta granate, chaleco y pantalón negros; diseño de Eduardo con ChatGPT, `tools/sprites/chatgpt/junnie/`) sustituye a La Tenienta. Sus 5 hojas de poses de ChatGPT (`sprites_junnie_N.png`) se montan con `heroes_sheets.py` como las de Eduardo y Eder; quieta (con el pelo meciéndose) y las tres carreras (de frente, apuntando arriba y en diagonal, 10 fotogramas con el pelo al viento) están animadas con PixelLab (`tools/sprites/junnie_pixellab.py`). El Presi se quitó. También juegan **Eduardo** (pelo negro, camiseta negra y chaleco verde oliva, pantalón caqui) y **Eder** (pelo castaño corto, camisa de flores, pantalón gris), diseñados por Eduardo con ChatGPT (30-09-2026, `tools/sprites/chatgpt/`). Eduardo y Eder usan **sprites de cuerpo entero** montados por `tools/sprites/heroes_sheets.py`: quieto, correr, saltar, agacharse, disparar, granada, cuerpo a tierra, cuchillo, victoria, muerte (cae de espaldas, 8 fotogramas) y **apuntar arriba, en diagonal hacia arriba (quietos y corriendo) y en diagonal hacia abajo** (16-10-2026). Desde el 16-10-2026 se pasan a pixel art de verdad: paleta común de 48 colores, contorno oscuro de 1 px, fogonazo quitado de las poses (lo dibuja el juego en la boca del arma de cada dirección) y fogonazo de verdad (`player_<id>_flash.png`, el que venía en las poses, pequeño y grande por dirección). **Carrera al estilo Metal Slug:** piernas de la carrera de 10 fotogramas del amigo de Eduardo (en Eder, con el pantalón recoloreado a gris) y torso firme con el arma recta, con un rebote de hasta 2 px; igual al correr apuntando arriba o en diagonal. El fogonazo sale de la punta del cañón de cada fotograma (`tips` del meta). **Abajo = cuerpo a tierra** (Eduardo y Eder): se tiran al suelo, quedan tumbados (alto 12 px: las balas a la altura del pecho les pasan por encima) y se arrastran al moverse. ☐ Sin usar todavía: barrida y paracaídas (están en las hojas 4 y 5). El Chato y Don Bigotes se quitaron. Se eligen en ELIGE TU SOLDADO y cambian el sprite con el que se juega.

**Ruta de la campaña (v0.7, en el código):** Argentina → México → EUA → Alemania → nivel secreto en la ONU, 15 fases (ver "Niveles" y [`historia.md`](historia.md)). La ruta anterior (Triple Frontera → Bolivia → Frontera Norte) se sustituyó; sus jefes (Fortaleza Roja, Helicóptero Cóndor, Comandante Kruger, Camión) siguen en el código pero ya no aparecen.

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

**Flujo de pantallas:** intro estilo Metal Slug 2 (se salta con cualquier botón) → menú (Jugar, Elegir fase, Controles, Ver intro, Salir) → **ELIGE TU SOLDADO** (estilo Metal Slug X, cuenta atrás de 30) → **mapa mundial** con la ruta y el jefe de la fase → fase → "¡Fase X.Y superada!" (o "¡País liberado!" tras el jefe final) → **mapa** → … → tras la fase 5.3, "¡Apocalipsis detenido!" y el mapa con "¡Mundo salvado!" vuelve al menú. Esc pausa la partida.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta o stick |
| Apuntar arriba | Arriba | Cruceta arriba |
| Disparar hacia abajo (solo en el aire) | Abajo | Cruceta abajo |
| Disparar en diagonal hacia arriba | Arriba + izquierda/derecha | Cruceta en diagonal |
| Disparar en diagonal hacia abajo (solo en el aire) | Abajo + izquierda/derecha | Cruceta en diagonal |
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
| Jefes políticos | Minijefe / jefe final | Caricaturas de PixelLab (`politician.gd`): esperan fuera de pantalla, entran andando al llegar a la arena y combinan ataques ☐ **provisionales** (ráfaga, abanico, granadas, bombas del cielo, soldados, embestida, onda rasante, salto). Los jefes finales se enfurecen a media vida. Al perder salen volando dando vueltas ("¡Recibió su merecido!"), sin sangre | ✅ |
| **Sergio Massa** (animado) | Minijefe 1.1 | Mide 60 px (×1,25 Eduardo). Dos poses de Eduardo (ChatGPT, de traje y de chaleco) animadas con PixelLab (`massa.gd`, `tools/sprites/massa.py`). **De traje:** **Doble granada** (como un lanzador de béisbol, lanza una con cada mano: una al jugador y otra delante o detrás de él; ya no hay discursos, promesas ni fajos de billetes), **¡Pulgar arriba!** (llama a 2 militantes). A media vida **se saca el saco** ("¡SE SACÓ EL SACO!", invulnerable mientras tanto), lo tira y agarra un rifle: **de chaleco** dispara ráfagas de 4 balas apuntadas, camina más rápido, suda y llama militantes a gritos. Al perder sale volando y se le cae una lluvia de billetes de los bolsillos. 70 de vida | ✅ |
| Transfiguración | Jefe final 2.3 | Sheinbaum se transforma en **La Presidenta Mecha** (el mecha por piezas) | ✅ |
| Ritual del pentagrama | Jefe final 5.3 | Tras vencer al líder de la Orden aparecen los jefes finales en las puntas de un pentagrama, giran y se fusionan en **La Orden Fusionada** (flota, 260 de vida, todos los ataques) | ✅ |
| Puerta blindada | Objetivo (5.1, 5.2) | Fin de fase en el nivel secreto: se abre al llegar | ✅ |
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

**Sensación de impacto (autoload `Juice`):** el juego se congela un instante (*hitstop*) al matar, con las explosiones de granada y al morir; la cámara tiembla con los disparos pesados y las explosiones; los soldados salen despedidos girando al morir. **Explosiones (16-10-2026):** animación de 12 fotogramas hecha con Sprite Fusion (`assets/sprites/explosion.png`: destello, bola de fuego, estallido y humo), escalada al radio de cada explosión, con la metralla por código. Origen en `tools/sprites/spritefusion/explosion/` (semilla de PixelLab animada con Sprite Fusion). **Impacto de bala (17-10-2026):** chispa de 6 fotogramas hecha con PixelLab (`create_vfx`, `scripts/impact.gd`, `tools/sprites/impacto.py`) donde la bala toca algo; las llamas no la sueltan.

## Niveles

15 fases en `scripts/levels.gd` (5 zonas x 3). Cada fase usa una de 5 plantillas de terreno (selva, desierto, ciudad, nieve, base) con variaciones de enemigos y armas, mide 3000 px y termina en la arena del jefe. Banderas y carteles de propaganda cambian según el país.

| Fase | Escenario | Jefe |
|---|---|---|
| 1.1 | Argentina: Pueblo de la pampa al atardecer, 4879 px, calle llana armada pieza por pieza con los edificios, árboles y valla de Eduardo, aves en el cielo (`tools/sprites/pueblo.py`, `aves.py`) | Minijefe Sergio Massa, frente a la capilla |
| 1.2 | Argentina: Quebrada de Humahuaca (desierto) | Minijefa Cristina Kirchner |
| 1.3 | Argentina: Buenos Aires, Casa Rosada (ciudad) | **Javier Milei** |
| 2.1 | México: Selva del Sureste | Minijefe AMLO |
| 2.2 | México: Desierto del Norte | Minijefe Carlos Salinas de Gortari |
| 2.3 | México: Capital, Palacio Nacional | **Claudia Sheinbaum → Presidenta Mecha** |
| 3.1 | EUA: Frontera de Texas (desierto) | Minijefe Joe Biden |
| 3.2 | EUA: Pantanos de Florida (selva) | Minijefe Barack Obama |
| 3.3 | EUA: Washington, Casa Blanca (ciudad) | **Donald Trump** |
| 4.1 | Alemania: Selva Negra (nieve) | Minijefa Angela Merkel |
| 4.2 | Alemania: Alpes Bávaros (nieve) | Minijefe Olaf Scholz |
| 4.3 | Alemania: Berlín, Bundestag (ciudad) | **Friedrich Merz** |
| 5.1 | ONU: Sótanos (base) | Puerta 1 |
| 5.2 | ONU: Laboratorio de la Orden (base) | Puerta 2 |
| 5.3 | ONU: Sala del Consejo Secreto (base) | **Líder de la Orden → La Orden Fusionada** |

☐ Pendiente: escenarios únicos por fase (ahora se repiten las 5 plantillas), habilidades definitivas de cada jefe, político aliado y ayudante religioso.

## Estilo visual y sonido

- Pixel art a 480x270, fondos con parallax (cielo al atardecer, montañas, palmeras).
- **Intro estilo Metal Slug 2:** presentación tipo NEO GEO ("G·E, MAX 480x270 PIXEL POWER"), las letras gigantes de ONU caen de una en una y después OUTBREAK en piedra cincelada con golpe y polvo, y un fogonazo las pasa a oro sobre cielo azul con "SUPER SOLDADO-001", "PULSA START" y el copyright de G·E STUDIOS.
- **Letras de logo cinceladas** (`tools/sprites/logo.py`): cursiva, bisel y relieve 3D, en piedra, oro y acero. Se usan en la intro, el menú y los títulos de pantalla.
- **ELIGE TU SOLDADO estilo Metal Slug X:** marco de acero remachado, retratos de cómic (el elegido a color, el resto en sepia), placas con el nombre y cuenta atrás.
- **Sprites (v0.5):** el protagonista (traje, banda presidencial tricolor, mochila y rifle; cara inventada), los soldados (selva y desierto) y La Presidenta Mecha ya son sprites PNG en `assets/sprites/`. Los generan los programas de `tools/sprites/` y se pueden retocar en Aseprite. El protagonista tiene piernas y torso separados, como en Metal Slug. Siguen dibujados por código: torretas, tanques, mini jefes, jefes de las misiones 1 y 2 y objetos.
- **Arte con PixelLab (IA):** ya están hechos con PixelLab los 4 retratos de ELIGE TU SOLDADO (primer plano caricaturesco, fondo oscuro) y el rascacielos en llamas animado del menú. Los originales están en `tools/sprites/pixellab/`; `portraits.py` y `tower.py` montan las hojas. ☐ Siguiente: sprites de juego de los soldados.
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
| Campaña de la Orden Mundial: 15 fases, 14 jefes políticos, nieve y base secreta, mapa mundial ✅ (v0.7) | |

## Preguntas abiertas

- ☐ Misión 3 (México–EE.UU.): empieza en una escuela, ¿y luego qué? ¿Qué papel tiene la escuela (base enemiga abandonada, refugio)?
- ✅ Personajes: **caricaturas de políticos reales** permitidas (cambio de Gwyn, 28-09-2026; antes eran solo ficticios). Los soldados jugables siguen siendo inventados. Tono de burla tipo Metal Slug / Broforce, **con sangre y gore de arcade** (cambio de Gwyn, 30-09-2026): sangre pixelada y enemigos que revientan en trozos. Eduardo tiene pase libre para decidir historia, personajes y nivel de violencia. Lista en [`historia.md`](historia.md).
- ✅ Controles: estilo Metal Slug **con disparo en diagonal** (cambio de Gwyn, 02-10-2026; antes era sin diagonales). Arriba + lado apunta en diagonal hacia arriba; en el aire, Abajo + lado apunta en diagonal hacia abajo. El Presi y La Tenienta tienen poses diagonales; Eduardo y Eder también, con las poses de la propuesta `poses_extra` (16-10-2026).
- ✅ Arte: sprites generados con IA que se van ajustando a mano en Aseprite.
- ☐ ¿Modo cooperativo de 2 jugadores en la misma pantalla?
- ☐ ¿Solo PC o también exportar a navegador?
- ☐ ¿Cuántos niveles para la primera versión completa?
- ☐ ¿Quién se encarga del arte y quién del sonido?
- ☐ ¿Se publica (itch.io, Steam) o es proyecto personal?

## Propuestas

Carpetas en [`propuestas/`](propuestas/) (con `.gdignore`: Godot no importa sus imágenes). Nada de esto está en el juego hasta que se acepte y se implemente.

| Propuesta | Estado |
|---|---|
| [`nivel1/`](propuestas/nivel1/): caricaturas de AMLO, Salinas y Sheinbaum | ✅ Aceptada e integrada (México, nivel 2) |
| [`vendedor/`](propuestas/vendedor/): vendedor GDA y su camioneta de 6 ruedas | ✅ Fusionada como diseño (PR #8); ☐ falta meterlo en el juego |
| [`poses_extra/`](propuestas/poses_extra/): poses nuevas de Eduardo y Eder (arriba, abajo, diagonal, barrida, paracaídas, muerte) | ✅ Aceptada por Gwyn (PR #9) y montada en el juego (16-10-2026): las hojas pasaron a `tools/sprites/chatgpt/sprites_<id>_3..5.png`. ☐ Barrida y paracaídas sin usar |
| [`narrativa_blue_beam/`](propuestas/narrativa_blue_beam/): la IA B.L.U.E. como antagonista oculto | ☐ Pendiente de leer por Gwyn (Eduardo tiene pase libre en historia) |


**Arte de la 1.2 y la 1.3 (17-10-2026, PixelLab):** la Quebrada de Humahuaca (cerros de colores, cardones, suelo de roca roja) y Buenos Aires (edificios antiguos y la Casa Rosada al final, donde espera el jefe) tienen fondo panorámico y suelo propios (`tools/sprites/argentina.py`). Usan el terreno de las plantillas `desert` y `city` con la ambientación `quebrada` y `baires` (cuarto dato de la fase en `ZONES`).

**Ventajas de cada soldado (Gwyn, 17-10-2026, `PERKS` en `player.gd`):** Eduardo aguanta 3 golpes antes de perder una vida, con barra de vida bajo el 1UP (caer a un foso mata igual). Eder lleva doble pistola (la pistola dispara dos balas paralelas) y empieza con 20 granadas (también al reaparecer). El Presi y La Tenienta, sin cambios.

**Tanques y torretas (17-10-2026, PixelLab):** tres tanques muy distintos (`tank.gd`, `tools/sprites/tanks.py`): **comunista** (estilo T-34, verde con estrella roja; vida 20, velocidad normal, un obús cada 2,3 s), **israelí** (estilo Merkava, gris arena, sin símbolos; vida 34, lento, obús pesado cada 3,2 s) y **estadounidense** (estilo Abrams, arena con estrella blanca; vida 16, el doble de rápido, ráfaga de 2 obuses cada 1,4 s). El nivel puede fijar el tipo (`["tank", x, y, tipo]`); si no, se alternan según la x. La torreta es un búnker de sacos terreros con una ametralladora que gira encima (`turret.gd`, `tools/sprites/turret.py`).

**Escenarios con desniveles y dos caminos (17-10-2026, Gwyn; referencia Metal Slug 3):** el suelo admite cuestas (`[x0, x1, y_inicio, y_fin]` en `ground`) y los salientes se ven macizos. La 1.2 (`quebrada`) y la 1.3 (`baires`) tienen distribución propia: colinas o rampas, escalones, meseta o terraza alta y, en la segunda mitad, dos caminos a la vez en pantalla (arriba cornisas con francotiradores y cápsulas; abajo el fondo del cañón o la avenida con tanques) que se juntan antes del jefe. ☐ Llevarlo a México, EUA y Alemania (siguen con las plantillas planas `desert`, `city`, `jungle`, `snow`). La 1.1 sigue llana a pedido de Eduardo.

**Vecinos y soldados de Argentina (18-10-2026, Eduardo):** en la 1.1 viven 12 vecinos (ChatGPT, animados con PixelLab; `tools/sprites/vecinos.py`, `scripts/civilian.gd`), uno por edificio: pasean frente a su puerta y, cuando llega la pelea, entran a su casa y se asoman por las ventanas; no corren por la calle ni reciben balas. Las puertas y ventanas de cada edificio salen de `tools/sprites/pueblo.py` (`scripts/pueblo_casas.gd`). Los soldados enemigos de Argentina (1.1 a 1.3) son un soldado nuevo con las proporciones de los héroes y parche argentino (`tools/sprites/soldados.py` → `soldier_ar.png`): correr (PixelLab), apuntar en 4 direcciones, granada, susto y una muerte en 3 poses (cae de espaldas y queda tirado). Cada soldado sale con una de 5 caras al azar (las de `tools/sprites/chatgpt/soldados/caras_v2.png`): el joven original y 4 variantes pintadas en cada fotograma por `soldados.py caras` (`soldier_ar_1..4.png`: bigote, moreno, canoso con barba, pelirrojo). ☐ Versiones para los demás países.

