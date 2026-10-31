# Modo en línea, panel del admin y ejercicios al azar

Este documento resume los cambios de la rama `desarrollo` (commit `bfdc168`) y explica cómo funciona
todo. Sirve para retomar el trabajo o para pasárselo a otra persona (o a otra sesión de Claude).

## 1. Qué pidió el instructor y qué se decidió

El instructor David pidió:

1. Un **panel de administrador** para manejar el tiempo y otras reglas.
2. **Ejercicios al azar**, para que el juego no sea fácil si ya se pasó varias veces.
3. **Multijugador**: el admin crea una sala, inicia la partida con todo configurado, cada jugador
   tiene nombre, y quien pierde puede ver las partidas de los demás.

Decisiones tomadas (no hay que volver a discutirlas):

| Tema | Decisión |
|---|---|
| Conexión | **Por Internet**: un servidor propio (Node.js, carpeta `server/`), publicado en Railway. |
| Rol del admin | **Solo supervisa**: configura, inicia, controla y mira. No juega. |
| Ver a los demás | **Tablero + vista en vivo**: clasificación, y al elegir a alguien se ve su sala con su personaje moviéndose. |
| Azar | **Banco de variantes por sala**: cada sala sortea un enunciado distinto, no solo números distintos. |

## 2. Ejercicios al azar

### Cómo funciona

- En `data/chambers.json` algunas salas tienen una lista `"variants"`. Cada variante reemplaza
  claves de la sala (textos, etiquetas, código inicial, ayuda, reglas). Puede tener `"params"`:
  listas de valores de las que se sortea uno, y se ponen en los textos con `{k}`, `{t}`, etc.
- `src/core/challenge_deck.gd` (`ChallengeDeck`) sortea la variante de cada sala a partir de una
  **semilla**. Además le da a cada sala su propia semilla para los números.
- `DataRepository.roll_challenges(semilla)` guarda el resultado en `data.picks`.
  `DataRepository.chamber_data(i)` devuelve la sala ya con su variante.
- `Game.start_new_game(semilla)` sortea al empezar. Sin semilla usa una al azar. La semilla se
  guarda con la partida (`save_game`), así que al cargar salen los mismos ejercicios.
- **Misma semilla = mismos ejercicios.** Por eso el espectador puede cargar exactamente la sala
  del otro jugador.

### Las variantes

| Sala | Variantes | Dónde está la regla |
|---|---|---|
| 1. La Criba | pares/impares · múltiplos de 3, 4 o 5 · mayores que 15, 20, 25 o 30 | `ParityFilter.rule` (`{"kind": "multiple", "k": …}` o `{"kind": "greater", "t": …}`); `accepts(n)` decide |
| 2. El Mural | `ax + b = c` → `(c - b) / a` · `x/a + b = c` → `(c - b) * a` · `a(x + b) = c` → `c / a - b` | `RootsTrial.form` (`lineal`, `fraccion`, `parentesis`) |
| 3. El Vórtice | sin variantes: las minas ya cambian siempre | — |
| 4. La Mesa | Rectángulo + Casa · Escalera + Barco · Torre + Rombo | `"puzzles"` de cada variante |
| 5. El Sendero | múltiplos de 3, 4, 5 o 6 | lista `"rules"` |
| 6. El Trono | sin variantes: los problemas del jefe ya salen al azar | — |

Para **agregar una variante** solo hay que editar `chambers.json`, sin tocar código. La excepción
es una regla de Criba o una forma de ecuación nueva: esas se agregan en `ParityFilter.accepts`
o en `RootsTrial.make_case` / `equation`.

Detalles:

- Los mensajes de error de la Criba ahora vienen de la variante (`wrong_in`, `wrong_out`).
- La pista del Mural viene de la variante (`wrong_hint`) y se mete en el texto `mural_wrong` con `{hint}`.
- La fuente pixel (Jersey 10) **no tiene `≤`**. Por eso la etiqueta del crisol dice `HASTA {t}`.

## 3. Modo en línea: cómo se usa

Menú principal → **EN LÍNEA**. Ahí se escriben el nombre, el código de la sala y la dirección del
servidor. El nombre y la dirección se recuerdan en `user://en_linea.cfg`.

### El admin

1. **CREAR SALA (ADMIN)** → recibe un código de 5 letras y se abre el **panel del admin**.
2. Antes de empezar elige (← → cambian el valor):

| Opción | Rango | Por defecto |
|---|---|---|
| Tiempo | 3–60 min | 15 |
| Corazones | 1–10 | 5 |
| Castigo por caída | 0–30 s | 7 |
| Sin corazones (castigo) | 0–180 s | 60 |
| Máximo de jugadores | 1–60 | 30 |
| Mismos ejercicios | sí / no | no (cada uno con los suyos, así no se copian) |
| Ver a los demás | sí / no | sí |
| Empezar en el templo | sí / no | no (sí = se salta el pueblo) |

3. **INICIAR PARTIDA**. Durante la partida tiene **PAUSAR / REANUDAR A TODOS**,
   **+1 MINUTO A TODOS** y **TERMINAR PARTIDA**. Cuando termina: **OTRA PARTIDA** (mismos
   jugadores) o **CERRAR SALA**.
4. **TAB** pasa a la lista de jugadores: **ENTER** mira a uno en vivo, **SUPR** (o X) lo saca de
   la sala. En la vista en vivo: ↑/↓ cambian de jugador, **P** pausa o reanuda a todos y **ESC**
   vuelve al panel.

### Los jugadores

1. Escriben nombre y código → **UNIRSE A LA SALA** → sala de espera.
2. Cuando el admin inicia, todos empiezan a la vez con las reglas del admin.
3. En línea **la pausa no detiene el reloj** (sería trampa) y **no se puede guardar**. Salir desde
   la pausa abandona la partida.
4. La pausa del admin congela el juego y el reloj, y muestra «PAUSA DEL ADMIN».
5. Al ganar o perder, **Enter** lleva al modo espectador: la clasificación y los demás en vivo,
   si el admin lo permite.
6. Si se cae la red, el juego se reconecta solo con una clave y sigue en la misma sala.

### Clasificación

Primero los que ganaron, ordenados por menos tiempo usado. Después los demás, por la sala a la
que llegaron y, si empatan, por el tiempo que les queda.

## 4. Arquitectura

```
Jugador (Godot) ──estado 10/s──►  server/server.js  ──tablero 2/s──► todos
                                   (salas, reglas,   ──posiciones──► quien mira a ese jugador
Admin (Godot)   ──config/inicio──►  clasificación)   ──inicio/pausa/+tiempo──► jugadores
```

- **Cada jugador corre su partida completa en su PC.** El servidor no simula nada: reparte la
  semilla y la configuración, junta el tablero y reenvía posiciones.
- El **espectador** (`WatchView`) carga la misma sala con la misma semilla y esconde a Tala. En
  su lugar pone un `SpectatorGhost` que copia el dibujo de Tala y se mueve con las posiciones que
  llegan. El nivel queda congelado, así no dispara eventos.
- Si el otro ya resolvió la sala, el espectador la ve resuelta.
- **Limitación:** no se ve el Códice ni los guardianes del otro jugador. Solo la sala, su
  personaje, su estado y si la resolvió.

### Archivos nuevos y cambiados

| Archivo | Qué hace |
|---|---|
| `server/server.js` | Servidor de salas (Node.js + `ws`). Puerto en `PORT` (8080 por defecto). |
| `server/test.js` | 20 pruebas del servidor (`npm test`). |
| `src/net/net_client.gd` | `NetClient`: WebSocket. Mensajes JSON con el campo `"t"`. |
| `src/net/online_session.gd` | `OnlineSession` (Facade): rol, sala, tablero, espectador, reconexión. Avisa con señales. |
| `src/net/watch_view.gd` | `WatchView`: vista en vivo (carga la sala, mueve el fantasma, dibuja el panel). |
| `src/net/spectator_ghost.gd` | `SpectatorGhost`: la Tala del otro jugador. |
| `src/states/online_state.gd` | Pantalla EN LÍNEA (nombre, código, servidor). |
| `src/states/lobby_state.gd` | Sala de espera del jugador. |
| `src/states/admin_state.gd` | Panel del admin (configuración, controles, lista, vista en vivo). |
| `src/states/watch_state.gd` | Espectador para el jugador que ya terminó. |
| `src/ui/text_field.gd` | Campo de texto para la interfaz dibujada (admite CTRL+V). |
| `src/ui/net_board.gd` | Tabla de jugadores (puesto, nombre, estado, sala, tiempo, corazones). |
| `src/core/challenge_deck.gd` | Sorteo de variantes. |
| `src/tests/net_test.gd` | 28 pruebas en línea contra un servidor real. |
| `src/game.gd` | Crea `OnlineSession` y conecta sus señales. Además: `apply_match_rules`, `net_state`, `admin_paused`, `load_watch_level`, `show_town` y la semilla de los ejercicios. |
| `src/states/{menu,play,pause,end}_state.gd` | Opción EN LÍNEA, modo `"online"`, pausa sin guardar y con reloj corriendo, Enter → espectador. |
| `src/player/player_controller.gd` | `pose()`: animación y salto, para el espectador. |
| `src/chambers/{parity_filter,criba_machine,roots_trial,mural_machine}.gd` | Reglas de la Criba y formas del Mural según la variante. |
| `data/*.json` | Variantes, textos nuevos (`net_*`, `admin_*`, `watch_*`, `admin_rows`) y `server_url`. |

Los textos «tienes {min} minutos» y «Pasaron los {min} minutos» ahora siguen el tiempo real de la
partida.

### Protocolo (mensajes JSON, campo `"t"`)

| De → a | Mensajes |
|---|---|
| Admin → servidor | `create`, `config {config}`, `start`, `pause {on}`, `add_time {sec, id?}`, `kick {id}`, `end`, `reset`, `close` |
| Jugador → servidor | `join {code, name}`, `state {s}`, `done {won, used}`, `leave` |
| Cualquiera → servidor | `watch {id}` (un jugador solo puede mirar si ya terminó y el admin lo permite), `resume {code, token}` (reconexión) |
| Servidor → clientes | `created`, `joined`, `lobby`, `board`, `start {seed, config}`, `pause`, `add_time`, `snap {id, s}`, `ended`, `reset`, `kicked`, `closed`, `error {key}` |

El estado `s` de un jugador tiene estos campos:

| Campo | Qué es |
|---|---|
| `c` | sala (-1 = pueblo) |
| `x`, `y` | posición |
| `a` | animación |
| `hop` | altura del salto |
| `h`, `mh` | medios corazones y máximo |
| `tl` | tiempo que le queda |
| `sd` | semilla de sus ejercicios |
| `ok` | si ya resolvió la sala |

Otros detalles del servidor:

- Valida y recorta la configuración a los rangos de la tabla de la sección 3.
- Una sala sin admin se borra a los 10 minutos.
- Al sacar a un jugador, cierra su conexión 300 ms después de avisarle. Si la cerrara de
  inmediato, Godot perdería el aviso.

## 5. Cómo correrlo y probarlo

Godot 4.4.1 no está en el PATH: `C:\Users\SENA\Godot\Godot_v4.4.1-stable_win64_console.exe`.

```
# Servidor
cd server
npm install
npm start                      # puerto 8080
npm test                       # 20 pruebas

# Juego (desde la raíz)
godot --headless --path . --import                    # después de crear clases nuevas (class_name)
godot --headless --path . -- --selftest               # 160 pruebas
godot --headless --path . -- --nettest=ws://127.0.0.1:8080          # 28 pruebas en línea
godot --path . -- "--nettest=ws://127.0.0.1:8080,C:/carpeta"         # además guarda capturas
```

Para probar a mano en un solo PC: arrancar el servidor y abrir el juego dos veces. Una ventana
crea la sala (admin) y la otra se une con el código.

## 6. Pendiente

- ~~Publicar el servidor~~ **Hecho (31 oct 2026)**: está en Railway (proyecto `aritma-servidor`,
  servicio `servidor-salas`) en `wss://servidor-salas-production.up.railway.app`, que ya es el
  `server_url` de `data/config.json`. Se despliega con `railway up --ci` desde `server/` (no hay
  GitHub conectado; ver README). Las 28 pruebas en línea pasan contra Railway:
  `godot --headless --path . -- --nettest=wss://servidor-salas-production.up.railway.app`.
- Opcional: mostrar en la vista en vivo el Códice o los guardianes del otro jugador.
- Los `.import`, `.tres`, `main.tscn` y `project.godot` que aparecen modificados en git son solo
  cambios de fin de línea del editor. No se subieron.
