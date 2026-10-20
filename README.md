# Paredes Vivas 2D: La Cámara de los Aritmanos (versión con escenas)

Juego de puzles en Godot **4.4.1** para Ingeniería de Software II (SENA). En esta versión el
mundo está armado con **escenas `.tscn`**, que se ven y se editan en el editor. Antes, todo se
construía por código al ejecutar el juego.

## Abrirlo
1. Abrir **Godot 4.4.1**. Godot 3.5 no sirve: muestra el error *"creada por una nueva
   versión del motor"*.
2. **Importar** → elegir `project.godot` de esta carpeta → **Importar y editar**.
3. **F5** ejecuta el juego. **F6** ejecuta solo la escena que está abierta.

## Dónde está cada cosa
| Carpeta | Qué hay |
|---|---|
| `main.tscn` | Escena principal: `Main` (game.gd), `Camara`, `Tala` y la `Interfaz`. |
| `scenes/niveles/` | `pueblo.tscn` y las 6 salas: `sala_1_filtro`, `sala_2_raices`, `sala_3_vortice`, `sala_4_figuras`, `sala_5_singularidad`, `sala_6_trono` (el jefe final). |
| `scenes/objetos/` | Piezas reutilizables: antorcha, brasero, columna, letrero, estatua, árboles, prensa. |
| `scenes/maquinas/` | Atril, Criba (Sala 1), Mural (Sala 2), Faro (Sala 3), Mesa de las Figuras (Sala 4) y el atril de la puerta del templo. |
| `scenes/personajes/` | Tala (jugadora, con su garrote) y Orun. |
| `scenes/enemigos/` | Los guardianes de la tumba: `centinela.tscn` (caballero dorado, golpea de cerca), `hechicero.tscn` (lanza orbes de lejos, `orbe.tscn`) y `runico.tscn` (explota). `scenes/objetos/estatua_guardian.tscn` es el mismo guardián dormido sobre su pedestal. |
| `assets/tiles/` | TileSets: `suelo.tres` (se pisa) y `muros.tres` (todo lo que se pinta ahí es sólido y hace sombra). |
| `src/` | Scripts: reglas, patrones de diseño, intérprete del Códice. |
| `data/` | Textos, salas y configuración (JSON): nada de esto está escrito a mano en el código. |
| `docs/ARQUITECTURA.md` | Patrones de diseño, SOLID y el diagrama UML de las clases principales. |
| `docs/UML_COMPLETO.md` | El UML de **todas** las clases, generado desde el código con `python3 tools/generar_uml.py`. |

## Cómo está armado un nivel
Cada nivel tiene los mismos nodos:
- **Suelo**, **Detalles** y **Muros** (TileMapLayer): el mapa se pinta con tiles.
- **Actores** (ordenados por altura, *y-sort*): objetos, personajes y máquinas.
- **Efectos**: antorchas y prensas, que se dibujan por encima.
- **Bordes**: bloqueos invisibles.
- **Zonas**: entradas, puntos seguros y la salida.
- **Fosos**: aparecen como recuadros rojos en el editor.
- **Guardianes/Caidas** (opcional): `Marker2D` donde caen los guardianes del techo. Las
  estatuas (`estatua_guardian.tscn`) se ponen en **Actores**. Si una sala no tiene ninguna de
  las dos cosas, sus errores no despiertan guardianes.
- **Inicio**: el punto donde aparece Tala.
- **Ambiente**: el color de la luz.

El script del nivel no dibuja nada. Al cargarse, conecta lo que hay en la escena (letreros,
puntos seguros, fosos, máquinas).

## Las 6 salas (15 minutos en total)
| Sala | Máquina | Qué hay que hacer | Después |
|---|---|---|---|
| 1. El Filtro de la Dualidad | Criba | Separar esferas pares e impares (3 rondas) | — |
| 2. El Mural de la Incógnita | Mural | `despejar(a, b, c)`: devolver la x de ax + b = c, o sea `(c - b) / a` (3 ecuaciones: solo se ve la primera) | — |
| 3. El Vórtice de Celdas | Faro | `luces.encender()` (como `puerta.abrir()` en el pueblo): enciende la sala y el tablero | Buscaminas: E destapa, Q bandera; 10 minas; siempre se resuelve sin adivinar; una mina = −2 corazones y tablero nuevo. Sin guardianes. |
| 4. La Mesa de las Figuras | Mesa | Sin código: llenar una figura grande con piezas más pequeñas (se arrastran con el ratón; R o clic derecho las gira). Dos figuras: un rectángulo y una casa con las piezas giradas | — |
| 5. La Singularidad del Cero | — | Sin código: cruzar el abismo por losas numeradas pisando solo las que cumplen la regla (múltiplos de 3 o de 4, al azar) | Una losa mala se rompe y Tala cae (−7 s); la losa queda rota. Tomar el núcleo lleva a la Sala 6. |
| 6. El Trono del Cero | — | Nada: es el **jefe final**, el Guardián del Cero (tengu rojo) | 16 de vida en 4 fases. Ráfaga de orbes (3, 5, 6, 7), pisotón con círculo rojo (salir o saltar con ESPACIO; −1 corazón). Al perder cada cuarta parte se cubre con un escudo y pone un **problema** de repaso (par/impar, múltiplo, despejar x; 15 s): si aciertas cae el escudo; si fallas llama 4, 5 o 6 guardianes. Al caer el escudo deja una **poción**. Al entrar se recuperan 2 corazones. Si Tala cae, el jefe vuelve a vida llena. Vencerlo gana. |

## Guardianes, corazones y castigos de tiempo
- Cada vez que una máquina rechaza el código (también por un error de escritura) sube la
  **alarma** de la sala: la primera vez despiertan las estatuas; después caen guardianes del
  techo (2, 3, 4, 4, 5 y hasta 6, cada vez un poco más rápidos). Cada tipo tiene un aro de
  color bajo los pies: dorado el caballero, morado el hechicero (desde la alarma 2), rojo el
  rúnico (desde la alarma 3). Atacan en formación: los caballeros rodean a Tala y cubren al
  hechicero; el hechicero mantiene la distancia y, si algo le tapa el tiro, se teletransporta. Mientras quede uno, la máquina
  está bloqueada. Al resolver la sala la alarma vuelve a 0. Resolver salas **no** cura: solo se recuperan 2 corazones al entrar a la sala del jefe y con las pociones que deja al caer su escudo.
- Desde la alarma 3 cae también el **guardián rúnico** (calavera con aura roja): no golpea,
  se carga y explota. Si Tala queda dentro del círculo rojo, aparece el **reto de teclas**:
  pulsar en orden 4 a 7 teclas (A S D F J K L) en 5 a 8 segundos, tras un segundo para
  leerlas; las demás teclas no cuentan. Si falla, −2 corazones.
- Tala golpea con **J** o clic (garrote; salen símbolos `+ − × ÷ { } ;`). Tiene 5 corazones;
  el golpe de un centinela quita medio.
- Caer a un foso o a una prensa: **−7 s**. Quedarse sin corazones: **−1 minuto** y de vuelta
  a la entrada de la sala; si quedaba 1 minuto o menos, **fin del juego**.
- La pausa detiene el reloj y a los guardianes. El libro (TAB) detiene a los guardianes, pero
  el reloj sigue.
- Todos los números están en `data/config.json`: secciones `combat` (guardianes, corazones, castigos) y `boss` (la pelea con el jefe).
- Si el código tiene un error, la consola del Códice lo conserva: al volver de pelear sigue ahí.

## Pruebas automáticas
```
godot --path . -- --selftest                       # 151 pruebas de reglas y del recorrido completo
godot --path . -- --recorrido=/carpeta[:sala2|:sala3|:sala4|:sala5|:jefe]  # capturas del camino del jugador
```
