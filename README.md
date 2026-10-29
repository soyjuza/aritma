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
| `src/` | Scripts: reglas, patrones de diseño, el motor SQL del Códice (`src/sql_lang/`). |
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

## Aprender SQL
El Códice ya no habla Python: habla **SQL**, el idioma con que se le pregunta a una base de datos.
Las máquinas de Aritma guardan todo en **tablas** (columnas arriba, filas abajo) y obedecen a quien les
escribe una **consulta**. Cada capítulo agrega una parte, de lo más básico hasta JOIN:

| Capítulo | Mapa | Tema SQL | Salas |
|---|---|---|---|
| 1. El Templo de Aritma | Raíz (`pueblo.tscn`) | `SELECT` y `FROM`: una columna, varias, `*` | Compuerta, Faro, Figuras, Sendero, Trono (jefe) |
| 2. El Bosque | `bosque.tscn` | `WHERE` con `> < =` y textos entre `'comillas'` | Puente, Jardín, Claro del Guardián (jefe) |
| 3. La Cueva | `cueva.tscn` | `AND` y `OR` | Bomba, Criba, Claro de Cristal (jefe) |
| 4. El Mirador | `mirador.tscn` | `ORDER BY`, `DESC` y `LIMIT` | Molino, Mural, Salón del Mural (jefe) |
| 5. La Cima | `cima.tscn` | `JOIN` e `INNER JOIN ... ON` | Campanas, Balanza, Árboles Gemelos, Trono de la Cima (jefe final) |

**Cómo se juega una sala.** El atril abre el Códice. A la derecha están las piezas de SQL de la sala y
las **tablas de la ronda 1** con sus filas. Se arma la consulta con **piezas** (en los capítulos 1 y 2, y
siempre en el celular) o se **escribe a mano** (desde el capítulo 3 en el PC; el botón cambia de modo).
Las piezas traen algunas equivocadas a propósito (`WHERE peso < 10`, `WHERE tierra = seca`...) y cada
parte de SQL tiene su color: SELECT cian, FROM dorado, WHERE/AND/OR naranja, ORDER BY/LIMIT morado y
JOIN/ON verde. Al ejecutar, la consola muestra **la tabla que trajo la consulta**, y la máquina la prueba
en 3 rondas con tablas distintas (solo se ve la primera): no sirve copiar los nombres a mano.

**Errores.** Hay dos tipos y los dos despiertan guardianes:
1. *La consulta no se entiende* (`SqlLexer`, `SqlParser`, `SqlEngine`): el Códice dice la línea y qué
   pasó, con una pista. Ejemplos: «No conozco «SELEC». ¿Quisiste decir SELECT?», «Falta FROM»,
   «No existe la tabla «carreta». ¿Quisiste decir «carretas»?», «Si «seca» es un texto, va entre comillas:
   'seca'», «En SQL se compara con un solo =», «WHERE está fuera de lugar. El orden es: SELECT … FROM …».
2. *La consulta corre pero trae otra cosa* (`SqlCheck` compara con la respuesta de la sala): «Tu consulta
   trajo las columnas «nombre, peso», pero la máquina pide «nombre»», «Sobra la fila «Sal»», «Falta la fila
   «Roca»» o «Las filas están bien, pero en otro orden».

Todos los mensajes están en `data/texts.json` (`sql_errors` y las claves `sql_check_*`).

| Sala | Máquina | Tablas | Consulta que la resuelve |
|---|---|---|---|
| Puerta del templo | Puerta | `puerta(palabra, forma)` | `SELECT * FROM puerta` |
| 1. La Compuerta del Nivel | Compuerta | `sensor(color, nivel, hora)` | `SELECT nivel FROM sensor` |
| 2. El Vórtice de Celdas | Faro | `faro(nombre, color, brillo)` | `SELECT color, brillo FROM faro` (después, el buscaminas) |
| 3. La Mesa de las Figuras | Mesa | — | Sin consulta: rompecabezas de piezas |
| 4. La Singularidad del Cero | — | — | Sin consulta: losas con múltiplos |
| El Puente Colgante | Puente | `carretas(nombre, peso)` | `SELECT nombre FROM carretas WHERE peso > 10` |
| El Jardín de las Macetas | Maceta | `macetas(nombre, tierra, hojas)` | `SELECT nombre FROM macetas WHERE tierra = 'seca'` |
| La Bomba de la Cueva | Bomba | `tanques(nombre, nivel, valvula)` | `... WHERE nivel < 5 AND valvula = 'abierta'` |
| El Filtro de la Dualidad | Criba | `esferas(numero, color)` | `SELECT numero FROM esferas WHERE color = 'oro' OR numero > 50` |
| El Molino de la Montaña | Molino | `sacos(nombre, peso)` | `SELECT nombre FROM sacos ORDER BY peso DESC` (importa el orden) |
| El Mural de los Récords | Mural | `aritmanos(nombre, puntos, edad)` | `SELECT nombre, puntos FROM aritmanos ORDER BY puntos DESC LIMIT 3` |
| Las Campanas de la Cima | Campanas | `partitura(orden, campana)`, `campanas(nombre, numero)` | `SELECT campanas.numero FROM partitura JOIN campanas ON partitura.campana = campanas.nombre` |
| La Balanza de las Pesas | Balanza | `cajas(caja, pesa_id)`, `pesas(id, kilos)` | `SELECT cajas.caja, pesas.kilos FROM cajas INNER JOIN pesas ON cajas.pesa_id = pesas.id` |
| Los Árboles Gemelos | Gemelas | `ninos(nombre, arbol_id)`, `arboles(id, fruta)` | `... INNER JOIN arboles ON ninos.arbol_id = arboles.id WHERE arboles.fruta = 'manzana'` |

Cualquier consulta que traiga lo mismo vale (otro orden de columnas, minúsculas, alias, `>= 11` en vez
de `> 10`...). La respuesta de cada sala está en `data/chambers.json` (`answer`; `ordered` si importa el
orden de las filas). Los jefes preguntan qué trae una consulta sobre tablas chicas que se inventan al azar
(`src/chambers/quiz/`): la respuesta buena la calcula el mismo motor SQL, así nunca está mal puesta.

El libro de reglas (TAB) trae una **Guía de SQL** que crece con cada capítulo.

## El motor SQL (`src/sql_lang/`)
| Clase | Qué hace |
|---|---|
| `SqlLexer` | Parte el texto en palabras, números, 'textos' y símbolos. Acepta comillas curvas del celular y comentarios `--`. |
| `SqlParser` | Arma la consulta (`SqlQuery`) en el orden SELECT → FROM → JOIN/ON → WHERE → ORDER BY → LIMIT. |
| `SqlEngine` | Facade: `run(consulta, tablas)` revisa los nombres, junta las tablas, filtra, ordena y devuelve columnas y filas (o el error con su línea). También COUNT, SUM, MIN, MAX y AVG. |
| `SqlTable` | Una tabla: nombre, columnas y filas. |
| `SqlCheck` | Compara el resultado con la respuesta de la sala y dice qué columna o fila sobra o falta. |
| `SqlMessages` | Lee los mensajes de error de `texts.json`. |

Solo se puede **leer** (SELECT): INSERT, UPDATE, DELETE, LEFT JOIN, GROUP BY, LIKE... responden que
estas máquinas no los usan. Los textos se comparan sin importar mayúsculas.

## Cómo se hace una máquina nueva
1. Una escena en `scenes/maquinas/` con su atril (`atril.tscn`) y un script que extienda `SqlMachine`.
2. En el script: `make_tables(ronda)` inventa las tablas de cada ronda y `_draw()` dibuja la máquina
   (`_draw_tables()` pone las tablas en tablillas y marca las filas que trajo la consulta). Opcional:
   `react()` para animar lo que hace con el resultado.
3. En `data/chambers.json`: `answer`, piezas (`blocks`), ayuda (`help`), comentario inicial
   (`starter_code`, con `--`), `intro` y `solved_text`. `SqlMachine` hace el resto: corre la consulta en
   cada ronda, la compara con `answer` y avisa qué estuvo mal.

## Los jefes
Cada capítulo termina con un jefe (el primero, el Guardián del Cero: 16 de vida en 4 fases). Lanza
ráfagas de orbes y da pisotones con círculo rojo (salir o saltar con ESPACIO; −1 corazón). Al perder
cada cuarta parte se cubre con un escudo y pone una **pregunta de SQL** con las tablas dibujadas
(30 s): si aciertas cae el escudo; si fallas llama 4, 5 o 6 guardianes. Al caer el escudo deja una
**poción**. Si Tala cae, el jefe vuelve a vida llena.

| Jefe | Pregunta |
|---|---|
| Guardián del Cero | qué palabra falta (SELECT/FROM), qué muestra un SELECT, cuántas columnas trae |
| Guardián del Bosque | qué nombres deja pasar un WHERE y cuántas filas trae |
| Guardián de la Cueva | lo mismo, con AND y OR |
| Guardián de las Ruinas | en qué orden salen las filas con ORDER BY (y LIMIT) |
| Sombra del Sol Negro | qué trae un JOIN y cuántas filas deja un INNER JOIN |

## El mundo
Los mapas están unidos por sus bordes, como en Pokémon o Survival RPG: Raíz → Bosque → Cueva →
Mirador → Cima, siempre hacia el este (`data/chambers.json`, "maps"). El paso a cada zona nueva
está tapado por **rocas** que se derrumban al vencer al jefe del capítulo anterior; se puede volver
atrás cuando se quiera. Cada mapa tiene su templo (la entrada a sus salas); un templo ya vencido
no se vuelve a abrir. En el Mirador, el **balcón** del sur muestra todo el valle.

- `src/world/map_exit.gd`: zona del borde que lleva al mapa vecino (`target`, `entry`).
- `src/world/barrier.gd` + `scenes/objetos/rocas.tscn`: rocas con `need` (capítulo que las abre).
- `tools/crear_mundo.gd`: genera los 5 mapas (`godot --headless -s tools/crear_mundo.gd`).

## Misiones secundarias
Están en `data/quests.json`. Los personajes con misión tienen un **«!»** sobre la cabeza (y **«?»** si
la misión sigue abierta). La pausa muestra la lista de misiones. Se guardan con la partida.

Cada misión cumplida da **1 punto de habilidad**.

| Personaje | Dónde | Misión | Recompensa |
|---|---|---|---|
| Mila | Raíz | 3 preguntas de SELECT (¿qué muestra `SELECT nombre FROM gatos`?) | 1 punto |
| Tuerca (robot) | Sala 1, la Compuerta | ordenar las partes de 2 consultas desordenadas (`SELECT` → `FROM` → `WHERE`) | 1 punto |
| Brasa | Raíz | encontrar 3 engranajes de bronce escondidos en las salas 1, 2 y 3 | 1 punto |
| Ramas | Bosque | 3 preguntas de WHERE (¿qué filas deja pasar?) | 1 punto |
| Lía | Bosque | encontrar 3 hongos azules (uno en el bosque, uno en cada sala) | 1 punto |
| Grava | Cueva | 3 preguntas de AND y OR | 1 punto |
| Perla | Cueva | encontrar 3 cristales violetas (uno en la cueva, uno en la Bomba y uno en la Criba) | 1 punto |
| Pluma | Mirador | 3 preguntas de ORDER BY (¿en qué orden salen?) | 1 punto |
| Vigía | Mirador | encontrar 3 pergaminos (uno en el mirador, uno en el Molino y uno en el Mural) | 1 punto |
| Eco | Cima | 3 preguntas de JOIN (¿qué mascota tiene Ana?) | 1 punto |

Las preguntas de las misiones usan el mismo cuadro que el jefe, pero sin castigo: si fallas,
vuelves a hablar con el personaje. Los engranajes cuentan aunque no hayas hablado con Brasa.

## Habilidades
Las misiones dan 1 punto y cada jefe da 2. Se gastan en **pausa → HABILIDADES** (`config.json`, "skills"):

| Habilidad | Máx. | Por nivel |
|---|---|---|
| Vida | 3 | +1 corazón |
| Fuerza | 2 | +1 de daño del garrote |
| Aliento | 2 | +50 % de energía para correr y saltar |
| Tiempo de pensar | 3 | +5 s en las preguntas de los jefes (que ya dan 30 s) |

## En el celular
El Códice se abre a pantalla completa y más grande (`touch_codex_zoom`), y la cámara se acerca a la
máquina mientras prueba la consulta (`touch_machine_zoom`). En el PC se prueba con `-- --tactil`.

Para moverse hay dos controles, a elegir en **Ajustes → MOVERSE (CELULAR)**: la **palanca** que
aparece donde se toca la mitad izquierda de la pantalla, o la **cruceta** fija de 4 direcciones.

## Guardianes y corazones
- Cada vez que una máquina rechaza la consulta (también por un error de escritura) sube la
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
- Si la consulta tiene un error, la consola del Códice lo conserva: al volver de pelear sigue ahí.

## Pruebas automáticas
```
godot --path . -- --selftest                       # pruebas de reglas y del recorrido completo
godot --path . -- --recorrido=/carpeta[:sala2|:sala3|:sala4|:sala5|:jefe|:compuerta|:misiones|:bosque|:mundo|:celular]  # capturas del camino del jugador
```
