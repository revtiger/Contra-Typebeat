# Historia y personajes: propuesta de Eduardo

Autor: Eduardo · 26-09-2026 · Estado: **propuesta, pendiente de acordar con Gwyn**

> Propone cambiar el tema del juego a una sátira de personajes políticos, estilo Contra / Metal Slug. Choca con la historia de la intro de la v0.2 (General Zarko, año 2087); ver "Preguntas abiertas". Cuando se acuerde, se integra en [`diseno.md`](diseno.md). Lo marcado con ☐ está por decidir.

## Premisa

Juego de acción 2D tipo Contra / Metal Slug con tema de **personajes políticos**, en tono de parodia.

**Objetivo:** detener a Trump en la reunión secreta de las Naciones Unidas.

**Giro de la historia:** Trump planea traicionar a los países aliados lanzando bombas sobre países clave para dominar el mundo. Tiene aliados en cada país a los que hay que detener antes de llegar a él.

## Personajes

| Rol | Personajes | Qué hace |
|---|---|---|
| Héroes (2) | Dos stickman (por ahora) | Personajes jugables. ☐ ¿Cooperativo a la vez o se elige uno? |
| Mercader (1) | Vladimir Putin | Vende armas y mejoras entre fases. ☐ ¿Con qué se paga (puntos, monedas)? |
| Ayudante (1) | Papa Francisco | Ayuda al jugador. ☐ ¿Cómo? (vida extra, escudo, aparece en momentos difíciles…) |

### Jefes por país

Cada país tiene semijefes y un jefe final: 3 jefes finales en total, uno por nivel.

| País | Personajes | Jefe final |
|---|---|---|
| México | Claudia Sheinbaum, Felipe Calderón, AMLO | ☐ |
| Argentina | Javier Milei, Néstor y Cristina Kirchner (jefe doble), Sergio Massa | ☐ |
| EUA | Donald Trump, Barack Obama, Joe Biden | **Trump** (jefe final del juego) |

## Niveles

3 niveles, uno por país, con 3 fases cada uno (1.1, 1.2, 1.3…). Propuesta de estructura:

| Fase | Contenido |
|---|---|
| X.1 | Recorrido + semijefe |
| X.2 | Recorrido + semijefe |
| X.3 | Recorrido + jefe final del país |

| Nivel | País | Final |
|---|---|---|
| 1 | ☐ México | ☐ |
| 2 | ☐ Argentina | ☐ |
| 3 | EUA | Reunión secreta de la ONU: Trump |

Tiene sentido acabar en EUA, porque la sede de la ONU está en Nueva York. ☐ Confirmar el orden de México y Argentina.

## Nivel 1 (México): propuesta visual

Nivel 1 de prueba para la mejora gráfica. Si convence, se sigue igual con los demás niveles.

![Referencia visual del nivel 1](propuestas/nivel1/referencia.png)

| Fase | Escenario | Jefe | Idea |
|---|---|---|---|
| 1.1 | Selva del sureste | Minijefe: "el predicador de la mañanera" | Caricatura que recuerda a AMLO: pelo cano, cejas marcadas, atril y dedo levantado |
| 1.2 | Desierto del norte | Minijefe: "el privatizador" | Caricatura que recuerda a Salinas de Gortari: calvo, orejas grandes, bigote, bolsa de dinero |
| 1.3 | Capital | Jefa final: La Presidenta → Presidenta Mecha | Caricatura que recuerda a Sheinbaum. A mitad del combate se transfigura en una máquina parecida a ella, del tamaño del jefe mecha actual |

Hay que vencer al minijefe para pasar de fase. El héroe protagonista se mantiene.

**Sobre la imagen:** los fondos, el héroe y el HUD son capturas reales del juego (v0.6). Los jefes son bocetos estáticos generados con PixelLab ([`propuestas/nivel1/`](propuestas/nivel1/)) y pegados encima. Todavía no hay nada en el código. Para el juego harían falta animaciones de cada jefe (moverse, atacar, recibir daño). Además, el mecha tendría que llevar armas y la banda tricolor bien hecha.

## Preguntas abiertas

- ☐ **Caricaturas de políticos reales vs. regla de "personajes siempre ficticios"** (PR #4/#5). Hay que decidirlo juntos antes de pasar estos bocetos al juego. Las caricaturas buscan parecido, no ser idénticas.

- ☐ **¿Sustituye esta historia a la del General Zarko (intro v0.2) o se combinan?**
- ☐ ¿Cómo encajan las misiones actuales (Jungla, Desierto Rojo) en los países? ¿Se reaprovechan como fases?
- ☐ ¿Quién es el jefe final de México y de Argentina?
- ☐ ¿Qué hacen exactamente el mercader y el ayudante?
- ☐ Tono y límites de la parodia, sobre todo si el juego se publica (itch.io, Steam): caricatura, nombres reales o apodos.
