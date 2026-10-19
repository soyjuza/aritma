## Pruebas automáticas que juegan de verdad (mueven a Tala con eventos de teclado, no la
## teletransportan salvo para empezar cada prueba). Ejecutar:
##   Godot --headless --path . -- --selftest
class_name SelfTest
extends RefCounted

const ROOTS_OK := "def factorizar(b, c):\n    for p in range(-abs(c), abs(c) + 1):\n        q = b - p\n        if p * q == c:\n            return [p, q]\n"
const ROOTS_SLOW := "def factorizar(b, c):\n    for p in range(-abs(c), abs(c) + 1):\n        for q in range(-abs(c), abs(c) + 1):\n            if p + q == b and p * q == c:\n                return [p, q]\n"
const ROOTS_RANGE_OK := "def factorizar(b, c):\n    for p in range(-60, 61):\n        q = b - p\n        if p * q == c:\n            return [p, q]\n"
const ROOTS_RANGE_SLOW := "def factorizar(b, c):\n    for p in range(-60, 61):\n        for q in range(-60, 61):\n            if p + q == b and p * q == c:\n                return [p, q]\n"
const BALANCE_OK := "p = pesas.lista()\nn = len(p)\ntotal = sum(p)\nfor m in range(2 ** n):\n    izq = 0\n    for i in range(n):\n        if (m // (2 ** i)) % 2 == 1:\n            izq += p[i]\n    if izq * 2 == total:\n        for i in range(n):\n            if (m // (2 ** i)) % 2 == 1:\n                plato_izq.poner(i)\n            else:\n                plato_der.poner(i)\n        break\n"
const BALANCE_HALF := "p = pesas.lista()\nfor i in range(len(p)):\n    if i % 2 == 0:\n        plato_izq.poner(i)\n    else:\n        plato_der.poner(i)\n"
const NETWORK_BFS := "n = red.cantidad()\nprevio = []\nfor i in range(n):\n    previo.append(-1)\nvisto = [red.inicio]\ncola = [red.inicio]\nwhile len(cola) > 0:\n    actual = cola.pop(0)\n    for v in red.vecinos(actual):\n        if v not in visto:\n            visto.append(v)\n            previo[v] = actual\n            cola.append(v)\ncamino = []\nx = red.salida\nwhile x != -1:\n    camino.insert(0, x)\n    x = previo[x]\nfor k in range(1, len(camino)):\n    puentes.levantar(camino[k])\n"
const NETWORK_PATHS := "visto = [red.inicio]\ncaminos = [[red.inicio]]\nwhile len(caminos) > 0:\n    c = caminos.pop(0)\n    u = c[len(c) - 1]\n    if u == red.salida:\n        for k in range(1, len(c)):\n            puentes.levantar(c[k])\n        break\n    for v in red.vecinos(u):\n        if v not in visto:\n            visto.append(v)\n            caminos.append(c + [v])\n"
const NETWORK_GREEDY := "camino = [red.inicio]\nactual = red.inicio\nwhile actual != red.salida:\n    mejor = red.vecinos(actual)[0]\n    for v in red.vecinos(actual):\n        if red.distancia(v) < red.distancia(mejor):\n            mejor = v\n    actual = mejor\n    camino.append(actual)\nfor k in range(1, len(camino)):\n    puentes.levantar(camino[k])\n"
const NETWORK_WRONG := "puentes.levantar(red.mas_cercano(red.inicio))\n"
const NETWORK_DFS := "visto = [red.inicio]\npila = [[red.inicio]]\ncamino = []\nwhile len(pila) > 0:\n    c = pila.pop()\n    u = c[len(c) - 1]\n    if u == red.salida:\n        camino = c\n        break\n    for v in red.vecinos(u):\n        if v not in visto:\n            visto.append(v)\n            pila.append(c + [v])\nfor k in range(1, len(camino)):\n    puentes.levantar(camino[k])\n"
const BEACON_SIMPLE := "def dentro(x, y):\n    return 0 <= x < 8 and 0 <= y < 8\n"
const BALANCE_SIMPLE := "for i in range(pesas.cantidad()):\n    plato_liviano().poner(i)\n"
const NETWORK_SIMPLE := "actual = red.inicio\nwhile actual != red.salida:\n    actual = red.mas_cercano(actual)\n    puentes.levantar(actual)\n"
const CRIBA_OK := "while tolva.quedan() > 0:\n    n = tolva.soltar()\n    if n % 2 == 0:\n        caliz.recibir()\n    else:\n        crisol.desintegrar()\n"

var game: Game
var _failures := 0


func _init(context: Game) -> void:
	game = context


func run() -> void:
	ScriptLangTests.new().run_all(_check)
	_test_quality()
	_test_health_and_alarm_rules()
	await _test_movement()
	await _test_town_and_gate()
	await _test_corridor()
	_test_parity_filter()
	await _test_criba()
	_test_roots_trial()
	_test_roots_difficulty()
	await _test_presses()
	await _test_mural()
	_test_mine_rules()
	await _test_vortex()
	_test_balance_rules()
	await _test_balance()
	_test_network_rules()
	await _test_core()
	await _test_game_over_without_lives()
	print("SELFTEST ", "OK" if _failures == 0 else "FALLO (%d)" % _failures)
	game.get_tree().quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	print(("  ok   " if condition else "  FALLO ") + label)
	if not condition:
		_failures += 1


func _wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, true).timeout


## Espera en tiempo real (aunque el juego vaya en cámara lenta, como en el reto de teclas).
func _real_wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, false, true).timeout


## Pulsa o suelta una tecla como un evento real (cuenta igual que con el teclado).
func _key(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_all() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "run", "jump"]:
		_key(a, false)


## Camina hacia arriba hasta que pase algo (o se acabe el tiempo).
func _walk_up_until(done: Callable, limit: float, run := false) -> void:
	_key("move_up", true)
	if run:
		_key("run", true)
	var t := 0.0
	while not done.call() and t < limit:
		await _wait(0.1)
		t += 0.1
		game.dialog.close()
	_release_all()


func _test_quality() -> void:
	var presets: Dictionary = game.data.setting("quality_presets", {})
	var low := QualityProfile.create(0, presets)
	var high := QualityProfile.create(1, presets)
	_check(low is LowQuality and not low.shadows() and high is HighQuality and high.shadows(), "Strategy (efectos): bajos sin sombras, altos con sombras")
	_check(low.particle_scale() < high.particle_scale(), "Strategy (efectos): bajos dibujan menos partículas")


func _test_movement() -> void:
	game.machine.change("play", {"mode": "new"})
	game.dialog.close()
	await _wait(0.3)
	var p := game.player
	var start := p.global_position
	_key("move_up", true)
	await _wait(0.6)
	_check(p.state_name == "walk" and start.y - p.global_position.y > 25.0, "State (movimiento): con W camina")
	_key("run", true)
	await _wait(0.2)
	var before := p.global_position.y
	await _wait(0.4)
	_check(p.state_name == "run" and (before - p.global_position.y) / 0.4 > 100.0, "State (movimiento): con SHIFT corre más rápido")
	_check(p.stamina < p.stamina_max, "Correr gasta aliento")
	_key("jump", true)
	await _wait(0.1)
	_key("jump", false)
	_check(p.state_name == "jump" and p.airborne and p.hop_height > 0.0, "State (movimiento): ESPACIO salta")
	await _wait(0.5)
	_check(not p.airborne, "El salto aterriza")
	_release_all()
	await _wait(0.4)
	_check(p.state_name == "idle", "Sin teclas vuelve al reposo")


func _test_town_and_gate() -> void:
	game.machine.change("play", {"mode": "new"})
	game.dialog.close()
	var town := game.level as TownLevel
	# Hablar con Orun: pararse frente a él
	game.player.place(town.get_node("Actores/Orun").global_position + Vector2(0, 20), Vector2.UP)
	await _wait(0.2)
	var seen := game.player.focused_interactable()
	_check(seen != null and seen.prompt_key == "prompt_talk", "Pueblo: frente a Orun aparece «Hablar»")
	# El atril de la puerta
	game.player.place(town.gate.global_position + Vector2(0, 16), Vector2.UP)
	await _wait(0.2)
	seen = game.player.focused_interactable()
	_check(seen != null and seen.prompt_key == "prompt_machine", "Pueblo: frente al atril aparece «Programar la máquina»")
	seen.interact()
	await _wait(0.8)
	_check(game.machine.current is CodexState and game.codex.docked and game.rig.fixed_shot, "Códice: se abre al costado y la cámara encuadra la puerta")
	game.codex.editor.text = "puerta.abrir()\n"
	game.machine.current.run()
	var t := 0.0
	while not town.gate.is_solved and t < 5.0:
		await _wait(0.1)
		t += 0.1
	await _wait(0.8)
	game.dialog.close()
	_check(town.gate.gate_open and game.machine.current is PlayState, "Códice + Adapter: puerta.abrir() abre la puerta del templo")
	# Entrar caminando al templo
	game.player.place(town.get_node("Zonas/EntradaTemplo").global_position + Vector2(0, 80), Vector2.UP)
	await _walk_up_until(func(): return game.level is FilterLevel, 6.0)
	await _wait(0.8)
	_check(game.level is FilterLevel and game.timer.active, "Entrar al templo: se carga la Sala 1 y empiezan los 15 minutos")


func _test_corridor() -> void:
	var lvl := game.level as FilterLevel
	if lvl == null:
		_check(false, "Pasillo: no hay Sala 1")
		return
	game.dialog.close()
	var first: Pit = lvl.get_node("Fosos/Foso1")
	var pit := Rect2(first.global_position, first.size)
	var below := Vector2(pit.get_center().x, pit.end.y + 40)
	# Caminando, el salto no alcanza: cae y vuelve al punto seguro
	game.player.place(below, Vector2.UP)
	await _wait(0.2)
	var before_fall := game.timer.remaining
	_key("move_up", true)
	await _wait(0.35)
	_key("jump", true)
	await _wait(0.1)
	_key("jump", false)
	await _wait(1.6)
	_release_all()
	await _wait(0.4)
	_check(game.player.global_position.y > pit.position.y + 8, "Pasillo: caminando, el foso no se cruza (cae y vuelve)")
	# Lo que corrió el reloj mientras tanto (2,45 s de espera) más los 7 del castigo
	var lost := before_fall - game.timer.remaining - 2.45
	_check(lost > 6.5 and lost < 8.0, "Caída: el foso cuesta 7 segundos (perdió %.1f)" % lost)
	# Corriendo sí
	game.player.place(below + Vector2(0, 20), Vector2.UP)
	await _wait(0.2)
	_key("move_up", true)
	_key("run", true)
	await _wait(0.45)
	_key("jump", true)
	await _wait(0.1)
	_key("jump", false)
	await _wait(0.6)
	_release_all()
	await _wait(0.3)
	_check(game.player.global_position.y < pit.position.y + 8 and not game.player.falling, "Pasillo: corriendo y saltando se cruza el foso")
	# Hasta la sala
	var second: Pit = lvl.get_node("Fosos/Foso2")
	game.player.place(Vector2(pit.get_center().x, second.global_position.y - 24), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 4.0)
	_check(lvl._in_hall and lvl.objective_key == "objective_filter_machine", "Pasillo: se llega caminando a la sala de la Criba")


func _run_filter(rules: ParityFilter, code: String) -> Array:
	var sandbox := ScriptSandbox.new()
	var text := func(key, args): return game.data.message(key, args)
	var errors: Array = []
	for i in rules.rounds.size():
		rules.start_round(i)
		var result := sandbox.run(code, FilterAdapter.objects(rules, text))
		if not result.ok:
			errors.append(result.error_text())
			break
		rules.end_round()
		if rules.failed():
			break
	return errors


func _test_parity_filter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var config: Array = game.data.chamber_data(0).get("rounds", [])
	var rules := ParityFilter.new(config, rng)
	_check(rules.rounds.size() == 3, "Criba: hay 3 rondas")
	var errors := _run_filter(rules, CRIBA_OK)
	_check(errors.is_empty() and not rules.failed(), "Criba: el programa correcto pasa las 3 rondas")
	rules = ParityFilter.new(config, rng)
	_run_filter(rules, "while tolva.quedan() > 0:\n    tolva.soltar()\n    caliz.recibir()\n")
	_check(rules.fault == ParityFilter.Fault.WRONG_SIDE, "Criba: mandar todo al cáliz falla en la primera impar")
	rules = ParityFilter.new(config, rng)
	var hand := ""
	for v in rules.rounds[0]:
		hand += "tolva.soltar()\n" + ("caliz.recibir()\n" if v % 2 == 0 else "crisol.desintegrar()\n")
	errors = _run_filter(rules, hand)
	_check((rules.failed() or not errors.is_empty()) and rules.round_index >= 1, "Criba: copiar a mano la ronda 1 no sirve para las ocultas")
	rules = ParityFilter.new(config, rng)
	errors = _run_filter(rules, "caliz.recibir()\n")
	_check(errors.size() == 1 and "soltar" in errors[0], "Criba: recibir sin soltar da un error claro")


func _test_criba() -> void:
	var lvl := game.level as FilterLevel
	if lvl == null:
		return
	game.dialog.close()
	var machine := lvl.machine
	var first_round: Array = machine.rules.rounds[0].duplicate()
	game.open_codex(machine.session)
	await _wait(0.8)
	game.codex.editor.text = "while tolva.quedan() > 0:\n    tolva.soltar()\n    caliz.recibir()\n"
	Engine.time_scale = 4.0
	game.machine.current.run()
	await _wait(0.2)
	_check(not game.codex.visible, "Máquina: al ejecutar, el Códice se repliega para ver la máquina")
	var t := 0.0
	while not game.codex.visible and t < 40.0:
		await _wait(0.2)
		t += 0.2
	_check(not machine.is_solved and machine.rules.rounds[0] != first_round, "Máquina: con un programa equivocado se traba y trae esferas nuevas")
	Engine.time_scale = 1.0
	await _test_guardians(lvl)
	await _test_runic(lvl)
	await _test_formation_orbs_and_pause(lvl)
	game.player.place(Vector2(212, 262), Vector2.UP)
	game.open_codex(machine.session)
	await _wait(0.8)
	Engine.time_scale = 4.0
	game.codex.editor.text = CRIBA_OK
	game.machine.current.run()
	t = 0.0
	while not machine.is_solved and t < 60.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(1.0)
	game.dialog.close()
	_check(machine.is_solved and lvl.solved and game.machine.current is PlayState, "Máquina: con el programa correcto la Criba se resuelve y se abre la salida")
	game.player.place(Level.cell_center(Vector2i(15, 4)) + Vector2(8, 0), Vector2.UP)
	await _walk_up_until(func(): return game.level is RootsLevel, 4.0)
	await _wait(0.8)
	_check(game.level is RootsLevel and game.chamber_index == 1, "Sala 1: se cruza la salida caminando y se llega a la Sala 2 (Factory: RootsBuilder)")


## El error de la Criba despierta a las estatuas: se pelea con el garrote (teclas de verdad),
## los centinelas golpean, la máquina queda bloqueada hasta vencerlos, y si Tala se queda sin
## corazones vuelve a la entrada con un minuto menos y las estatuas en su lugar.
func _test_guardians(lvl: FilterLevel) -> void:
	var t := 0.0
	while not game.machine.current is PlayState and t < 3.0:
		await _wait(0.1)
		t += 0.1
	var awake := lvl.nodes_of(Guardian).filter(func(g): return g.is_active())
	_check(lvl.alarm.level == 1 and awake.size() == 2 and lvl.machine.locked, "Guardianes: el error sube la alarma a 1, despierta las 2 estatuas y bloquea la Criba")
	_check(game.machine.current is PlayState and not game.codex.visible, "Guardianes: el Códice se cierra para pelear")
	_check(lvl.machine_blocked(), "Guardianes: con guardianes despiertos la Criba no se puede usar")
	await _wait(1.8)
	# Quieta junto a un centinela: la golpea
	var g: Guardian = awake[0]
	var halves := game.health.halves
	t = 0.0
	while game.health.halves == halves and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_check(game.health.halves == halves - 1, "Guardianes: el golpe de un centinela quita medio corazón")
	# Tres golpes de garrote lo vencen
	for i in 6:
		if not g.is_active():
			break
		game.player.facing = (g.global_position - game.player.global_position).normalized()
		game.player.global_position = g.global_position - game.player.facing * 12.0
		await _wait(0.05)
		_key("attack", true)
		await _wait(0.06)
		_key("attack", false)
		await _wait(0.5)
	_check(not g.is_active(), "Garrote: con golpes de J el centinela se deshace")
	for other in awake:
		if other.is_active():
			other.take_hit(5, Vector2.UP)
	await _wait(0.4)
	_check(not lvl.alarm.fighting() and not lvl.machine.locked and not lvl.machine_blocked(), "Guardianes: vencidos todos, la Criba vuelve a aceptar código")
	# Sin corazones: un minuto menos, corazones llenos, entrada de la sala, estatuas de vuelta
	var before := game.timer.remaining
	game.health.damage(game.health.halves)
	await _wait(2.4)
	var lost := before - game.timer.remaining
	var dormant := lvl.nodes_of(Guardian).filter(func(x): return x.state_name == "dormant")
	_check(lost > 59.9 and lost < 63.5 and game.health.halves == game.health.max_halves, "Sin corazones: se pierde 1 minuto y vuelven los 5 corazones (perdió %.1f)" % lost)
	_check(game.player.global_position.distance_to(lvl.room_entrance()) < 4.0 and dormant.size() == 2 and lvl.alarm.level == 1, "Sin corazones: vuelve a la entrada de la sala, las estatuas a su pedestal y la alarma sigue en 1")


## La alarma 3 trae un guardián rúnico: se acerca, se carga, explota y pone el reto de teclas.
## Acertar las teclas no cuesta nada; equivocarse cuesta 2 corazones.
func _test_runic(lvl: FilterLevel) -> void:
	game.player.place(Vector2(248, 285), Vector2.UP)
	lvl.alarm.level = 2
	game.bus.publish(GameEvents.MACHINE_FAILED, {"message": ""})
	await _wait(1.0)
	var runics := lvl.nodes_of(RunicGuardian)
	_check(lvl.alarm.level == 3 and runics.size() == 1, "Rúnico: la alarma 3 trae un guardián rúnico")
	await _wait(2.5)
	for g in lvl.nodes_of(Guardian):
		if not g is RunicGuardian and g.can_be_hit():
			g.take_hit(9, Vector2.UP)
	var t := 0.0
	while not game.machine.current is KeyChallengeState and t < 10.0:
		await _wait(0.1)
		t += 0.1
	_check(game.machine.current is KeyChallengeState, "Rúnico: se acerca, se carga y al explotar con Tala dentro empieza el reto de teclas")
	if not game.machine.current is KeyChallengeState:
		return
	var halves := game.health.halves
	await _real_wait(1.1)
	_press_key("W")
	_press_key("Shift")
	await _real_wait(0.05)
	_check(not game.machine.current.finished, "Reto de teclas: las teclas que no son del reto (W, SHIFT) no cuentan como error")
	for k in game.machine.current.keys:
		_press_key(k)
		await _real_wait(0.05)
	await _real_wait(1.0)
	_check(game.machine.current is PlayState and game.health.halves == halves, "Reto de teclas: con las teclas en orden no se pierden corazones")
	var challenge := lvl.alarm.challenge(3)
	game.machine.change("keys", challenge)
	await _real_wait(1.1)
	var wrong: String = (challenge.pool as Array).filter(func(k): return k != challenge.keys[0])[0]
	_press_key(wrong)
	await _real_wait(1.0)
	_check(game.machine.current is PlayState and game.health.halves == halves - 4, "Reto de teclas: una tecla equivocada cuesta 2 corazones")
	await _wait(0.5)
	_check(not lvl.alarm.fighting() and is_equal_approx(Engine.time_scale, 1.0), "Rúnico: se destruye en su explosión y el tiempo vuelve a la normalidad")


## Caballeros en formación (rodean a Tala), el hechicero dispara de lejos, el garrote deshace
## los orbes y la pausa congela todo (guardianes y reloj).
func _test_formation_orbs_and_pause(lvl: FilterLevel) -> void:
	var p := Vector2(248, 285)
	game.player.place(p, Vector2.UP)
	game.player.invulnerable = 999.0
	var made: Array = []
	for spec in [[AlarmDirector.SENTINEL, Vector2(-44, -6)], [AlarmDirector.SENTINEL, Vector2(-44, 6)], [AlarmDirector.SORCERER, Vector2(0, -95)]]:
		var g: Guardian = spec[0].instantiate()
		g.setup(game.bus, lvl.kit, game.data.setting("combat", {}))
		lvl.actors.add_child(g)
		g.global_position = p + spec[1]
		made.append(g)
	await _wait(2.0)
	var a1: float = (made[0].global_position - p).angle()
	var a2: float = (made[1].global_position - p).angle()
	_check(absf(angle_difference(a1, a2)) > deg_to_rad(100.0), "Formación: dos caballeros que llegan por el mismo lado se reparten alrededor de Tala")
	var mage_d: float = made[2].global_position.distance_to(p)
	_check(mage_d > 45.0 and mage_d < 150.0, "Formación: el hechicero se mantiene a distancia (%.0f px)" % mage_d)
	var fired := [false]
	var on_fire := func(_x): fired[0] = true
	game.bus.subscribe(GameEvents.ORB_FIRED, on_fire)
	var t := 0.0
	while not fired[0] and t < 4.0:
		await _wait(0.1)
		t += 0.1
	game.bus.unsubscribe(GameEvents.ORB_FIRED, on_fire)
	_check(fired[0], "Hechicero: lanza orbes desde lejos")
	# Pausa: nada se mueve y el reloj no corre
	game.machine.change("pause")
	await _wait(0.1)
	var before_time := game.timer.remaining
	var before_pos: Vector2 = made[2].global_position
	await _wait(1.0)
	_check(is_equal_approx(game.timer.remaining, before_time) and made[2].global_position == before_pos, "Pausa: el reloj y los guardianes se detienen")
	game.machine.change("play")
	for g in made:
		g.queue_free()
	for orb in game.get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	await _wait(0.2)
	# Un orbe que llega quita medio corazón; con un garrotazo a tiempo se deshace
	game.player.invulnerable = 0.0
	var halves := game.health.halves
	var orb: RuneOrb = OrbShot.ORB.instantiate()
	lvl.actors.add_child(orb)
	orb.global_position = p + Vector2(40, -4)
	orb.velocity = Vector2.LEFT * orb.speed
	await _wait(0.8)
	_check(game.health.halves == halves - 1, "Hechicero: su orbe quita medio corazón")
	await _wait(1.2)
	var orb2: RuneOrb = OrbShot.ORB.instantiate()
	lvl.actors.add_child(orb2)
	orb2.global_position = p + Vector2(0, -40)
	orb2.velocity = Vector2.DOWN * orb2.speed
	game.player.facing = Vector2.UP
	halves = game.health.halves
	await _wait(0.2)
	_key("attack", true)
	await _wait(0.06)
	_key("attack", false)
	await _wait(0.6)
	_check(not is_instance_valid(orb2) and game.health.halves == halves, "Garrote: un golpe a tiempo deshace el orbe")


func _press_key(letter: String) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = OS.find_keycode_from_string(letter)
	event.keycode = event.physical_keycode
	event.pressed = true
	Input.parse_input_event(event)
	var up := event.duplicate()
	up.pressed = false
	Input.parse_input_event(up)


## Reglas puras: corazones, castigo de tiempo y tamaño de las olas.
func _test_health_and_alarm_rules() -> void:
	var bus := EventBus.new()
	var died := [false]
	bus.subscribe(GameEvents.PLAYER_DIED, func(_p): died[0] = true)
	var health := PlayerHealth.new(bus, 5)
	health.damage(1)
	_check(health.halves == 9 and not died[0], "Corazones: un golpe quita medio corazón (quedan 4 y medio)")
	health.heal(2)
	_check(health.halves == 10, "Corazones: curar no pasa del máximo")
	_check(health.damage(10) and died[0], "Corazones: sin mitades, Tala cae vencida")
	var alarm := AlarmDirector.new()
	alarm._settings = game.data.setting("combat", {})
	_check(alarm.wave_size(1) == 2 and alarm.wave_size(2) == 3 and alarm.wave_size(4) == 4 and alarm.wave_size(20) == 6, "Alarma: 2, 3, ... hasta 6 guardianes como máximo")
	_check(is_equal_approx(alarm.wave_speed(1), 1.0) and alarm.wave_speed(30) <= 1.6, "Alarma: con más errores son más rápidos, con tope")
	_check(alarm.runic_count(2) == 0 and alarm.runic_count(3) == 1 and alarm.runic_count(6) == 2, "Alarma: los rúnicos aparecen desde la alarma 3")
	var easy := alarm.challenge(3)
	var hard := alarm.challenge(12)
	_check(easy.keys.size() == 4 and is_equal_approx(easy.seconds, 5.0) and hard.keys.size() == 7 and is_equal_approx(hard.seconds, 8.0), "Reto de teclas: de 4 teclas en 5 s hasta 7 en 8 s")
	var repeats := false
	for i in range(1, hard.keys.size()):
		repeats = repeats or hard.keys[i] == hard.keys[i - 1]
	_check(not repeats and hard.keys.all(func(k): return k in ["A", "S", "D", "F", "J", "K", "L"]), "Reto de teclas: teclas A S D F J K L, sin repetir dos seguidas")
	alarm.free()


## Si se acaban los corazones con un minuto o menos en el reloj, se acaba el juego.
func _test_game_over_without_lives() -> void:
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	game.load_chamber(0)
	game.timer.start()
	game.timer.remaining = 50.0
	game.health.damage(game.health.halves)
	await _wait(2.2)
	_check(game.machine.current is EndState and game.machine.current._key == "ending_no_lives", "Sin corazones y con menos de 1 minuto: fin del juego")


## Vence de un golpe a todos los guardianes que queden (después de que terminen de caer).
func _clear_guardians(lvl: ChamberLevel) -> void:
	var t := 0.0
	while lvl.alarm._pending > 0 and t < 6.0:
		await _wait(0.2)
		t += 0.2
	await _wait(0.6)
	for g in lvl.nodes_of(Guardian):
		if g.is_active():
			if g.can_be_hit():
				g.take_hit(99, Vector2.UP)
			else:
				g.blow_up()
	t = 0.0
	while lvl.alarm.fighting() and t < 4.0:
		await _wait(0.2)
		t += 0.2
	await _wait(0.3)


## La dificultad nueva del Mural (12 000 pasos y raíces entre −60 y 60): un bucle sobre el
## rango pasa siempre; dos bucles anidados sobre el rango se pasan de pasos.
func _test_roots_difficulty() -> void:
	var limit := int(game.data.chamber_data(1).get("max_steps", 0))
	var sandbox := ScriptSandbox.new()
	var rng := RandomNumberGenerator.new()
	var worst := {"ok": 0, "slow": 0, "abs": 0}
	var all_right := true
	for code_name in ["ok", "slow", "abs"]:
		var code: String = {"ok": ROOTS_RANGE_OK, "slow": ROOTS_RANGE_SLOW, "abs": ROOTS_OK}[code_name]
		var program := sandbox.run(code, {}, 10000000)
		for kind in ["square", "mixed", "zero", "both_positive", "near"]:
			for i in 30:
				rng.seed = i * 13 + 7
				var c := RootsTrial.make_case(kind, rng)
				var answer := sandbox.call_function(program, "factorizar", [c.b, c.c])
				worst[code_name] = maxi(worst[code_name], program.context.steps)
				if code_name != "slow":
					all_right = all_right and answer[0] and RootsTrial.judge(c, answer[1]) == RootsTrial.Verdict.RIGHT
	_check(limit == 12000, "Mural: el límite es de 12 000 pasos")
	_check(all_right and worst.ok < limit and worst.abs < limit, "Mural: un bucle de −60 a 60 (peor caso %d pasos) y el de abs(c) (%d) caben" % [worst.ok, worst.abs])
	_check(worst.slow > limit, "Mural: dos bucles anidados de −60 a 60 se pasan (peor caso %d pasos)" % worst.slow)


## Reglas del buscaminas: la primera baldosa nunca es mina, todo tablero se resuelve solo con
## lógica (sin adivinar), y tras una bomba el patrón nuevo es distinto aunque se empiece igual.
func _test_mine_rules() -> void:
	var board := MineBoard.new()
	board.power_on()
	var first_safe := true
	var solvable := true
	var counts_ok := true
	var all_different := true
	var generator := MinefieldGenerator.new("king")
	var field := {}
	for c in board.cells():
		field[c] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 120:
		var first := Vector2i(rng.randi_range(0, 7), rng.randi_range(0, 7))
		var before: Dictionary = board.mines.duplicate()
		board.reset()
		var result := board.reveal(first)
		first_safe = first_safe and result == MineBoard.Result.SAFE and board.revealed.get(first, -1) == 0
		solvable = solvable and generator.is_solvable(field, board.mines, first)
		counts_ok = counts_ok and board.mines.size() == 10
		if i > 0:
			all_different = all_different and board.mines != before
	_check(first_safe, "Buscaminas: la primera baldosa nunca es mina y abre una zona (120 tableros)")
	_check(solvable and counts_ok, "Buscaminas: 120 tableros de 8×8 con 10 minas, todos se resuelven solo con lógica")
	_check(all_different, "Buscaminas: después de cada bomba el patrón nuevo es distinto al anterior")
	# Banderas: una baldosa con bandera no se destapa
	var flagged := Vector2i(-1, -1)
	for c in board.cells():
		if not board.revealed.has(c):
			flagged = c
			break
	board.toggle_flag(flagged)
	_check(board.reveal(flagged) == MineBoard.Result.NOTHING, "Buscaminas: una baldosa con bandera no se puede destapar")
	board.free()


## La Sala 3 de verdad: el Faro con un programa mal y uno bien, el tablero con E y Q, una bomba
## (−2 corazones y tablero nuevo) y el tablero limpio que abre la salida. Sin guardianes.
func _test_vortex() -> void:
	var lvl := game.level as VortexLevel
	if lvl == null:
		return
	game.dialog.close()
	_check(not lvl.alarm.enabled(), "Sala 3: no tiene guardianes")
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	game.dialog.close()
	game.player.place(lvl.machine.global_position + Vector2(0, 30), Vector2.UP)
	game.open_codex(lvl.machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = "def dentro(x, y):\n    return x < 8 and y < 8\n"
	game.machine.current.run()
	await _wait(0.3)
	var t := 0.0
	while not game.codex.visible and t < 20.0:
		await _wait(0.2)
		t += 0.2
	_check(not lvl.machine.is_solved and not lvl.board.powered and game.machine.current is CodexState, "Faro: si dentro() acepta casillas negativas, no enciende (y no despierta guardianes)")
	game.codex.editor.text = BEACON_SIMPLE
	game.machine.current.run()
	t = 0.0
	while not lvl.board.powered and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(0.8)
	game.dialog.close()
	_check(lvl.board.powered and game.machine.current is PlayState, "Faro: con dentro(x, y) bien escrito (una línea), el tablero se enciende")
	# E destapa la baldosa que pisa Tala; Q le pone bandera
	var start := Vector2i(3, 6)
	game.player.place(lvl.board.cell_center(start), Vector2.UP)
	await _wait(0.2)
	_key("interact", true)
	await _wait(0.05)
	_key("interact", false)
	await _wait(0.2)
	_check(lvl.board.revealed.has(start) and lvl.board.mines.size() == 10, "Tablero: E destapa la baldosa que se pisa (y reparte las minas)")
	var mine: Vector2i = lvl.board.mines.keys()[0]
	game.player.place(lvl.board.cell_center(mine), Vector2.UP)
	await _wait(0.2)
	_key("flag", true)
	await _wait(0.05)
	_key("flag", false)
	await _wait(0.2)
	_check(lvl.board.flags.has(mine), "Tablero: Q pone una bandera")
	_key("flag", true)
	await _wait(0.05)
	_key("flag", false)
	await _wait(0.1)
	# Una bomba: −2 corazones y tablero nuevo
	game.health.refill()
	var halves := game.health.halves
	var old_mines: Dictionary = lvl.board.mines.duplicate()
	_key("interact", true)
	await _wait(0.05)
	_key("interact", false)
	await _wait(2.6)
	_check(game.health.halves == halves - 4 and lvl.board.revealed.is_empty() and lvl.board.mines.is_empty(), "Tablero: una mina quita 2 corazones y el tablero vuelve a empezar")
	_check(game.player.global_position.distance_to(lvl.room_entrance()) < 4.0, "Tablero: después de la bomba, Tala vuelve a la entrada")
	lvl.board.reveal(start)
	_check(lvl.board.mines != old_mines, "Tablero: empezando por la misma baldosa, las minas quedan en otro lugar")
	# Destapar todo lo que no es mina limpia el tablero y abre la salida
	for c in lvl.board.cells():
		if not lvl.board.mines.has(c):
			lvl.board.reveal(c)
	await _wait(0.6)
	game.dialog.close()
	_check(lvl.solved, "Tablero: destapar todas las baldosas sin mina abre la salida")
	game.player.place(Level.cell_center(Vector2i(15, 4)) + Vector2(8, 0), Vector2.UP)
	await _walk_up_until(func(): return game.level is BalanceLevel, 4.0)
	await _wait(0.8)
	_check(game.level is BalanceLevel and game.chamber_index == 3, "Sala 3: se cruza la salida y se llega a la Sala 4 (Factory: BalanceBuilder)")


## Reglas de la Balanza: cada juego de pesas se puede nivelar, y los errores se explican.
func _test_balance_rules() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var always := true
	for i in 300:
		always = always and BalanceRules.has_solution(BalanceRules.make_set(7 + i % 2, rng))
	_check(always, "Balanza: 300 juegos de pesas, todos se pueden nivelar")
	var rules := BalanceRules.new([4, 6, 10])
	_check(rules.put(9, BalanceRules.LEFT) == "bad_index" and rules.put(0, BalanceRules.LEFT) == "" and rules.put(0, BalanceRules.RIGHT) == "twice", "Balanza: una posición que no existe o una pesa repetida dan error")
	_check(rules.verdict() == BalanceRules.Verdict.LEFT_OUT, "Balanza: si quedan pesas en el estante, no vale")
	rules.put(1, BalanceRules.LEFT)
	rules.put(2, BalanceRules.RIGHT)
	_check(rules.verdict() == BalanceRules.Verdict.LEVEL, "Balanza: 4 + 6 = 10 queda nivelada")
	var sandbox := ScriptSandbox.new()
	var ok := true
	for i in 40:
		var r := BalanceRules.new(BalanceRules.make_set(8, rng))
		var result := sandbox.run(BALANCE_OK, BalanceAdapter.objects(r, func(k, a): return k), 200000)
		ok = ok and result.ok and r.verdict() == BalanceRules.Verdict.LEVEL
	_check(ok, "Balanza: probar todos los repartos (2 ** n) siempre la nivela")
	var easy := true
	for i in 100:
		var r := BalanceRules.new(BalanceRules.make_set(7 + i % 2, rng, 2, 19, true))
		var result := sandbox.run(BALANCE_SIMPLE, BalanceAdapter.objects(r, func(k, a): return k), 200000)
		easy = easy and result.ok and r.verdict() == BalanceRules.Verdict.LEVEL
	_check(easy, "Balanza (fácil): plato_liviano().poner(i) en un for siempre la nivela (100 juegos)")


## La Sala 4 de verdad: un reparto a medias hace caer las pesas (y despierta guardianes); el
## programa que busca el reparto la nivela y abre la reja del este.
func _test_balance() -> void:
	var lvl := game.level as BalanceLevel
	if lvl == null:
		return
	game.dialog.close()
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	game.dialog.close()
	var machine := lvl.machine
	var before: Array = machine.sets.duplicate(true)
	game.player.place(machine.global_position + Vector2(0, 40), Vector2.UP)
	game.open_codex(machine.session)
	await _wait(0.6)
	game.codex.editor.text = BALANCE_HALF
	Engine.time_scale = 4.0
	game.machine.current.run()
	await _wait(0.3)
	var t := 0.0
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	_check(not machine.is_solved and machine.sets != before and lvl.alarm.level == 1, "Balanza: un reparto a medias no la nivela, llegan pesas nuevas y despiertan los guardianes")
	await _clear_guardians(lvl)
	game.player.place(machine.global_position + Vector2(0, 40), Vector2.UP)
	game.open_codex(machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = BALANCE_SIMPLE
	game.machine.current.run()
	t = 0.0
	while not machine.is_solved and t < 40.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(1.0)
	game.dialog.close()
	_check(machine.is_solved and lvl.solved, "Balanza: poniendo cada pesa en el plato más liviano se nivelan los dos juegos")
	game.player.place(Level.cell_center(Vector2i(27, 12)), Vector2.RIGHT)
	_key("move_right", true)
	t = 0.0
	while not game.level is CoreLevel and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_release_all()
	await _wait(0.8)
	_check(game.level is CoreLevel and game.chamber_index == 4, "Sala 4: se cruza la reja del este y se llega a la Sala 5 (Factory: CoreBuilder)")


## Reglas de la red: en la versión fácil (la del juego) sirve cualquier camino, en anchura o en
## profundidad; con shortest, una búsqueda en profundidad da un camino más largo y no alcanza.
func _test_network_rules() -> void:
	var pos: Array = []
	var net_node := (load("res://scenes/niveles/sala_5_singularidad.tscn") as PackedScene).instantiate()
	pos = (net_node.get_node("Red") as SkyNetwork).positions()
	net_node.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var sandbox := ScriptSandbox.new()
	var all_ok := true
	var dfs_fails := true
	var lengths_ok := true
	for i in 40:
		var net := NetworkRules.make(pos, 0, pos.size() - 1, rng, 100.0, 0.6, 3, 5)
		var length := net.shortest_path().size() - 1
		lengths_ok = lengths_ok and length >= 3 and length <= 5
		for code in [NETWORK_SIMPLE, NETWORK_GREEDY, NETWORK_BFS, NETWORK_PATHS, NETWORK_DFS]:
			var a := NetworkRules.new(net.positions, net.edges, net.start, net.goal)
			var r := sandbox.run(code, NetworkAdapter.objects(a, func(k, x): return k), 200000)
			all_ok = all_ok and r.ok and a.check(a.path) == ""
		var hard := NetworkRules.make(pos, 0, pos.size() - 1, rng, 100.0, 0.6, 4, 7, true)
		var b := NetworkRules.new(hard.positions, hard.edges, hard.start, hard.goal)
		b.require_shortest = true
		var r2 := sandbox.run(NETWORK_DFS, NetworkAdapter.objects(b, func(k, x): return k), 200000)
		dfs_fails = dfs_fails and (not r2.ok or b.check(b.path) != "")
	_check(lengths_ok, "Red: el camino más corto tiene entre 3 y 5 puentes")
	_check(all_ok, "Red: con red.distancia (la fácil), en anchura o en profundidad, cualquier camino sirve (40 redes)")
	_check(dfs_fails, "Red (modo difícil): una búsqueda en profundidad no alcanza (40 redes)")


## La Sala 5 de verdad: la Consola rechaza un camino que no llega (y despierta guardianes),
## acepta la búsqueda con lista de caminos, el atril levanta los puentes y quedan para siempre,
## caer al abismo cuesta 7 s, y tomar el núcleo gana el juego.
func _test_core() -> void:
	var lvl := game.level as CoreLevel
	if lvl == null:
		return
	game.dialog.close()
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	game.dialog.close()
	var machine := lvl.machine
	game.player.place(machine.global_position + Vector2(0, 34), Vector2.UP)
	game.open_codex(machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = NETWORK_WRONG
	game.machine.current.run()
	await _wait(0.3)
	var t := 0.0
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	_check(not machine.is_solved and lvl.alarm.level == 1, "Consola: un camino que no llega a la salida no sirve (y despiertan los guardianes)")
	await _clear_guardians(lvl)
	game.player.place(machine.global_position + Vector2(0, 34), Vector2.UP)
	game.open_codex(machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = NETWORK_SIMPLE
	game.machine.current.run()
	t = 0.0
	while not machine.is_solved and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(1.0)
	game.dialog.close()
	_check(machine.is_solved and machine.real.check(machine.path) == "", "Consola: saltar con red.mas_cercano y levantar cada puente sirve y la red queda lista")
	# Caer al abismo
	var before := game.timer.remaining
	game.player.place(lvl.network.to_global(lvl.network.void_rect.get_center() + Vector2(0, 30)), Vector2.UP)
	await _wait(1.6)
	var lost := before - game.timer.remaining - 1.6
	_check(lost > 6.5 and lost < 8.0 and game.player.global_position.distance_to(lvl.room_entrance()) < 4.0, "Abismo: fuera de las plataformas Tala cae (−7 s) y vuelve a la entrada")
	# El atril levanta los puentes; por los puentes se camina
	lvl._use_console()
	_check(lvl.network.bridges_up(), "Atril: con la red lista, levanta los puentes")
	await _wait(1.0)
	var a := lvl.network.platform_global(machine.path[0])
	var b := lvl.network.platform_global(machine.path[1])
	_check(lvl.network.is_ground(a.lerp(b, 0.5)), "Puentes: sobre un puente levantado no se cae")
	await _wait(10.0)
	_check(lvl.network.bridges_up() and lvl.network.is_ground(a.lerp(b, 0.5)), "Puentes: siguen ahí 10 s después (quedan para siempre)")
	# El núcleo: tomarlo lleva a la Sala 6
	for id in machine.path:
		game.player.global_position = lvl.network.platform_global(id) + Vector2(0, 2)
		await _wait(0.15)
	t = 0.0
	while not game.level is ThroneLevel and t < 6.0:
		await _wait(0.2)
		t += 0.2
	_check(game.level is ThroneLevel and game.chamber_index == 5, "Núcleo: al tomarlo se llega a la Sala 6, el Trono del Cero (Factory: ThroneBuilder)")
	await _test_boss(game.level as ThroneLevel)


## La Sala 6: al entrar despierta el jefe (y cura 2 corazones); el pisotón quita un corazón,
## la ráfaga lanza orbes, al cambiar de fase se cubre con un escudo y llama guardianes, y
## vencerlo gana el juego.
func _test_boss(lvl: ThroneLevel) -> void:
	if lvl == null:
		return
	var boss := lvl.boss
	game.dialog.close()
	_check(not boss.is_awake(), "Jefe: duerme mientras Tala va por el pasillo")
	game.health.halves = 4
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	_check(boss.is_awake() and game.health.halves == 8, "Jefe: al entrar a la sala despierta y Tala recupera 2 corazones (la única curación)")
	var t := 0.0
	while boss.state == "appear" and t < 4.0:
		await _wait(0.2)
		t += 0.2
	game.dialog.close()
	game.health.refill()
	game.player.invulnerable = 0.0
	game.player.place(boss.global_position + Vector2(0, 30), Vector2.UP)
	boss.change("slam")
	var halves := game.health.halves
	await _wait(1.6)
	_check(game.health.halves == halves - 2 and boss.state == "tired", "Jefe: el pisotón quita un corazón y después queda cansado")
	game.player.place(boss.global_position + Vector2(0, 90), Vector2.UP)
	await _wait(1.2)
	var orbs := game.get_tree().get_nodes_in_group("orbs").size()
	boss.change("volley")
	await _wait(0.85)
	_check(game.get_tree().get_nodes_in_group("orbs").size() >= orbs + 3, "Jefe: la ráfaga lanza un abanico de orbes")
	game.health.refill()
	for i in boss.phase_hp():
		boss.take_hit(1, Vector2.UP)
	_check(boss.state == "shield" and not boss.can_be_hit(), "Jefe: al perder un tercio de la vida se cubre con un escudo")
	await _wait(1.5)
	_check(lvl.alarm.fighting(), "Jefe: el escudo llama una ola de guardianes")
	await _clear_guardians(lvl)
	await _wait(0.5)
	_check(boss.can_be_hit(), "Jefe: vencida la ola, el escudo cae")
	game.health.refill()
	while boss.hp > 0:
		if boss.can_be_hit():
			boss.take_hit(1, Vector2.UP)
		else:
			await _clear_guardians(lvl)
			await _wait(1.2)
	t = 0.0
	while boss.state != "hidden" and t < 5.0:
		await _wait(0.2)
		t += 0.2
	t = 0.0
	while not game.machine.current is EndState and t < 6.0:
		await _wait(0.2)
		t += 0.2
	_check(game.machine.current is EndState and game.machine.current._won, "Jefe: al vencerlo se gana el juego")


## Reglas puras del Mural de las Raíces.
func _test_roots_trial() -> void:
	_check(RootsTrial.polynomial(-20, 100) == "x² − 20x + 100" and RootsTrial.polynomial(1, 0) == "x² + x" and RootsTrial.polynomial(0, -9) == "x² − 9", "Raíces: el polinomio se escribe con sus signos")
	_check(RootsTrial.factors(-10, -10) == "(x − 10)(x − 10)" and RootsTrial.factors(0, 3) == "(x)(x + 3)", "Raíces: la factorización se escribe bien")
	var case := {"b": -20, "c": 100}
	_check(RootsTrial.judge(case, [-10, -10]) == RootsTrial.Verdict.RIGHT, "Raíces: [-10, -10] es correcto para x² − 20x + 100")
	_check(RootsTrial.judge(case, [10, 10]) == RootsTrial.Verdict.WRONG, "Raíces: [10, 10] está mal (daría x² + 20x + 100)")
	_check(RootsTrial.judge(case, "(x-10)(x-10)") == RootsTrial.Verdict.BAD_SHAPE and RootsTrial.judge(case, null) == RootsTrial.Verdict.BAD_SHAPE, "Raíces: un texto o nada no sirve; debe ser una lista de dos enteros")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var trial := RootsTrial.new(game.data.chamber_data(1).get("cases", []), rng)
	var kinds_ok: bool = trial.cases.size() == 5 and trial.cases[2].c == 0 and trial.cases[1].c < 0 and absi(trial.cases[4].b) == 1
	_check(kinds_ok, "Raíces: cinco casos (cuadrado perfecto, c negativo, c = 0, grandes, casi opuestos)")


## Las prensas del pasillo de la Sala 2.
func _test_presses() -> void:
	var lvl := game.level as RootsLevel
	if lvl == null:
		_check(false, "Prensas: no hay Sala 2")
		return
	game.dialog.close()
	var press: Crusher = null
	for n in lvl.fx.get_children():
		if n is Crusher:
			press = n
			break
	# Quedarse quieta en medio de la prensa: la atrapa
	var resets := [0]
	press.crushed.connect(func(): resets[0] += 1, CONNECT_ONE_SHOT)
	game.player.place(press.global_position + Vector2(-30, 3), Vector2.UP)
	var t := 0.0
	while resets[0] == 0 and t < press.period * 1.5:
		await _wait(0.05)
		t += 0.05
	_check(resets[0] == 1, "Prensas: si Tala se queda dentro, la prensa la atrapa")
	await _wait(0.3)
	# Con el ritmo justo se cruza: esperar a que se abra y correr
	game.player.place(press.global_position + Vector2(0, 26), Vector2.UP)
	while press.extension() <= 0.0:
		await _wait(0.02)
	while press.extension() > 0.0:
		await _wait(0.02)
	var start_resets: int = resets[0]
	_key("move_up", true)
	_key("run", true)
	await _wait(0.6)
	_release_all()
	var past: bool = game.player.global_position.y < press.global_position.y - 10
	_check(past and int(resets[0]) == start_resets, "Prensas: esperando el ritmo y corriendo, se cruza")
	# Llegar a la sala
	game.player.place(Level.cell_center(Vector2i(15, 24)), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 4.0)
	_check(lvl._in_hall, "Prensas: se llega caminando a la sala del Mural")


## El Mural de verdad: programa lento, respuesta fija (cada error despierta guardianes que hay
## que vencer), programa correcto y salida.
func _test_mural() -> void:
	var lvl := game.level as RootsLevel
	if lvl == null:
		return
	game.dialog.close()
	var machine := lvl.machine
	var cases_before: Array = machine.trial.cases.duplicate(true)
	game.open_codex(machine.session)
	await _wait(0.6)
	game.codex.editor.text = ROOTS_SLOW
	Engine.time_scale = 4.0
	game.machine.current.run()
	await _wait(0.2)
	var t := 0.0
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	_check(not machine.is_solved and machine.trial.cases != cases_before, "Mural: probar todas las parejas se pasa de pasos y el Mural cambia sus polinomios")
	_check(lvl.alarm.level == 1 and lvl.machine.locked, "Sala 2: el error del Mural despierta a sus guardianes y lo bloquea")
	await _clear_guardians(lvl)
	game.open_codex(machine.session)
	await _wait(0.6)
	game.codex.editor.text = "def factorizar(b, c):\n    return [-10, -10]\n"
	game.machine.current.run()
	t = 0.0
	await _wait(0.2)
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	_check(not machine.is_solved and lvl.alarm.level == 2, "Mural: devolver siempre la misma respuesta no sirve (y la alarma sube a 2)")
	await _clear_guardians(lvl)
	game.open_codex(machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = ROOTS_RANGE_OK
	game.machine.current.run()
	t = 0.0
	while not machine.is_solved and t < 40.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(1.0)
	game.dialog.close()
	_check(machine.is_solved and lvl.solved, "Mural: un solo bucle de −60 a 60 (q = b − p) resuelve los cinco polinomios")
	game.player.place(Level.cell_center(Vector2i(27, 12)), Vector2.RIGHT)
	_key("move_right", true)
	t = 0.0
	while not game.level is VortexLevel and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_release_all()
	await _wait(0.8)
	_check(game.level is VortexLevel and game.chamber_index == 2, "Sala 2: se cruza la reja del este y se llega a la Sala 3 (Factory: VortexBuilder)")
