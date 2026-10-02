# ONU: Outbreak

> El juego se llamó Contra-Typebeat hasta la v0.6; el repositorio conserva ese nombre.
Juego de acción / shooter 2D al estilo Contra, hecho con Godot 4.7.

## Descargar y jugar
En [Releases → ultima-version](https://github.com/revtiger/Contra-Typebeat/releases/tag/ultima-version) está el .exe de Windows de la última versión de `main`: descomprime el .zip y ejecuta `ONU-Outbreak.exe`.

## Abrirlo con Godot
Abre la carpeta con Godot 4.7.2 (Importar → `project.godot`) y pulsa F5, o desde la terminal:

```
godot --path .
```

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta o stick |
| Apuntar arriba | Arriba | Cruceta |
| Disparar abajo (en el aire) | Abajo | Cruceta |
| Agacharse | Abajo | Cruceta abajo |
| Saltar | Z / Espacio / K | A |
| Bajar de un puente | Abajo + Saltar | Abajo + A |
| Disparar (mantener) / cuchillo de cerca | X / J | X |
| Granada | C / L | B / Y |
| Pausa | Esc / P | Start |
| Reintentar tras Game Over | Enter / R | Start |
| Salir al menú (en pausa) | Q | Select |

Armas (munición limitada, al acabarse vuelve la pistola): dispara a la cápsula voladora para soltar **H** (ametralladora), **R** (cohetes), **F** (llamas), **L** (láser), **S** (escopeta) o **B** (+10 bombas).

Campaña (historia *ONU: Trying to save the world*): Argentina → México → EUA → Alemania → nivel secreto en la ONU, 3 fases cada uno (15 en total). Cada fase termina en un jefe político (minijefe en X.1 y X.2, jefe final en X.3) y entre fases hay un mapa mundial con la ruta. Detalle en [docs/historia.md](docs/historia.md).

Las armas que no se recogen parpadean y desaparecen a los 9 segundos.

## Estructura
- `scripts/game.gd`: autoload con vidas, puntos, récord, controles, sonido y pausa
- `scripts/levels.gd`: las 15 fases (zonas, plantillas de terreno, enemigos y jefe de cada fase)
- `scripts/politician.gd`, `massa.gd`, `ritual.gd`, `door.gd`: jefes políticos (Massa animado), ritual del pentagrama y puertas del nivel secreto
- `scripts/intro.gd`, `menu.gd`, `select.gd`, `map.gd`, `level.gd`: las escenas (intro, menú, ELIGE TU SOLDADO, mapa, misión)
- `scripts/logo_text.gd`: letras cinceladas del logo; `scripts/city.gd`: ciudad en llamas del menú
- `scripts/player.gd`: jugador
- `scripts/soldier.gd`, `turret.gd`, `tank.gd`, `miniboss.gd`, `boss.gd`, `heli.gd`: enemigos, mini jefes y jefes
- `scripts/barrel.gd`, `mine.gd`, `jet.gd`, `bomb.gd`: peligros del desierto
- `scripts/pickup.gd`: cápsula y armas
- `scripts/sfx.gd`: sintetizador de efectos y música
- `scripts/mecha.gd`, `boss_part.gd`: La Presidenta Mecha, jefe por piezas (transfiguración de Sheinbaum en la fase 2.3)
- `tools/sprites/`: generadores de sprites (Python + Pillow) → `assets/sprites/`
- `tests/autoplay.gd`: prueba automática que juega sola y guarda capturas (ver CLAUDE.md)

## Equipo
Gwyn (`revtiger`) y Eduardo (`eduardord596`). Reglas de trabajo en [CLAUDE.md](CLAUDE.md), diseño en [docs/diseno.md](docs/diseno.md).
