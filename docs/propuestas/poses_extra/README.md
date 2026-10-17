# Propuesta: poses nuevas de Eduardo y Eder

Autor: Eduardo · 01-10-2026 · Estado: **aceptada y montada en el juego (16-10-2026)**. Las hojas se movieron a `tools/sprites/chatgpt/sprites_<id>_3.png` (arriba y abajo), `_4.png` (diagonal y barrida) y `_5.png` (paracaídas y muerte); las usa `tools/sprites/heroes_sheets.py`. Ya en el juego: arriba, diagonal arriba (quieto y corriendo), diagonal abajo en el aire y muerte. Sin usar: barrida y paracaídas.

Hojas hechas con ChatGPT, 4x4 poses cada una, con el mismo estilo que las de `tools/sprites/chatgpt/`.

| Hoja | Eduardo | Eder | Contenido |
|---|---|---|---|
| 1 | `sprites_eduardo_3.png` | `sprites_eder_3.png` | Disparar **arriba** quieto y corriendo; disparar **abajo** (en diagonal hacia el suelo) quieto y corriendo |
| 2 | `sprites_eduardo_4.png` | `sprites_eder_4.png` | Disparar en **diagonal hacia arriba** quieto y corriendo; **barrerse** y levantarse |
| 3 | `sprites_eduardo_5.png` | `sprites_eder_5.png` | **Descenso en paracaídas** y aterrizaje; **muerte** (cae hacia atrás y queda tumbado) |

## Qué resolvería en el juego

- Hoy Eduardo y Eder no tienen pose de disparar arriba ni abajo: la bala sale bien, pero el sprite sigue apuntando al frente.
- La muerte actual usa las poses de "cuerpo a tierra"; estas son una caída de verdad.
- El paracaídas serviría para la entrada al empezar cada fase o al reaparecer.

## Por decidir

- ☐ Los controles son 100 % Metal Slug (sin diagonales). ¿Se añade el disparo en diagonal o se usan esas poses solo como transición entre frente y arriba?
- ☐ El "abajo" de las hojas es en diagonal hacia el suelo estando de pie; en Metal Slug el disparo hacia abajo solo existe en el aire. ¿Se usa como disparo en diagonal hacia abajo o solo en el aire?
- ☐ ¿Se añade la barrida como movimiento nuevo (por ejemplo, Abajo + Saltar corriendo)?
- ☐ ¿Paracaídas al empezar cada fase, al reaparecer tras morir, o en los dos?

Esta carpeta está dentro de `docs/propuestas/`, que tiene `.gdignore`: Godot no importa estas imágenes.
