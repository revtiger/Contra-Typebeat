# Historia y personajes: propuesta de Eduardo

Idea original: Eduardo (PR #2, 26-09-2026) · Integración: Gwyn · Estado: **propuesta, pendiente de acordar entre los dos**

> Parodia política estilo Contra / Metal Slug / Broforce con **caricaturas de políticos reales**. El 28-09-2026 Gwyn cambió la regla anterior de "personajes siempre ficticios": ahora se permiten los políticos reales de la propuesta de Eduardo. Cuando se acuerde el resto, se integra en [`diseno.md`](diseno.md). Lo marcado con ☐ está por decidir.

## Premisa

Run and gun 2D estilo Metal Slug, en tono de parodia de personajes políticos.

**Objetivo:** detener a **Donald Trump** en la reunión secreta de las Naciones Unidas en Nueva York.

**Giro de la historia:** Trump planea traicionar a los países aliados lanzando bombas sobre países clave para dominar el mundo. Tiene aliados en cada país a los que hay que detener antes de llegar a él.

## Personajes

| Rol | Personaje | Qué hace |
|---|---|---|
| Héroes | Los 4 soldados de ELIGE TU SOLDADO (El Presi, La Tenienta, El Chato, Don Bigotes) | Jugables e inventados. Eduardo proponía 2 stickman; ya existen estos 4. ☐ ¿Cooperativo a 2 jugadores? |
| Mercader | **Vladimir Putin** | Vende armas y mejoras entre fases. ☐ ¿Con qué se paga (puntos, monedas)? |
| Ayudante | **Papa Francisco** | Ayuda al jugador. ☐ ¿Cómo? (vida extra, escudo, aparece en momentos difíciles…) |

### Jefes por país

Cada país tiene semijefes y un jefe final: 3 jefes finales en total, uno por nivel.

| País | Personajes | Jefe final |
|---|---|---|
| México | Claudia Sheinbaum, Andrés Manuel López Obrador (AMLO), Carlos Salinas de Gortari, Felipe Calderón | **Sheinbaum** → Presidenta Mecha (ver nivel 1) |
| Argentina | Javier Milei, Néstor y Cristina Kirchner (jefe doble), Sergio Massa | ☐ |
| EUA | Donald Trump, Barack Obama, Joe Biden | **Trump** (jefe final del juego, en la ONU) |

## Niveles

3 niveles, uno por país, con 3 fases cada uno (1.1, 1.2, 1.3…):

| Fase | Contenido |
|---|---|
| X.1 | Recorrido + semijefe |
| X.2 | Recorrido + semijefe |
| X.3 | Recorrido + jefe final del país |

La ruta actual del juego ya va de sur a norte y acaba en la ONU de Nueva York (idea de Eduardo): Triple Frontera (Argentina–Brasil) → Bolivia → frontera México–EE.UU. → EE.UU.

## Nivel 1 (México): propuesta visual de Eduardo

Nivel 1 de prueba para la mejora gráfica. Si convence, se sigue igual con los demás niveles.

![Referencia visual del nivel 1](propuestas/nivel1/referencia.png)

| Fase | Escenario | Jefe | Idea |
|---|---|---|---|
| 1.1 | Selva del sureste | Minijefe: **AMLO**, "el predicador de la mañanera" | Pelo cano, cejas marcadas, atril y dedo levantado. Dispara desde detrás del atril. |
| 1.2 | Desierto del norte | Minijefe: **Salinas de Gortari**, "el privatizador" | Calvo, orejas grandes, bigote y bolsa de dinero. Lanza bolsas de dinero que explotan. |
| 1.3 | Capital | Jefa final: **Sheinbaum** → **Presidenta Mecha** | A mitad del combate se transfigura en una máquina parecida a ella, del tamaño del jefe mecha actual (jefe por piezas de la misión 3). |

Hay que vencer al minijefe para pasar de fase. El héroe protagonista se mantiene.

**Sobre la imagen:** los fondos, el héroe y el HUD son capturas reales del juego (v0.6). Los jefes son bocetos estáticos generados con PixelLab ([`propuestas/nivel1/`](propuestas/nivel1/)) y pegados encima. Todavía no hay nada en el código. Para el juego harían falta animaciones de cada jefe (moverse, atacar, recibir daño). Además, el mecha tendría que llevar armas y la banda tricolor bien hecha.

## Preguntas abiertas

- ☐ ¿Cómo encajan las misiones actuales (Jungla, Bolivia, Frontera Norte) en los 3 países? ¿Pasan a ser fases?
- ☐ ¿Quién es el jefe final de Argentina? (¿Milei, o los Kirchner como jefe doble?)
- ☐ ¿Qué papel tienen Calderón, Obama y Biden (semijefes, cameos)?
- ☐ ¿El Comandante Kruger se queda como jefe de algún país?
- ☐ ¿Qué hacen exactamente Putin (mercader) y el Papa Francisco (ayudante), y en qué momento aparecen?
- ☐ ¿Más países o políticos? La lista se puede ampliar.
- ☐ Al publicar (itch.io, Steam): revisar las normas de cada tienda sobre personas reales antes de subirlo.
- ✅ El final chistoso ya aprobado: todos los villanos "reciben su merecido".
