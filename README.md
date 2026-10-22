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

## Capítulos
El mundo se divide en 5 capítulos (`data/chambers.json`, "chapters"). Cada uno enseña un tema y
termina con su jefe. Por ahora se juegan el 1 y el 2; la Criba y el Mural esperan en el 3 y el 4. Al vencer al jefe de un
capítulo, Tala llega al mapa del siguiente (`hub` en el JSON).

| Capítulo | Tema | Salas |
|---|---|---|
| 1. El Templo de Aritma | instrucciones en orden, métodos y variables (sin bucles) | Compuerta, Faro, Figuras, Sendero, Trono (jefe) |
| 2. El Bosque | if / else | Puente, Jardín, Claro del Guardián (jefe) |
| 3. La Cueva | while | Criba (y sale al mirador) |
| 4. Las Ruinas del Mural | funciones con return | Mural |
| 5. La Cima | for y listas | (por hacer, jefe final) |

## Las salas del capítulo 1
| Sala | Máquina | Qué hay que hacer | Después |
|---|---|---|---|
| 1. La Compuerta del Nivel | Compuerta | Variables: `nivel = sensor.leer()`, `nivel = nivel + 3`, `compuerta.subir(nivel)` (3 rondas con números distintos) | — |
| 2. El Vórtice de Celdas | Faro | `luces.encender()` (como `puerta.abrir()` en el pueblo): enciende la sala y el tablero | Buscaminas: E destapa, Q bandera; 10 minas; siempre se resuelve sin adivinar; una mina = −2 corazones y tablero nuevo. Sin guardianes. |
| 3. La Mesa de las Figuras | Mesa | Sin código: llenar una figura grande con piezas más pequeñas (se arrastran con el ratón; R o clic derecho las gira). Dos figuras: un rectángulo y una casa con las piezas giradas | — |
| 4. La Singularidad del Cero | — | Sin código: cruzar el abismo por losas numeradas pisando solo las que cumplen la regla (múltiplos de 3 o de 4, al azar) | Una losa mala se rompe y Tala cae (−½ corazón); la losa queda rota. Tomar el núcleo lleva al Trono. |
| 5. El Trono del Cero | — | Nada: es el **jefe del capítulo 1**, el Guardián del Cero (tengu rojo) | 16 de vida en 4 fases. Ráfaga de orbes, pisotón con círculo rojo (salir o saltar con ESPACIO; −1 corazón). Al perder cada cuarta parte se cubre con un escudo y pone un **problema** sin bucles (cuánto vale una variable, en qué orden van las líneas, par/impar después de calcular; 20 s): si aciertas cae el escudo; si fallas llama 4, 5 o 6 guardianes. Al caer el escudo deja una **poción**. Si Tala cae, el jefe vuelve a vida llena. Vencerlo cierra el capítulo 1. |

Salas guardadas para otros capítulos: **la Criba** (separar pares e impares con while + if, capítulo 3)
y **el Mural de la Incógnita** (`despejar(a, b, c)` con return, capítulo 4).

## Las salas del capítulo 2
Se entra por las ruinas al norte de `bosque.tscn`. Cada sala prueba el programa en 3 rondas con números distintos.

| Sala | Máquina | Qué hay que hacer |
|---|---|---|
| 1. El Puente Colgante | Puente | `peso = carreta.peso()`, `if peso > 10:` → `puente.reforzar()` |
| 2. El Jardín de las Macetas | Maceta | `agua = maceta.medir()`, `if agua < 5:` → `maceta.regar()`, `else:` → `maceta.asolear()` |
| 3. El Claro del Guardián | — | Jefe del capítulo 2: el Guardián del Bosque. Sus problemas son de if y de if/else (qué imprime). |

## Misiones secundarias
Están en `data/quests.json`. Los personajes con misión tienen un **«!»** sobre la cabeza (y **«?»** si
la misión sigue abierta). La pausa muestra la lista de misiones. Se guardan con la partida.

Cada misión cumplida da **1 punto de habilidad**.

| Personaje | Dónde | Misión | Recompensa |
|---|---|---|---|
| Mila | Raíz | 3 cuentas de variables (`n = 4`, `n = n + 3`… ¿cuánto vale n?) | 1 punto |
| Tuerca (robot) | Sala 1, la Compuerta | ordenar 2 programas desordenados (`pasos = 2` → `pasos = pasos + 1` → `tuerca.avanzar(pasos)`) | 1 punto |
| Brasa | Raíz | encontrar 3 engranajes de bronce escondidos en las salas 1, 2 y 3 | 1 punto |
| Ramas | Bosque | 3 preguntas de if / else | 1 punto |
| Lía | Bosque | encontrar 3 hongos azules (uno en el bosque, uno en cada sala) | 1 punto |

Las preguntas de las misiones usan el mismo cuadro que el jefe, pero sin castigo: si fallas,
vuelves a hablar con el personaje. Los engranajes cuentan aunque no hayas hablado con Brasa.

## Habilidades
Las misiones dan 1 punto y cada jefe da 2. Se gastan en **pausa → HABILIDADES** (`config.json`, "skills"):

| Habilidad | Máx. | Por nivel |
|---|---|---|
| Vida | 3 | +1 corazón |
| Fuerza | 2 | +1 de daño del garrote |
| Aliento | 2 | +50 % de energía para correr y saltar |
| Tiempo de pensar | 3 | +5 s en las preguntas de los jefes |

## En el celular
El Códice se abre a pantalla completa y más grande (`touch_codex_zoom`), y la cámara se acerca a la
máquina mientras prueba el programa (`touch_machine_zoom`). En el PC se prueba con `-- --tactil`.

## Guardianes y corazones
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
- Caer a un foso o a una prensa: **−½ corazón** y vuelves al borde. Quedarse sin corazones:
  de vuelta a la entrada de la sala con la vida llena (no hay fin del juego).
- La pausa y el libro (TAB) detienen a los guardianes.
- Todos los números están en `data/config.json`: secciones `combat` (guardianes, corazones, castigos) y `boss` (la pelea con el jefe).
- Si el código tiene un error, la consola del Códice lo conserva: al volver de pelear sigue ahí.

## Pruebas automáticas
```
godot --path . -- --selftest                       # pruebas de reglas y del recorrido completo
godot --path . -- --recorrido=/carpeta[:sala2|:sala3|:sala4|:sala5|:jefe|:compuerta|:misiones|:bosque]  # capturas del camino del jugador
```
