# Documento de diseño: Contra-Typebeat

Autores: Gwyn y Eduardo · Última revisión: 27-09-2026

> Sustituye al borrador de Word ("Colibrí Veloz"), que era un ejemplo de plantilla. Se mantiene su estructura. Lo marcado con ☐ está por decidir.

## Resumen

Contra-Typebeat es un run and gun 2D de desplazamiento lateral inspirado en Contra: un soldado cruza la jungla disparando en 8 direcciones contra oleadas de enemigos hasta destruir la fortaleza del final.

| Aspecto | Definición |
|---|---|
| Género | Run and gun / acción arcade |
| Motor | Godot 4.7.2 |
| Plataforma | PC (Windows) ☐ ¿también navegador? |
| Duración de un nivel | 3 a 5 minutos |
| Público | Fans de los arcade clásicos que buscan reto |
| Meta del jugador | Llegar al final del nivel y vencer al jefe sin perder todas las vidas |

## Pilares de diseño

1. **Acción inmediata**: se dispara desde el primer segundo; nada de tutoriales largos.
2. **Difícil pero justo**: cada muerte se entiende; las balas enemigas son lentas y visibles.
3. **Una más**: reinicio instantáneo y puntuación visible.

## Bucle de juego principal

Avanzar → aparecen enemigos → apuntar y disparar → esquivar balas saltando o tumbándose → recoger mejoras de arma → jefe al final del nivel.

Al morir se pierde el arma especial y se reaparece en el mismo punto con 2 s de invulnerabilidad. Sin vidas: Game Over.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta |
| Apuntar arriba / diagonales | Arriba (+ lado), Abajo + lado | Cruceta |
| Tumbarse | Abajo | Cruceta abajo |
| Saltar (en bola) | Z / Espacio / K | A |
| Bajar de un puente | Abajo + Saltar | Abajo + A |
| Disparar (mantener) | X / J | X / B |
| Reiniciar | Enter / R | Start |

## Enemigos, armas y objetos

| Elemento | Tipo | Qué hace | Estado |
|---|---|---|---|
| Soldado corredor | Enemigo | Corre en línea recta, salta escalones, muere de 1 tiro | ✅ |
| Francotirador | Enemigo | Quieto, apunta en 8 direcciones, 2 tiros | ✅ |
| Torreta | Enemigo | Gira hacia el jugador (12 direcciones), 8 tiros | ✅ |
| Muro-fortaleza | Jefe | 2 cañones con ráfaga triple, suelta soldados, 70 de vida | ✅ |
| Cápsula voladora | Objeto | Cruza la pantalla; al dispararle suelta un arma | ✅ |
| Normal | Arma | Disparo simple | ✅ |
| M: metralleta | Arma | Cadencia doble | ✅ |
| S: spread | Arma | 5 balas en abanico | ✅ |
| L: láser | Arma | ☐ | Pendiente |
| F: fuego | Arma | ☐ | Pendiente |

## Niveles

1. **Jungla** ✅: suelo con fosos de agua, puentes, un escalón elevado y el muro-fortaleza al final.
2. ☐ Por definir (¿base enemiga en pseudo-3D como el Contra original? ¿cascada vertical?).

## Estilo visual y sonido

- Pixel art a 480x270, fondos con parallax (cielo al atardecer, montañas, palmeras).
- Ahora mismo todo son formas dibujadas por código; ☐ decidir quién hace los sprites y con qué programa (Aseprite recomendado).
- ☐ Música y efectos de sonido: pendiente.

## Alcance del primer prototipo

| Entra | Queda para después |
|---|---|
| Nivel 1 completo con jefe | Más niveles |
| Movimiento, salto, tumbarse, 8 direcciones | Modo 2 jugadores |
| 3 armas | Láser y fuego |
| Formas simples | Sprites y animaciones |
| Vidas, puntos, Game Over | Música, sonido, menú principal |

## Preguntas abiertas

- ☐ ¿Modo cooperativo de 2 jugadores en la misma pantalla?
- ☐ ¿Solo PC o también exportar a navegador?
- ☐ ¿Cuántos niveles para la primera versión completa?
- ☐ ¿Quién se encarga del arte y quién del sonido?
- ☐ ¿Se publica (itch.io, Steam) o es proyecto personal?
