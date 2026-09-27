# Documento de diseño: Contra-Typebeat

Autores: Gwyn y Eduardo · Última revisión: 27-09-2026 (v0.2)

> Sustituye al borrador de Word ("Colibrí Veloz"), que era un ejemplo de plantilla. Se mantiene su estructura. Lo marcado con ☐ está por decidir.

## Resumen

Contra-Typebeat es un run and gun 2D de desplazamiento lateral inspirado en Contra: un soldado cruza la jungla y el desierto disparando en 8 direcciones contra oleadas de enemigos, tanques y bombardeos hasta destruir al jefe de cada misión.

**Historia (intro):** año 2087. El ejército del General Zarko ha tomado la Jungla de Galuga y el Desierto Rojo. Solo dos soldados pueden detenerlo.

| Aspecto | Definición |
|---|---|
| Género | Run and gun / acción arcade |
| Motor | Godot 4.7.2 |
| Plataforma | PC (Windows) ☐ ¿también navegador? |
| Duración de un nivel | 3 a 5 minutos (2 misiones en la v0.2) |
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

**Flujo de pantallas:** intro (se salta con cualquier botón) → menú (Jugar, Elegir misión, Controles, Salir) → misión → "Misión cumplida" → siguiente misión → "Victoria total" → menú. Esc pausa la partida.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta |
| Apuntar arriba / diagonales | Arriba (+ lado), Abajo + lado | Cruceta |
| Tumbarse | Abajo | Cruceta abajo |
| Saltar (en bola) | Z / Espacio / K | A |
| Bajar de un puente | Abajo + Saltar | Abajo + A |
| Disparar (mantener) | X / J | X / B |
| Pausa | Esc / P | Start |
| Reintentar tras Game Over | Enter / R | Start |
| Salir al menú (en pausa o Game Over) | Q | Select |

## Enemigos, armas y objetos

| Elemento | Tipo | Qué hace | Estado |
|---|---|---|---|
| Soldado corredor | Enemigo | Corre en línea recta, salta escalones, muere de 1 tiro | ✅ |
| Francotirador | Enemigo | Quieto, apunta en 8 direcciones, 2 tiros | ✅ |
| Torreta | Enemigo | Gira hacia el jugador (12 direcciones), 8 tiros | ✅ |
| Muro-fortaleza | Jefe (misión 1) | 2 cañones con ráfaga triple, suelta soldados, 70 de vida | ✅ |
| Tanque | Enemigo | Avanza y dispara obuses rasantes: se esquivan saltando o tumbándose. 20 de vida | ✅ |
| Barril explosivo | Objeto | Estalla al dispararle y daña todo alrededor; reacción en cadena | ✅ |
| Mina | Peligro | Al pisarla pita y explota 0,4 s después; si sigues corriendo te salvas | ✅ |
| Bombardeo aéreo | Evento | Un caza cruza y suelta 4 bombas; marcas rojas avisan dónde caen | ✅ |
| Helicóptero | Jefe (misión 2) | Ráfagas apuntadas, bombas con aviso y abanico de balas a media vida. 110 de vida | ✅ |
| Cápsula voladora | Objeto | Cruza la pantalla; al dispararle suelta un arma | ✅ |
| Normal | Arma | Disparo simple | ✅ |
| M: metralleta | Arma | Cadencia doble | ✅ |
| S: spread | Arma | 5 balas en abanico | ✅ |
| L: láser | Arma | Rayo rápido que atraviesa enemigos, daño 3 | ✅ |
| F: fuego | Arma | Bola que avanza en espiral, daño 2 | ✅ |

## Niveles

1. **Jungla** ✅: suelo con fosos de agua, puentes, un escalón elevado y el muro-fortaleza al final.
2. **Desierto Rojo** ✅: mesetas rojas, dunas y cactus; cañones sin fondo, meseta elevada, barriles, minas, 2 tanques, 3 bombardeos y el helicóptero al final. Música más rápida.
3. ☐ Por definir (¿base enemiga en pseudo-3D como el Contra original? ¿cascada vertical?).

## Estilo visual y sonido

- Pixel art a 480x270, fondos con parallax (cielo al atardecer, montañas, palmeras).
- Ahora mismo todo son formas dibujadas por código; ☐ decidir quién hace los sprites y con qué programa (Aseprite recomendado).
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

## Preguntas abiertas

- ☐ ¿Modo cooperativo de 2 jugadores en la misma pantalla?
- ☐ ¿Solo PC o también exportar a navegador?
- ☐ ¿Cuántos niveles para la primera versión completa?
- ☐ ¿Quién se encarga del arte y quién del sonido?
- ☐ ¿Se publica (itch.io, Steam) o es proyecto personal?
