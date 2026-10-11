# Mapa de la fase 1.1: pueblo de la pampa (12 tramos)

Autor: Eduardo, con Claude · 11-10-2026 · Estado: **en curso**. Los tramos 1 y 2 ya están en el juego (rama `eduardo/argentina-graficos`).

## Referencia

[`referencia_pueblo_completo.png`](referencia_pueblo_completo.png): idea de Eduardo de cómo se ve el pueblo seguido, de punta a punta: casas con bandera, almacén, garaje con camión viejo, capilla con torre de reloj y plaza con monumento, otro almacén y la estación de tren con un vagón. Es solo referencia: los tramos reales van a la escala del juego y **sin civiles**.

## Cómo encaja en el juego

- **Fondo lejano:** el cielo del atardecer con la pampa (`tools/sprites/chatgpt/pueblo/cielo_pampa.png`). Va detrás de todo y se mueve muy despacio.
- **Tramos:** `tools/sprites/chatgpt/pueblo/tramoNN.png`, uno detrás de otro, a la misma velocidad que la calle. Cada uno ocupa unas 1,4 pantallas (675x270 en el juego).
- **Calle llana:** sin fosos ni tablones flotantes. Los enemigos y vehículos los pone el juego; los tramos son solo escenario.
- **12 tramos:** unos 8100 px, casi 3 veces la fase actual (3000 px). ☐ Falta confirmar el largo y repartir más enemigos.

## Los 12 tramos

La historia de la 1.1 (ver la propuesta Blue Beam): un despliegue militar bloquea el pueblo y los héroes encuentran las primeras marcas **B.B.** Cada tramo sube un poco la tensión: primero vida normal, después controles militares y al final la plaza tomada.

| # | Tramo | Qué se ve | Pista B.B. |
|---|---|---|---|
| 1 | ✅ Entrada al pueblo | Casa de ladrillo, almacén con toldo verde, camioneta vieja, torre de antenas al fondo | Torre de antenas |
| 2 | ✅ Casas con portón | Casa con galería, portón verde, reja entre pilares, poste de luz | |
| 3 | Primer control | Casas bajas, almacén de ramos generales cerrado con persiana, barrera militar y sacos de arena en la vereda | |
| 4 | Taller mecánico | Garaje abierto con un camión viejo verde, tractor rojo, herramientas en la pared, barriles, logo **B.B.** pintado en el muro | ✔ Primer logo B.B. |
| 5 | Capilla y plaza | Capilla con torre de reloj y cruz, plaza con monumento en el centro, faroles dobles, bancos y macetas, bandera argentina | |
| 6 | Escuela rural | Escuela con mural, alambrado, bicicletas, afiches de propaganda ("PROHIBIDO PREOCUPARSE") | Afiches |
| 7 | Estación de servicio vieja | Surtidores oxidados sin marca, techito de chapa, camión militar estacionado | |
| 8 | Acopio de granos | Silos de chapa, galpón, tanque de agua elevado | |
| 9 | Antena camuflada | Torre con parabólicas disfrazada de tanque de agua, cerco militar con reflectores y cables | ✔ Equipo B.B. a la vista |
| 10 | Estación de tren abandonada | Galpón de la estación, andén, cartel con el nombre del pueblo, vagón de carga oxidado sobre las vías | |
| 11 | Calle principal | Club social o bar con mesas afuera, faroles, banderines celestes y blancos | |
| 12 | Plaza de la municipalidad | Municipalidad con escudo, mástil con bandera, camiones militares, sacos de arena. **Arena del jefe Massa:** lo importante va en el centro, se ve una sola pantalla (480 px) | Monitor o caja con B.B. |

## Reglas para cada tramo (ChatGPT)

1. **Mismo estilo:** adjuntar el tramo 1 y el tramo anterior como referencia.
2. **Proporción 2,5 a 1** (por ejemplo 1983x793 o 1500x600). Fondo **transparente**: sin cielo.
3. **Empalme:** el borde izquierdo continúa lo que corta el borde derecho del tramo anterior (casa, cerca o árbol).
4. **Calle a la misma altura:** la vereda y los adoquines en la misma franja de abajo que el tramo 1.
5. **Sin personas:** ni héroes, ni soldados, ni políticos, ni vecinos. Puertas y ventanas vacías.
6. **Calle vacía:** sin cajas, sacos ni barriles encima de los adoquines. Lo que tiene que estar en la calle lo pone el juego.

### Texto base para pedirlo

> Continúa este pueblo de la pampa argentina en el mismo estilo pixel art y con la misma luz de atardecer que las imágenes adjuntas. Imagen ancha de proporción 2,5 a 1, con fondo transparente (sin cielo). El borde izquierdo debe continuar exactamente lo que corta el borde derecho de la imagen anterior. La vereda y la calle de adoquines van a la misma altura que en la imagen anterior y la calle queda vacía. Sin ninguna persona: ni héroes, ni soldados, ni vecinos; puertas y ventanas vacías. En este tramo: [descripción del tramo de la tabla].
