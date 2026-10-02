# Contra-Typebeat
Juego de acción / shooter 2D al estilo Contra, hecho con Godot 4.7.

## Descargar y jugar
En [Releases → ultima-version](https://github.com/revtiger/Contra-Typebeat/releases/tag/ultima-version) está el .exe de Windows de la última versión de `main`: descomprime el .zip y ejecuta `ContraTypebeat.exe`.

## Abrirlo con Godot
Abre la carpeta con Godot 4.7.2 (Importar → `project.godot`) y pulsa F5, o desde la terminal:

```
godot --path .
```

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | Flechas / WASD | Cruceta |
| Apuntar arriba / diagonal | Arriba (+ lado) | Cruceta |
| Tumbarse | Abajo | Cruceta abajo |
| Saltar | Z / Espacio / K | A |
| Bajar de un puente | Abajo + Saltar | Abajo + A |
| Disparar (mantener) | X / J | X / B |
| Pausa | Esc / P | Start |
| Reintentar tras Game Over | Enter / R | Start |
| Salir al menú (en pausa) | Q | Select |

Armas: dispara a la cápsula voladora para soltar **M** (metralleta), **S** (spread), **L** (láser) o **F** (fuego).

Campaña: 1 Argentina–Brasil (Triple Frontera), 2 Bolivia (Quebradas de Tupiza), 3 México–EE.UU. (próximamente). Cada misión tiene mini jefe y jefe final, y entre misiones hay un mapa con la ruta.

Las armas que no se recogen parpadean y desaparecen a los 9 segundos.

## Estructura
- `scripts/game.gd`: autoload con vidas, puntos, récord, controles, sonido y pausa
- `scripts/levels.gd`: datos de las misiones (suelo, plataformas, enemigos)
- `scripts/intro.gd`, `menu.gd`, `map.gd`, `level.gd`: las escenas (intro, menú, mapa de campaña, misión)
- `scripts/city.gd`, `portrait.gd`: ciudad en llamas y caras pixeladas de la intro
- `scripts/player.gd`: jugador
- `scripts/soldier.gd`, `turret.gd`, `tank.gd`, `miniboss.gd`, `boss.gd`, `heli.gd`: enemigos, mini jefes y jefes
- `scripts/barrel.gd`, `mine.gd`, `jet.gd`, `bomb.gd`: peligros del desierto
- `scripts/pickup.gd`: cápsula y armas
- `scripts/sfx.gd`: sintetizador de efectos y música
- `tests/autoplay.gd`: prueba automática que juega sola y guarda capturas (ver CLAUDE.md)

## Equipo
Gwyn (`revtiger`) y Eduardo (`eduardord596`). Reglas de trabajo en [CLAUDE.md](CLAUDE.md), diseño en [docs/diseno.md](docs/diseno.md).
