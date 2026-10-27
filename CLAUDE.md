# ONU: Outbreak (antes Contra-Typebeat): reglas del proyecto

Juego 2D de acción estilo Contra en **Godot 4.7.2** (GDScript). Equipo de dos personas, cada una con su Claude Code:

| Persona | GitHub |
|---|---|
| Gwyn | `revtiger` (dueño del repo) |
| Eduardo | `eduardord596` |

Todo se comparte por GitHub: https://github.com/revtiger/Contra-Typebeat. Lo que no está en el repo no existe para el otro.

## Flujo de trabajo (obligatorio)

1. **Antes de empezar**: `git checkout main && git pull`. Mira los Issues y PRs abiertos para no pisar el trabajo del otro.
2. **Una rama por tarea**, nunca trabajar directo en `main`. Nombre: `<persona>/<tema>`, p. ej. `gwyn/sprites-jugador`, `eduardo/nivel-2`.
3. **Commits pequeños** con mensaje en español que diga qué y por qué.
4. **Antes de abrir el PR**, correr la prueba automática y comprobar que no hay errores (ver abajo). Traer `main` a la rama si ha cambiado.
5. **Abrir un Pull Request** hacia `main` con: qué cambia, cómo probarlo y capturas si hay cambios visuales. Enlazar el Issue (`Closes #N`).
6. **El otro revisa y fusiona.** Nadie fusiona su propio PR salvo que el otro lo apruebe por el chat.
7. Borrar la rama tras fusionar.

Claude Code: no hagas push a `main`, no fuerces push (`--force`) sobre ramas del otro y no fusiones PRs sin que el usuario lo pida explícitamente.

## Quién toca qué

Para evitar conflictos, antes de editar un archivo que el otro tiene en un PR abierto, avisar por el chat. Los archivos que más chocan:

- `scripts/main.gd` (datos del nivel y HUD): cambios pequeños y fusionar rápido.
- `project.godot`: solo cambiarlo cuando haga falta; Godot lo reescribe al abrir el editor, revisar el diff antes de hacer commit.
- `.tscn` / `.tres`: son texto, pero los conflictos son difíciles de resolver. Una escena la edita una sola persona a la vez.

## Reglas de arquitectura (obligatorias)

[`ARQUITECTURA.md`](ARQUITECTURA.md) fija las reglas del proyecto, numeradas `ARQ-NN`: capas de colisión, capas visuales, arte, largo de los mapas en escenas de 480 px, archivos y nombres, la carpeta `referencias/` y las fusiones. Claude Code (y cualquier IA del equipo) debe:

- comprobar las reglas **antes** de escribir código o tocar arte;
- si un cambio rompe una regla ✅, detenerse con un **🛑 BLOQUEO** citando la regla y ofrecer la alternativa; no hacerlo aunque se insista (las reglas se cambian primero en `ARQUITECTURA.md`, no se saltan);
- avisar con un **⚠ WARNING** y esperar confirmación ante cambios drásticos de arte, temas por definir, renombrar o mover archivos o cambiar el largo de un mapa;
- dejar los antes/después que se pidan en `referencias/antes-despues/<AAAA-MM-DD>_<tema>/`;
- antes de fusionar, listar los riesgos de fusión (ARQ-70).

## Diseño

El documento de diseño vivo es [`docs/diseno.md`](docs/diseno.md). Cualquier decisión de juego (controles, enemigos, niveles, armas) se refleja ahí en el mismo PR que la implementa. Las dudas abiertas van al final del documento o como Issue con la etiqueta `diseño`.

## Código

- Godot 4.7.2 exacto en los dos equipos (versiones distintas reescriben archivos del proyecto).
- GDScript con tabuladores, tipado estático cuando se pueda, comentarios en español.
- Sin `class_name` por ahora: los scripts se cargan con `preload`.
- **Modo test** (`Game.test`, `scripts/modo_test.gd`): se abre con `godot --path . -- test` o con el `.exe` de test (preset "Windows Test", etiqueta `test`). No salen enemigos solos (`TEST_SKIP` en `level.gd`), no hay cinemática y hay teclas: **F1** greybox/arte, **F2** francotirador o granadero que entra, se planta y ataca, **F3** jefe de la fase aquí mismo (la fase no termina al vencerlo), **F4** cápsula con arma al azar, **F5** inmortal, **F6** turbo (corre a 400 px/s), **F7** granadero, **F8** francotirador, **F9** emboscadas de azotea (empiezan apagadas). Los enemigos de los interiores (edificios grandes) sí salen en modo test. El juego normal (producción) no tiene estas teclas.
- **Greybox:** en modo test las fases se ven con bloques grises etiquetados y las cajas de colisión coloreadas por capa (`scripts/greybox.gd`, `Game.greybox`). La jugabilidad (medidas, cajas, saltos, distribución) se prueba sobre el greybox, sin pedir arte nuevo.
- Capas de colisión y visuales: ver [`ARQUITECTURA.md`](ARQUITECTURA.md) (1 Terreno, 2 MainHurtbox, 3 EnemyHurtbox, 4 HitboxJugador, 5 HitboxEnemigo, 6 Interactivos, 7 Zonas).
- Autoload `Game` (`scripts/game.gd`): vidas, puntos, récord, misión actual, controles, sonido (`Game.sfx("boom")`) y pausa.
- Autoload `Juice` (`scripts/juice.gd`): `Juice.hitstop(segundos)` y `Juice.shake(cantidad)` para la sensación de impacto.
- Estilo Metal Slug: el plan y las fases están en `docs/plan-metal-slug.md`. Se permiten caricaturas de políticos reales (parodia política, idea de Eduardo); ver `docs/historia.md`.
- Escenas: `intro.tscn` → `menu.tscn` → `select.tscn` (ELIGE TU SOLDADO) → `map.tscn` → `level.tscn` → `map.tscn` … Las 15 fases se generan en `scripts/levels.gd` a partir de `ZONES` (país, lugar, plantilla de terreno y jefe de cada fase) y `TEMPLATES`; el mapa tiene una parada por zona en `STOPS` de `scripts/map.gd`.
- Jefes políticos: `scripts/politician.gd` (datos y ataques en `POLS`). Sprites en `assets/sprites/pol_<id>.png`, generados por `python tools/sprites/politicians.py` desde los PNG de PixelLab en `tools/sprites/pixellab/politicos/`.
- Mini jefes (`scripts/miniboss.gd`) bloquean la cámara con `level.lock_camera()` y la liberan al morir.
- Explosiones que hacen daño: `level.blast(pos, radio, daña_jugador)`; solo visuales: `level.explode(pos, radio)`.
- Resolución interna 480x270, escalada a la ventana.
- **Sprites:** los PNG de `assets/sprites/` los generan `tools/sprites/humans.py` (protagonista y soldados) y `tools/sprites/mecha.py` (jefe mecha), con Python + Pillow. Para cambiar un sprite: editar el generador y ejecutarlo (`python tools/sprites/humans.py`), o retocar el PNG en Aseprite. Los `*_meta.json` guardan filas de animación, pivotes y bocas de cañón: si se mueve el arma en el sprite, hay que regenerar el meta. Fotogramas de 48x48 con los pies en (24, 46).
- **Contexto del proyecto:** la skill `.claude/skills/contra-typebeat/SKILL.md` resume decisiones, estado y mapa del código. Actualizarla cuando cambie algo importante.
- **Una sola fuente para todo el texto:** `scripts/pixel_font.gd` (`PixelFont.apply(label, estilo, escala)`; para `draw_string` usar `PixelFont.font(estilo)` y `PixelFont.size(estilo)`). Jerarquía: `title` títulos, `small` valores y opción elegida, `white` texto normal, `label` ayudas, `metal` TIME. No usar la fuente por defecto de Godot.
- Fuente pixelada del HUD: `tools/sprites/font.py` → `assets/sprites/font.png`. El HUD (`scripts/hud.gd`) la dibuja con `draw_text(texto, pos, estilo, alineación)`; estilos `small`, `label`, `title` y `metal`.
- `Juice.hitstop()` se deshace comprobando el reloj real en cada fotograma; la prueba automática da `ERROR` si el juego queda en cámara lenta más de 0,5 s.
- `scripts/sprite_util.gd` carga las hojas (una fila por animación) como SpriteFrames.

## Probar

```
godot --path . -- autoplay out=<carpeta_capturas> level=0
godot --path . -- autoplay out=<carpeta_capturas> level=1 boss   # level = fase 0..14 (0 = 1.1, 14 = 5.3)
godot --path . -- autoplay out=<carpeta_capturas> scene=intro
godot --path . -- autoplay out=<carpeta_capturas> level=0 campaign
```

Juega la misión sola (invencible salvo en los fosos), guarda capturas y debe terminar con `FIN: estado=clear` y sin ningún `ERROR`. `boss` empieza justo antes del jefe; `scene=intro` solo captura la intro y el menú; `campaign` juega todas las misiones seguidas pasando por los mapas y termina con `FIN: vuelta al menú`.

## Versión jugable (.exe)

GitHub Actions (`.github/workflows/build.yml`) exporta el juego a Windows en cada push:
- En cualquier rama, el .zip queda en la pestaña Actions de esa ejecución (artifact).
- En `main`, además se publica en Releases como `ultima-version`.

Si añades archivos que no deben ir en el .exe, exclúyelos en `export_presets.cfg`.
