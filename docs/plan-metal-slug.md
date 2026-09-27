# Plan: de prototipo a "Metal Slug" profesional

Autores: Gwyn y Eduardo · 27-09-2026 · Complementa a [`diseno.md`](diseno.md), que sigue siendo el documento de diseño vivo.

> Objetivo: que Contra-Typebeat se juegue y se vea como un Metal Slug. **Inspirado en**, no copiado: ni sprites, ni sonidos, ni nombres de SNK. Las capturas de Metal Slug son solo referencia.

## 1. Qué hace que Metal Slug se sienta así

| Rasgo | En Metal Slug | En nuestro juego hoy |
|---|---|---|
| Animación densa | Enemigos con muchos fotogramas, todo "vivo"; hasta la explosión pequeña es un evento con fuego, humo y escombros | Formas dibujadas por código, 1-2 poses |
| Exageración y humor | Proporciones exageradas; soldados que se asustan, huyen, mueren de forma cómica | Soldados rígidos |
| Jefes por piezas | Jefes enormes con brazos y patas que se mueven por separado (técnica "paperdoll") y partes que se rompen | Jefes de una sola pieza |
| Controles | Disparo adelante, arriba y, en el aire, abajo; **granadas** con botón propio; **cuchillo** automático cuerpo a cuerpo | 8 direcciones y salto en bola (eso es Contra, no Metal Slug) |
| Armas | Armas especiales con **munición limitada** (H, R, F, L, S…); al acabarse vuelves a la pistola | Armas infinitas hasta morir |
| Rescate de prisioneros | Prisioneros atados que al liberarlos dan armas o puntos | No existe |
| Vehículos | El tanque "Slug" y otros: se montan, tienen vida propia y se abandonan | No existe |
| Destrucción | Casi todo el escenario se rompe | Solo barriles |
| Cooperativo | 2 jugadores en la misma pantalla | 1 jugador |

Fuentes del estudio: [análisis de la animación de Metal Slug (ResetEra)](https://www.resetera.com/threads/video-game-animation-study-the-animation-of-metal-slug.139664/), [Metal Slug Is Pixel Art Perfection](https://linclogames.com/metal-slug-is-pixel-art-perfection/), [tutorial de spriting estilo Metal Slug](https://6th-divisions-den.com/ms_tutorial.html).

## 2. Cómo cambia el código (arquitectura profesional en Godot)

Hoy todo se dibuja con `_draw()` y se construye por código. Sirvió para el prototipo, pero no escala a sprites animados ni a jefes por piezas. El cambio:

- **Escenas `.tscn` por entidad** (`player.tscn`, `soldier.tscn`, `boss_mecha.tscn`) con `AnimatedSprite2D` o `AnimationPlayer`, en lugar de dibujar por código. Los scripts actuales se reaprovechan como lógica.
- **Componentes reutilizables**: `Health`, `Hurtbox`, `Hitbox`, `Knockback`. Un enemigo nuevo pasa a ser "escena + componentes", no un script de 150 líneas.
- **Máquina de estados del jugador** (quieto, correr, saltar, agachado, disparar, granada, cuchillo, morir, en vehículo). Metal Slug separa el cuerpo de las piernas: las piernas corren mientras el torso dispara hacia arriba. Se hace con dos sprites superpuestos.
- **Jefes por piezas**: cada brazo o arma es un nodo con su propia hitbox y vida. Se animan con `AnimationPlayer` (y `Skeleton2D` si hace falta). Así se puede romper un brazo antes que el cuerpo, como el jefe de la referencia.
- **Autoload `Juice`** para la sensación de impacto: *hitstop* (congelar 2-4 fotogramas al golpear), temblor de cámara con decaimiento, destello blanco al recibir daño, partículas y variación de tono en los sonidos. Referencia: [screen shake y hit-stop en Godot 4](https://dev.to/saltmire/godot-4-screen-shake-and-hit-stop-in-one-script-11eh).
- **Niveles con `TileMapLayer`** y escenas de decorado destructible. `levels.gd` puede seguir guardando dónde aparece cada enemigo.
- **Audio**: buses separados de música y efectos, y opciones de volumen.

## 3. Cadena de producción del arte

- **Aseprite** para dibujar y animar. **[Aseprite Wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard)** importa cada etiqueta de Aseprite como animación en Godot: se guarda en Aseprite y se reimporta solo.
- **Tamaños orientativos** a nuestra resolución de 480x270: jugador unos 32x40 px, soldado igual, jefe grande de 150 a 250 px de alto.
- **Fotogramas orientativos** (Metal Slug suele ir por encima): quieto 4-6, correr 8-12, disparo 3-4 por dirección, muerte de soldado 8+, explosión 10-16.
- **Paleta limitada** por personaje (16-24 colores) con contorno oscuro: es lo que da la "cara" Metal Slug.
- **IA de imagen** (como las referencias que hicieron): muy útil para **conceptos, portadas, retratos y fondos**. No mantiene el mismo personaje fotograma a fotograma, así que la animación hay que limpiarla y hacerla en Aseprite. Flujo recomendado: concepto con IA → redibujar en Aseprite a tamaño real → animar → exportar.
- **Claude** puede generar sprites provisionales por código (PNG de píxeles) para probar mecánicas antes de tener el arte final, y comparar capturas del juego con las referencias, porque lee imágenes.

## 4. Cómo trabajar con Claude Code (Opus 5.5) de forma profesional

1. **Una función por rama y por PR**, como dice `CLAUDE.md`. Nada de "hazlo todo": cada pedido es una pieza concreta ("cuchillo cuerpo a cuerpo", "granadas", "jefe mecha brazo izquierdo").
2. **Modo plan primero** para cambios grandes (en la terminal, Shift+Tab dos veces): Claude propone el plan, ustedes lo aprueban y después se programa.
3. **Referencias visuales en cada pedido**: pasar capturas de Metal Slug y los bocetos propios. Claude compara la captura del juego con la referencia y ajusta.
4. **Pruebas automáticas siempre**: el `autoplay` actual, y más adelante [GdUnit4 + PlayGodot](https://github.com/Randroids-Dojo/Godot-Claude-Skills). Ningún PR sin la prueba en verde.
5. **Revisión cruzada**: el Claude de uno revisa el PR del otro (`/code-review`) y la persona decide.
6. **Ustedes deciden el diseño y el arte; Claude construye y verifica.** Cuando la IA "decide sola", sale código espagueti: la estructura la definen ustedes y la IA la rellena.
7. **`docs/diseno.md` se actualiza en el mismo PR** que cada cambio de juego.

## 5. Hoja de ruta por fases

| Fase | Contenido | Resultado |
|---|---|---|
| **v0.4 Base Metal Slug** ✅ | Controles estilo MS (adelante/arriba/abajo en el aire, sin salto en bola), granadas con límite, cuchillo automático de cerca, armas con munición (H, R, F, L, S), autoload `Juice`, soldados que se asustan y huyen | Se juega como Metal Slug, aunque aún con formas simples |
| **v0.5 Corte vertical de arte** ✅ (en curso: faltan torretas, tanques y jefes 1-2) | Arquitectura de escenas y componentes; jugador y soldado con sprites reales de Aseprite; un tramo corto de nivel con decorado destructible | Un minuto de juego que ya "parece" el juego final |
| **v0.6 Prisioneros y vehículo** | Prisioneros que dan armas o puntos; tanque tipo "Slug" que se monta y se abandona | Los dos rasgos más reconocibles de la saga |
| **v0.7 Jefe por piezas** | Primer jefe mecha gigante con brazos y armas independientes, fases y partes que se rompen (tipo referencia 1) | Jefe "de póster" |
| **v0.8 Cooperativo** | 2 jugadores en la misma pantalla (teclado + mando) | Jugar juntos |
| **v0.9-1.0** | Rehacer las misiones 1-2 con el nuevo arte, misión 3, música compuesta, opciones, pulido | Versión completa |

## 6. Decisiones abiertas

- ✅ Decidido: ficticios. **Personajes basados en políticos reales.** Recomendación: personajes **ficticios** que parodien el cargo o el estilo (banda presidencial, discursos, carteles de propaganda inventados), sin la cara, el nombre ni los lemas reales de personas concretas. Motivos: las tiendas (Steam, itch.io, consolas) y las redes suelen rechazar juegos en los que se dispara a un político real y reconocible; hay riesgo legal por uso de imagen; y el chiste funciona igual con una parodia. Los villanos concretos están por definir (Zarko y El Socio se descartaron).
- ☐ ¿Mantenemos el nombre "Contra-Typebeat" ahora que el estilo es Metal Slug?
- ✅ Decidido: IA + ajustes a mano. ¿Quién dibuja? ¿Uno de los dos, un artista externo o IA + limpieza en Aseprite?
- ✅ Decidido: 100 % Metal Slug. ¿Controles sin disparo diagonal o mantenemos las diagonales?
