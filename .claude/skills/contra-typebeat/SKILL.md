---
name: contra-typebeat
description: Contexto completo del juego ONU: Outbreak, antes Contra-Typebeat (run and gun estilo Metal Slug en Godot 4.7.2, de Gwyn y Eduardo). Úsala siempre que se trabaje en este juego: código, niveles, jefes, sprites, HUD, historia, diseño, PRs o dudas sobre decisiones ya tomadas.
---

# ONU: Outbreak (antes Contra-Typebeat): contexto del proyecto

El juego se llama **ONU: Outbreak** (el repo sigue llamándose Contra-Typebeat). Juego 2D de acción **estilo Metal Slug** hecho en **Godot 4.7.2** (GDScript) por dos personas, cada una con su Claude Code. Repo privado: https://github.com/revtiger/Contra-Typebeat (carpeta local de Gwyn: `C:\Users\Gwyn\Gwyn\Contra-Typebeat`).

| Persona | GitHub | Notas |
|---|---|---|
| Gwyn | `revtiger` (dueño) | Habla español; quiere respuestas en español |
| Eduardo | `eduardord596` | Colaborador con permiso de escritura |

Lee también `CLAUDE.md` (reglas de trabajo) y `docs/diseno.md` (diseño vivo) y `docs/plan-metal-slug.md` (hoja de ruta). Esta skill resume lo que no está escrito en otro sitio.

## Decisiones ya tomadas (no volver a preguntar)

- **Estilo:** Metal Slug "inspirado en", nunca sprites, sonidos ni nombres de SNK.
- **Controles 100 % Metal Slug:** adelante, arriba y abajo solo en el aire; sin diagonales ni salto en bola. Granada con botón propio (C/L), cuchillo automático de cerca, armas con munición (H, R, F, L, S) y vuelta a la pistola.
- **Políticos reales permitidos (cambio de Gwyn, 28-09-2026).** El juego es una parodia política al estilo Broforce: los jefes, semijefes, mercader y ayudante pueden ser caricaturas de políticos reales (cara, nombre y lemas), como en la propuesta de Eduardo. La lista está en `docs/historia.md`. No volver a proponer arquetipos inventados en su lugar. Los 4 soldados jugables siguen siendo inventados. **Tono:** burla tipo Metal Slug, sin gore: caricaturas exageradas, derrotas cómicas (salen volando, se ponen en ridículo, "reciben su merecido") y nada de sangre ni desmembramientos.
- **Arte:** sprites generados con IA y ajustados a mano en Aseprite; mientras tanto, los generadores de `tools/sprites/` producen los PNG.
- **Fuente:** una sola fuente pixelada para todo el texto del juego (`assets/sprites/font.png`), con estilos por jerarquía: `title` (títulos, degradado amarillo-rojo), `small` (valores y énfasis, dorado), `white` (texto normal), `label` (etiquetas y ayudas, azul claro), `metal` (TIME). Todo en mayúsculas.
- **Historia (aceptada 29-09-2026):** *ONU: Trying to save the world* de Eduardo, en `docs/historia.md`. La Orden Mundial; niveles Argentina (Massa, C. Kirchner, Milei) → México (AMLO, Salinas, Sheinbaum) → EUA (Biden, Obama, Trump) → Alemania (Merkel, Scholz, Merz) → nivel secreto en la ONU (líder enmascarado; los jefes se fusionan en un pentagrama en el jefe final sci-fi). Político aliado tras cada jefe (mejoras y munición), ayudante religioso (poción de inmunidad), 2 héroes genéricos con skins que el jugador puede subir. Se hace nivel por nivel. **Descartados:** el General Zarko, El Socio y el estilo de retratos de póster de *Duro de matar*. **Gwyn y Eduardo no son personajes** (solo aparecen como G·E STUDIOS en créditos). Referencias de estilo que le gustan a Gwyn: la intro de Metal Slug 2 (logo que cae letra a letra) y el SOLDIER SELECT de Metal Slug X. Ruta actual en el código: Argentina–Brasil (Triple Frontera) → frontera México–EE.UU. (Bolivia quitada el 30-09-2026); se sustituirá por la nueva.

## Estado (v0.6, 27-09-2026)

- 2 misiones jugables, cada una con mini jefe y jefe: Jungla (Comandante Kruger / La Fortaleza Roja), Frontera Norte (Comandante Kruger / La Presidenta Mecha, jefe por piezas). Bolivia se quitó; el tema desierto, `camion` y `heli.gd` quedan sin usar para reaprovecharlos.
- Nombre: **ONU: Outbreak**. Logo: ONU gigante + OUTBREAK debajo, en letras cinceladas (`logo_text.gd`, estilos big_stone/big_gold).
- Intro estilo Metal Slug 2 (G·E STUDIOS, logo cincelado que cae letra a letra, fogonazo a oro), menú con logo dorado, ELIGE TU SOLDADO estilo Metal Slug X con 4 soldados ficticios (El Presi, La Tenienta, El Chato, Don Bigotes; `Game.hero`), mapa de campaña, pausa, récord, música y efectos 8 bits generados por código.
- HUD Metal Slug: 1UP=vidas, recuadro ARMS/BOMB, icono del arma, TIME (60, baja cada 4 s, a 0 mueres), récord.
- Sprites PNG: protagonista (traje + banda tricolor + mochila; piernas y torso separados), soldados (selva/desierto), mecha. Aún con formas por código: torretas, tanques, mini jefes, jefes 1-2, objetos.
- **La Presidenta Mecha es ENEMIGA** (jefe final de la misión 3), y en la propuesta del nivel 1 pasa a ser la caricatura de Sheinbaum. **La Tenienta no está basada en nadie.** Idea aprobada: al final todos los villanos "reciben su merecido" de forma chistosa.
- **Arte siguiente paso: PixelLab** (MCP oficial para Claude Code: personajes, animaciones, tiles, con imágenes de referencia). Gwyn tiene que crear la cuenta y añadirlo con `claude mcp add pixellab https://api.pixellab.ai/mcp -t http -H "Authorization: Bearer <clave>"`; Claude nunca crea la cuenta ni maneja la clave. Cuando esté, rehacer primero los 4 soldados (quieto, correr, disparar, agacharse, morir) con referencias de Metal Slug.
- PRs encadenados: #1 (v0.3) → #3 (v0.4) → #4 (v0.5-v0.6). Fusionar en ese orden. PR #2 es la propuesta de historia de Eduardo con políticos reales; PR #6 la recoge en `docs/historia.md`, ya con políticos reales.

## Mapa del código

- `scripts/game.gd` (autoload `Game`): vidas, puntos, récord, misión, controles, sonido `Game.sfx()`, música, pausa, flujo de escenas.
- `scripts/juice.gd` (autoload `Juice`): `hitstop()` (se deshace con el reloj real cada fotograma) y `shake()`.
- Escenas: `intro` → `menu` → `select` (ELIGE TU SOLDADO) → `map` → `level` → `map`… Misiones como datos en `scripts/levels.gd`; paradas del mapa en `STOPS` de `scripts/map.gd` (parada i = misión i).
- `scripts/level.gd`: construye la misión, cámara, TIME, `blast()`/`explode()`, `throw_grenade()`, `lock_camera()` para mini jefes.
- Jugador `player.gd`; enemigos `soldier.gd`, `turret.gd`, `tank.gd`, `miniboss.gd`; jefes `boss.gd` (muro), `heli.gd`, `mecha.gd` + `boss_part.gd` (piezas con vida propia).
- HUD `scripts/hud.gd`; fuente para Labels `scripts/pixel_font.gd`; letras de logo `scripts/logo_text.gd`; hojas de sprites `scripts/sprite_util.gd`.
- Generadores (`tools/sprites/`): `humans.py` (4 soldados jugables `player_<id>_*` y enemigos), `mecha.py`, `font.py`, `logo.py`, `portraits.py` (retratos color/sepia).
- Capas de colisión: 1 suelo, 2 jugador, 4 enemigos, 8 puentes, 16 objetos.

## Cómo trabajar

1. `git checkout main && git pull`, rama `gwyn/…` o `eduardo/…`, PR hacia `main` (o encima del PR anterior si aún no se fusionó).
2. Probar antes de subir (desde la carpeta del repo, con el Godot instalado por winget):
   - `godot --path . -- autoplay out=<carpeta> level=0 campaign` → debe terminar en `FIN: vuelta al menú` sin ningún `ERROR`.
   - `level=N boss` para ir directo al jefe; `scene=intro` para intro y menú.
   - Revisar las capturas que guarda (leerlas como imágenes) antes de dar algo por bueno.
3. Sprites: editar `tools/sprites/humans.py`, `mecha.py` o `font.py` y ejecutarlos con Python (necesita Pillow); después `godot --headless --path . --import`.
4. El `.exe` lo genera GitHub Actions en cada push (pestaña Actions; en `main` queda en Releases como `ultima-version`).
5. Actualizar `docs/diseno.md` en el mismo PR y **actualizar esta skill** cuando cambie el estado o se tome una decisión nueva.
