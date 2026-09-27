# Contra-Typebeat
Juego de acción / shooter 2D al estilo Contra, hecho con Godot 4.7.

## Cómo jugar
Abre la carpeta con Godot (Importar → `project.godot`) y pulsa F5, o desde la terminal:

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
| Reiniciar tras Game Over | Enter / R | Start |

Armas: dispara a la cápsula voladora para soltar **M** (metralleta) o **S** (spread).

## Estructura
- `scripts/main.gd`: nivel, cámara, HUD y estado de la partida (datos del nivel al principio del archivo)
- `scripts/player.gd`: jugador
- `scripts/soldier.gd`, `turret.gd`, `boss.gd`: enemigos
- `scripts/pickup.gd`: cápsula y armas
- `tests/autoplay.gd`: prueba automática que juega sola y guarda capturas
  (`godot --path . --script res://tests/autoplay.gd -- <carpeta> [boss]`)

## Equipo
Gwyn (`revtiger`) y Eduardo (`eduardord596`). Reglas de trabajo en [CLAUDE.md](CLAUDE.md), diseño en [docs/diseno.md](docs/diseno.md).
