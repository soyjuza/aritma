## Pruebas que juegan de verdad con eventos de teclado:
## Godot --headless --path . -- --selftest
class_name SelfTest
extends RefCounted

const ROOTS_OK := "def despejar(a, b, c):\n    return (c - b) / a\n"
const CRIBA_OK := "while tolva.quedan() > 0:\n    n = tolva.soltar()\n    if n % 2 == 0:\n        caliz.recibir()\n    else:\n        crisol.desintegrar()\n"

var game: Game
var _failures := 0


func _init(context: Game) -> void:
	game = context


func run() -> void:
	game.fixed_challenges = true
	game.data.roll_challenges(1, true)
	ScriptLangTests.new().run_all(_check)
	_test_quality()
	_test_challenge_variants()
	_test_health_and_alarm_rules()
	await _test_movement()
	await _test_town_and_gate()
	await _test_corridor()
	_test_parity_filter()
	await _test_criba()
	_test_roots_trial()
	await _test_presses()
	await _test_mural()
	_test_mine_rules()
	await _test_vortex()
	_test_figure_rules()
	await _test_figures()
	_test_path_rules()
	_test_boss_quiz()
	await _test_core()
	await _test_save_and_load()
	await _test_game_over_without_lives()
	print("SELFTEST ", "OK" if _failures == 0 else "FALLO (%d)" % _failures)
	game.get_tree().quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	print(("  ok   " if condition else "  FALLO ") + label)
	if not condition:
		_failures += 1


func _wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, true).timeout


## Espera en tiempo real.
func _real_wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, false, true).timeout


## Pulsa o suelta una tecla.
func _key(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _release_all() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right", "run", "jump"]:
		_key(a, false)


## Camina hacia arriba hasta que pase algo.
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
	# Hablar con Orun
	game.player.place(town.get_node("Actores/Orun").global_position + Vector2(0, 20), Vector2.UP)
	await _wait(0.2)
	var seen := game.player.focused_interactable()
	_check(seen != null and seen.prompt_key == "prompt_talk", "Pueblo: frente a Orun aparece «Hablar»")
	# Atril de la puerta
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
	# Entrar al templo
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
	# Caminando no alcanza el salto
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


## Banco de variantes: cada partida sortea el ejercicio de cada sala.
func _test_challenge_variants() -> void:
	var seen := {}
	for i in 60:
		var picks := ChallengeDeck.roll(game.data.chambers, i + 1)
		for room in [0, 1, 3]:
			seen["%d:%s" % [room, picks[room].get("id", "")]] = true
	_check(seen.size() == 9, "Variantes: en 60 partidas salen las 3 variantes de la Criba, del Mural y de la Mesa")
	var a := ChallengeDeck.roll(game.data.chambers, 777)
	var b := ChallengeDeck.roll(game.data.chambers, 777)
	_check(JSON.stringify(a) == JSON.stringify(b), "Variantes: la misma semilla da los mismos ejercicios (el espectador ve lo mismo)")
	_check(int(a[0].get("seed", 0)) != 0 and a[0].get("seed") != a[1].get("seed"), "Variantes: cada sala tiene su propia semilla")
	var rng := RandomNumberGenerator.new()
	var sorts_ok := true
	var old_fails := true
	for i in 40:
		var room: Dictionary = ChallengeDeck.roll(game.data.chambers, i + 1)[0]
		var rule: Dictionary = room.get("rule", {})
		var test := "n > %d" % int(rule.get("t", 0)) if rule.get("kind") == "greater" else "n %% %d == 0" % int(rule.get("k", 2))
		var code := CRIBA_OK.replace("n % 2 == 0", test)
		rng.seed = i
		var rules := ParityFilter.new(room.get("rounds", []), rng, rule)
		sorts_ok = sorts_ok and _run_filter(rules, code).is_empty() and not rules.failed()
		if test != "n % 2 == 0":
			rules = ParityFilter.new(room.get("rounds", []), rng, rule)
			_run_filter(rules, CRIBA_OK)
			old_fails = old_fails and rules.failed()
	_check(sorts_ok, "Criba: en cada variante (pares, múltiplos de k, mayores que t) el programa correcto pasa")
	_check(old_fails, "Criba: el programa de pares no sirve para las otras variantes")
	var formulas := {"lineal": "(c - b) / a", "fraccion": "(c - b) * a", "parentesis": "c / a - b"}
	var sandbox := ScriptSandbox.new()
	var forms_ok := true
	var copy_fails := true
	for form in formulas:
		var program := sandbox.run("def despejar(a, b, c):\n    return %s\n" % formulas[form], {}, 2000)
		var old := sandbox.run(ROOTS_OK, {}, 2000)
		var old_right := 0
		for i in 60:
			var c := RootsTrial.make_case(["plus", "minus", "negative"][i % 3], rng, form)
			var answer := sandbox.call_function(program, "despejar", [c.a, c.b, c.c])
			forms_ok = forms_ok and answer[0] and RootsTrial.judge(c, answer[1]) == RootsTrial.Verdict.RIGHT
			var copied := sandbox.call_function(old, "despejar", [c.a, c.b, c.c])
			old_right += 1 if copied[0] and RootsTrial.judge(c, copied[1]) == RootsTrial.Verdict.RIGHT else 0
		if form != "lineal":
			copy_fails = copy_fails and old_right < 30
	_check(forms_ok, "Mural: cada forma (ax + b = c, x/a + b = c, a(x + b) = c) se despeja con su fórmula")
	_check(copy_fails, "Mural: la fórmula de ax + b = c no sirve para las otras formas")
	_check(RootsTrial.equation(4, 3, 5, "fraccion") == "x/4 + 3 = 5" and RootsTrial.equation(3, -2, 15, "parentesis") == "3(x − 2) = 15", "Mural: las otras formas se escriben bien")
	var figures_ok := true
	for v in game.data.chambers[3].get("variants", []):
		for p in v.get("puzzles", game.data.chambers[3].get("puzzles", [])):
			for i in 10:
				rng.seed = i
				figures_ok = figures_ok and _solve_figure(FigurePuzzle.from_layout(p.rows, p.title, true, rng))
	_check(figures_ok, "Figuras: las figuras de todas las variantes se pueden llenar")


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


## Error en la Criba: pelea con las estatuas y muerte en la sala.
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
	var g: Guardian = awake[0]
	var halves := game.health.halves
	t = 0.0
	while game.health.halves == halves and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_check(game.health.halves == halves - 1, "Guardianes: el golpe de un centinela quita medio corazón")
	# Tres golpes lo vencen
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
	# Sin corazones: un minuto menos y vuelve a la entrada
	var before := game.timer.remaining
	game.health.damage(game.health.halves)
	await _wait(2.4)
	var lost := before - game.timer.remaining
	var dormant := lvl.nodes_of(Guardian).filter(func(x): return x.state_name == "dormant")
	_check(lost > 59.9 and lost < 63.5 and game.health.halves == game.health.max_halves, "Sin corazones: se pierde 1 minuto y vuelven los 5 corazones (perdió %.1f)" % lost)
	_check(game.player.global_position.distance_to(lvl.room_entrance()) < 4.0 and dormant.size() == 2 and lvl.alarm.level == 1, "Sin corazones: vuelve a la entrada de la sala, las estatuas a su pedestal y la alarma sigue en 1")


## Alarma 3: el rúnico explota y pone el reto de teclas.
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


## Caballeros, hechicero, orbes y pausa.
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
	# En pausa nada se mueve
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
	# El orbe quita medio corazón y el garrote lo deshace
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


## Corazones, castigo de tiempo y olas.
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


## Sin corazones y con un minuto o menos se acaba el juego.
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


## Vence a todos los guardianes que queden.
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


## Reglas del buscaminas.
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
	# Con bandera no se destapa
	var flagged := Vector2i(-1, -1)
	for c in board.cells():
		if not board.revealed.has(c):
			flagged = c
			break
	board.toggle_flag(flagged)
	_check(board.reveal(flagged) == MineBoard.Result.NOTHING, "Buscaminas: una baldosa con bandera no se puede destapar")
	board.free()


## La Sala 3 completa.
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
	game.codex.editor.text = "luces.apagar()\n"
	game.machine.current.run()
	await _wait(0.3)
	var t := 0.0
	while not game.codex.visible and t < 20.0:
		await _wait(0.2)
		t += 0.2
	_check(not lvl.machine.is_solved and not lvl.board.powered and game.machine.current is CodexState, "Faro: un programa que no enciende las luces no enciende el tablero (y no despierta guardianes)")
	# El error sigue en la consola al volver
	game.codex.editor.text = "luces.encender(\n"
	game.machine.current.run()
	await _wait(0.3)
	var before: String = game.codex.console.get_parsed_text()
	game.machine.change("play")
	game.open_codex(lvl.machine.session)
	await _wait(0.3)
	_check(game.codex.console.get_parsed_text() == before and before.count("\n") > 3, "Códice: al salir y volver, la consola conserva los errores")
	game.codex.editor.text = "luces.encender()\n"
	game.machine.current.run()
	t = 0.0
	while not lvl.board.powered and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(0.8)
	game.dialog.close()
	_check(lvl.board.powered and game.machine.current is PlayState, "Faro: con luces.encender() el tablero se enciende")
	# E destapa y Q pone bandera
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
	# Una bomba: -2 corazones y tablero nuevo
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
	# Tablero limpio abre la salida
	for c in lvl.board.cells():
		if not lvl.board.mines.has(c):
			lvl.board.reveal(c)
	await _wait(0.6)
	game.dialog.close()
	_check(lvl.solved, "Tablero: destapar todas las baldosas sin mina abre la salida")
	game.player.place(Level.cell_center(Vector2i(15, 4)) + Vector2(8, 0), Vector2.UP)
	await _walk_up_until(func(): return game.level is FigureLevel, 4.0)
	await _wait(0.8)
	_check(game.level is FigureLevel and game.chamber_index == 3, "Sala 3: se cruza la salida y se llega a la Sala 4 (Factory: FigureBuilder)")


## La Sala 6: el jefe completo.
func _test_boss(lvl: ThroneLevel) -> void:
	if lvl == null:
		return
	var boss := lvl.boss
	game.dialog.close()
	_check(not boss.is_awake(), "Jefe: duerme mientras Tala va por el pasillo")
	var tuning: Dictionary = game.data.setting("boss", {})
	_check(is_equal_approx(boss.tired_time, float(tuning.tired_time)) and boss.orbs_per_phase == [3, 5, 6, 7] and boss.max_hp == int(tuning.max_hp), "Jefe: sus números vienen de config.json (State: un estado por clase)")
	game.health.halves = 4
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	_check(boss.is_awake() and game.health.halves == 8, "Jefe: al entrar a la sala despierta y Tala recupera 2 corazones")
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
	_check(boss.max_hp == 16 and boss.phase_hp() == 4 and boss.orbs_per_phase.size() == 4, "Jefe: 16 de vida en 4 partes")
	for i in boss.phase_hp():
		boss.take_hit(1, Vector2.UP)
	_check(boss.state == "shield" and not boss.can_be_hit(), "Jefe: al perder una cuarta parte de la vida se cubre con un escudo")
	t = 0.0
	while not game.machine.current is QuizState and t < 3.0:
		await _wait(0.2)
		t += 0.2
	_check(game.machine.current is QuizState and game.level.process_mode == Node.PROCESS_MODE_DISABLED, "Jefe: con el escudo aparece un problema y el mundo se detiene")
	var quiz := game.machine.current as QuizState
	quiz.choose((int(quiz.quiz.answer) + 1) % quiz.quiz.options.size())
	await _wait(QuizState.RESULT_TIME + 1.0)
	_check(lvl.alarm.fighting() and lvl.alarm.alive_count() == 4, "Jefe: si falla el problema llama a 4 guardianes")
	await _clear_guardians(lvl)
	await _wait(0.5)
	_check(boss.can_be_hit(), "Jefe: vencida la ola, el escudo cae")
	game.health.refill()
	for i in boss.phase_hp():
		boss.take_hit(1, Vector2.UP)
	t = 0.0
	while not game.machine.current is QuizState and t < 3.0:
		await _wait(0.2)
		t += 0.2
	quiz = game.machine.current as QuizState
	quiz.choose(int(quiz.quiz.answer))
	await _wait(QuizState.RESULT_TIME + 1.6)
	_check(not lvl.alarm.fighting() and boss.can_be_hit(), "Jefe: si acierta, el escudo cae sin guardianes")
	var potions := game.get_tree().get_nodes_in_group("potions")
	_check(potions.size() == 2, "Jefe: cada vez que cae el escudo aparece una poción")
	var potion: HeartPotion = potions[0]
	game.health.refill()
	game.player.place(potion.global_position, Vector2.UP)
	await _wait(0.2)
	_check(is_instance_valid(potion) and not potion.is_queued_for_deletion(), "Poción: con los corazones llenos se queda en el piso")
	game.health.halves = 4
	await _wait(0.2)
	_check(game.health.halves == 6 and not is_instance_valid(potion), "Poción: al tocarla Tala recupera un corazón")
	# Se acaba el tiempo del problema
	for i in boss.phase_hp():
		boss.take_hit(1, Vector2.UP)
	t = 0.0
	while not game.machine.current is QuizState and t < 3.0:
		await _wait(0.2)
		t += 0.2
	var waited := 0.0
	while game.machine.current is QuizState and waited < 20.0:
		await _wait(0.5)
		waited += 0.5
	_check(waited >= 15.0 and lvl.alarm.fighting() and lvl.alarm.alive_count() == 6, "Jefe: sin responder, a los 15 s llama a 6 guardianes")
	# Tala cae: la pelea empieza de nuevo
	lvl.restart_after_death()
	await _wait(0.5)
	_check(boss.hp == boss.max_hp and boss.phase == 0 and not lvl.alarm.fighting() and boss.can_be_hit() and game.get_tree().get_nodes_in_group("potions").is_empty(), "Jefe: si Tala cae, el jefe recupera toda la vida y vuelve a la fase 1")
	game.health.refill()
	while boss.hp > 0:
		if game.machine.current is QuizState:
			(game.machine.current as QuizState).choose(int((game.machine.current as QuizState).quiz.answer))
			await _wait(QuizState.RESULT_TIME + 0.5)
		elif boss.can_be_hit():
			boss.take_hit(1, Vector2.UP)
		else:
			await _wait(0.3)
	t = 0.0
	while boss.state != "hidden" and t < 5.0:
		await _wait(0.2)
		t += 0.2
	t = 0.0
	while not game.machine.current is EndState and t < 6.0:
		await _wait(0.2)
		t += 0.2
	_check(game.machine.current is EndState and game.machine.current._won, "Jefe: al vencerlo se gana el juego")


## Cada problema tiene una sola respuesta buena.
func _test_boss_quiz() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var quiz := BossQuiz.new(game.data.message)
	var ok := true
	for i in 300:
		var kind: String = ["paridad", "multiplo", "despejar"][i % 3]
		var q := quiz.make(kind, rng)
		var options: Array = q.options
		var unique := {}
		for o in options:
			unique[o] = true
		ok = ok and unique.size() == options.size() and q.answer >= 0 and q.answer < options.size()
		ok = ok and options.size() == (2 if kind == "paridad" else 4)
	_check(ok, "Prueba del jefe: 300 problemas, opciones distintas y una sola buena")
	var p := quiz.make("despejar", rng)
	var parts := String(p.question).split(" = ")
	_check(p.options[p.answer] != "" and "x" in parts[0], "Prueba del jefe: despejar muestra ax + b = c")


## Prensas de la Sala 2.
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
	# Quieta en la prensa: la atrapa
	var resets := [0]
	press.crushed.connect(func(): resets[0] += 1, CONNECT_ONE_SHOT)
	game.player.place(press.global_position + Vector2(-30, 3), Vector2.UP)
	var t := 0.0
	while resets[0] == 0 and t < press.period * 1.5:
		await _wait(0.05)
		t += 0.05
	_check(resets[0] == 1, "Prensas: si Tala se queda dentro, la prensa la atrapa")
	await _wait(0.3)
	# Con el ritmo justo pasa
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
	game.player.place(Level.cell_center(Vector2i(15, 24)), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 4.0)
	_check(lvl._in_hall, "Prensas: se llega caminando a la sala del Mural")


## Reglas del Mural.
func _test_roots_trial() -> void:
	_check(RootsTrial.equation(3, 5, 20) == "3x + 5 = 20" and RootsTrial.equation(2, -4, 10) == "2x − 4 = 10" and RootsTrial.equation(4, 9, -7) == "4x + 9 = −7", "Mural: la ecuación se escribe con sus signos")
	var case := {"a": 3, "b": 5, "c": 20, "x": 5}
	_check(RootsTrial.judge(case, 5) == RootsTrial.Verdict.RIGHT and RootsTrial.judge(case, 5.0) == RootsTrial.Verdict.RIGHT, "Mural: 5 y 5.0 son correctos para 3x + 5 = 20")
	_check(RootsTrial.judge(case, 15) == RootsTrial.Verdict.WRONG, "Mural: 15 (olvidar dividir) está mal")
	_check(RootsTrial.judge(case, "5") == RootsTrial.Verdict.BAD_SHAPE and RootsTrial.judge(case, null) == RootsTrial.Verdict.BAD_SHAPE, "Mural: un texto o nada (sin return) no sirve")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var trial := RootsTrial.new(game.data.chamber_data(1).get("cases", []), rng)
	var kinds_ok: bool = trial.cases.size() == 3 and trial.cases[1].b < 0 and trial.cases[2].x < 0
	for c in trial.cases:
		kinds_ok = kinds_ok and c.a * c.x + c.b == c.c
	_check(kinds_ok, "Mural: tres ecuaciones (b positivo, b negativo, x negativa) con solución entera")
	var sandbox := ScriptSandbox.new()
	var program := sandbox.run(ROOTS_OK, {}, 2000)
	var all_right := true
	for i in 100:
		var c := RootsTrial.make_case(["plus", "minus", "negative"][i % 3], rng)
		var answer := sandbox.call_function(program, "despejar", [c.a, c.b, c.c])
		all_right = all_right and answer[0] and RootsTrial.judge(c, answer[1]) == RootsTrial.Verdict.RIGHT
	_check(all_right, "Mural: return (c - b) / a despeja 100 ecuaciones al azar")


## La Sala 2 completa.
func _test_mural() -> void:
	var lvl := game.level as RootsLevel
	if lvl == null:
		return
	game.dialog.close()
	var machine := lvl.machine
	var cases_before: Array = machine.trial.cases.duplicate(true)
	game.open_codex(machine.session)
	await _wait(0.6)
	game.codex.editor.text = "def despejar(a, b, c):\n    return c - b\n"
	Engine.time_scale = 4.0
	game.machine.current.run()
	await _wait(0.2)
	var t := 0.0
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	_check(not machine.is_solved and machine.trial.cases != cases_before, "Mural: olvidar dividir entre a no sirve y el Mural cambia sus ecuaciones")
	_check(lvl.alarm.level == 1 and lvl.machine.locked, "Sala 2: el error del Mural despierta a sus guardianes y lo bloquea")
	await _clear_guardians(lvl)
	game.open_codex(machine.session)
	await _wait(0.6)
	game.codex.editor.text = "def despejar(a, b, c):\n    return %d\n" % machine.trial.cases[0].x
	game.machine.current.run()
	t = 0.0
	await _wait(0.2)
	while not game.machine.current is PlayState and t < 30.0:
		await _wait(0.2)
		t += 0.2
	_check(not machine.is_solved and lvl.alarm.level == 2, "Mural: devolver la x de la primera ecuación a mano no sirve (y la alarma sube a 2)")
	await _clear_guardians(lvl)
	game.open_codex(machine.session)
	await _wait(0.6)
	Engine.time_scale = 4.0
	game.codex.editor.text = ROOTS_OK
	game.machine.current.run()
	t = 0.0
	while not machine.is_solved and t < 40.0:
		await _wait(0.2)
		t += 0.2
	Engine.time_scale = 1.0
	await _wait(1.0)
	game.dialog.close()
	_check(machine.is_solved and lvl.solved, "Mural: return (c - b) / a despeja las tres ecuaciones")
	game.player.place(Level.cell_center(Vector2i(27, 12)), Vector2.RIGHT)
	_key("move_right", true)
	t = 0.0
	while not game.level is VortexLevel and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_release_all()
	await _wait(0.8)
	_check(game.level is VortexLevel and game.chamber_index == 2, "Sala 2: se cruza la reja del este y se llega a la Sala 3 (Factory: VortexBuilder)")


## Guardar y cargar.
func _test_save_and_load() -> void:
	game.saves.path = "user://save_prueba.cfg"
	game.load_chamber(0)
	var filter := game.level as FilterLevel
	filter.machine.session.code = "print(1)\n"
	filter.machine.mark_solved()
	await _wait(0.3)
	game.save_game()
	game.load_game()
	await _wait(0.3)
	filter = game.level as FilterLevel
	_check(filter != null and filter.solved and filter.machine.is_solved and filter.machine.session.code == "print(1)\n", "Guardar: la Sala 1 resuelta sigue resuelta al cargar, con el código en la máquina")
	_check(game.player.global_position.distance_to(filter.room_entrance()) < 4.0, "Guardar: al cargar, Tala aparece en la entrada de la sala")
	game.dialog.close()
	game.load_chamber(2)
	var vortex := game.level as VortexLevel
	vortex.restore_solved()
	await _wait(0.3)
	game.save_game()
	game.load_game()
	await _wait(0.3)
	game.dialog.close()
	vortex = game.level as VortexLevel
	_check(vortex != null and vortex.solved and vortex.board.is_cleared(), "Guardar: el buscaminas limpio sigue limpio al cargar")
	game.load_chamber(3)
	game.save_game()
	game.load_game()
	await _wait(0.3)
	var figures := game.level as FigureLevel
	_check(figures != null and not figures.solved and figures._in_hall and game.dialog.is_open(), "Guardar: una sala sin resolver empieza en la entrada, con su presentación")
	game.dialog.close()
	game.saves.clear()
	game.saves.path = SaveRepository.PATH


## Evento del mouse.
func _mouse(at: Vector2, pressed: bool, move := false) -> void:
	var event: InputEventMouse
	if move:
		event = InputEventMouseMotion.new()
	else:
		event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
	event.position = game.get_viewport().get_final_transform() * at
	event.global_position = event.position
	game.get_viewport().push_input(event)


## Resuelve un rompecabezas probando todo (vuelta atrás).
func _solve_figure(puzzle: FigurePuzzle, i := 0) -> bool:
	if i == puzzle.pieces.size():
		return puzzle.is_solved()
	for turn in 4:
		for y in puzzle.size.y:
			for x in puzzle.size.x:
				if puzzle.place(i, Vector2i(x, y)):
					if _solve_figure(puzzle, i + 1):
						return true
					puzzle.lift(i)
		puzzle.rotate(i)
	return false


## Reglas de la Mesa.
func _test_figure_rules() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var house := FigurePuzzle.from_layout(["..A..", ".AAA.", "BBCDD", "BCCCD", "BEEED"], "Casa", false, rng)
	_check(house.target.size() == 19 and house.pieces.size() == 5 and house.size == Vector2i(5, 5), "Figuras: la casa tiene 19 casillas y 5 piezas")
	var before := house.cells_of(0).duplicate()
	for k in 4:
		house.rotate(0)
	_check(house.cells_of(0) == before, "Figuras: cuatro giros dejan la pieza como estaba")
	_check(not house.place(0, Vector2i(0, 0)), "Figuras: una pieza que se sale de la figura no se puede poner")
	for i in house.pieces.size():
		house.place(i, house.solution[i].at)
	_check(house.is_solved(), "Figuras: con cada pieza en su lugar del dibujo, la figura queda llena")
	house.lift(4)
	_check(not house.is_solved() and not house.place(4, house.solution[1].at), "Figuras: falta una pieza = sin resolver; encima de otra no se puede")
	var all_ok := true
	for i in 20:
		rng.seed = i
		for p in game.data.chamber_data(3).get("puzzles", []):
			all_ok = all_ok and _solve_figure(FigurePuzzle.from_layout(p.rows, p.title, true, rng))
	_check(all_ok, "Figuras: las figuras de la sala siempre se pueden llenar, aunque las piezas lleguen giradas")


## La Sala 4 completa.
func _test_figures() -> void:
	var lvl := game.level as FigureLevel
	if lvl == null:
		return
	game.dialog.close()
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	game.dialog.close()
	_check(lvl.table.puzzles.size() == 2 and not lvl.alarm.fighting(), "Sala 4: la Mesa tiene dos figuras")
	lvl._open_table()
	await _wait(0.2)
	_check(game.machine.current is PuzzleState and game.level.process_mode == Node.PROCESS_MODE_DISABLED, "Mesa: el atril abre el rompecabezas y el mundo queda quieto")
	var state := game.machine.current as PuzzleState
	var first := lvl.table.puzzle()
	while first.cells_of(0) != first.solution[0].cells:
		first.rotate(0)
	first.place(0, first.solution[0].at)
	state.handle_input(["cancel"])
	await _wait(0.2)
	_check(game.machine.current is PlayState and first.is_placed(0), "Mesa: ESC la cierra y las piezas quedan donde estaban")
	# Arrastrar con el mouse
	lvl._open_table()
	await _wait(0.2)
	state = game.machine.current as PuzzleState
	var k := 1
	first.lift(k)
	while first.cells_of(k) != first.solution[k].cells:
		first.rotate(k)
	var half := Vector2.ONE * PuzzleState.CELL / 2.0
	var cell0 := Vector2(first.cells_of(k)[0]) * PuzzleState.CELL + half
	var from := state._piece_origin(game.ui, k) + cell0
	var to := state._board_origin(game.ui) + Vector2(first.solution[k].at) * PuzzleState.CELL + cell0
	_mouse(from, false, true)
	_mouse(from, true)
	await _wait(0.1)
	_mouse(to, false, true)
	await _wait(0.1)
	_mouse(to, false)
	await _wait(0.1)
	_check(first.pieces[k].at == first.solution[k].at, "Mesa: con el ratón se arrastra una pieza y encaja en la figura")
	state.handle_input(["cancel"])
	await _wait(0.2)
	for n in 2:
		lvl._open_table()
		await _wait(0.2)
		state = game.machine.current as PuzzleState
		var puzzle := lvl.table.puzzle()
		for i in puzzle.pieces.size():
			puzzle.lift(i)
		if n == 0:
			_solve_figure(puzzle)
			state.check_solved(game.ui)
		else:
			# La Casa: girar con R y arrastrar
			for i in puzzle.pieces.size():
				var half_cell := Vector2.ONE * PuzzleState.CELL / 2.0
				for turn in 4:
					if puzzle.cells_of(i) == puzzle.solution[i].cells:
						break
					_mouse(state._piece_origin(game.ui, i) + Vector2(puzzle.cells_of(i)[0]) * PuzzleState.CELL + half_cell, false, true)
					await _wait(0.05)
					_key("rotate", true)
					await _wait(0.05)
					_key("rotate", false)
					await _wait(0.05)
				var grab := Vector2(puzzle.cells_of(i)[0]) * PuzzleState.CELL + half_cell
				var start := state._piece_origin(game.ui, i) + grab
				var goal := state._board_origin(game.ui) + Vector2(puzzle.solution[i].at) * PuzzleState.CELL + grab
				_mouse(start, false, true)
				_mouse(start, true)
				await _wait(0.05)
				_mouse(goal, false, true)
				await _wait(0.05)
				_mouse(goal, false)
				await _wait(0.05)
			_check(puzzle.is_solved(), "Mesa: La Casa se llena con R y el ratón, como la juega una persona")
		await _wait(PuzzleState.SOLVED_PAUSE + 0.4)
		if n == 0:
			_check(lvl.table.current == 1 and game.machine.current is PuzzleState, "Mesa: al llenar la primera figura llega la segunda")
			state.handle_input(["cancel"])
			await _wait(0.2)
	game.dialog.close()
	_check(lvl.table.is_solved and lvl.solved and game.machine.current is PlayState, "Mesa: con las dos figuras llenas se abre la reja del este")
	game.player.place(Level.cell_center(Vector2i(27, 12)), Vector2.RIGHT)
	_key("move_right", true)
	var t := 0.0
	while not game.level is CoreLevel and t < 4.0:
		await _wait(0.1)
		t += 0.1
	_release_all()
	await _wait(0.8)
	_check(game.level is CoreLevel and game.chamber_index == 4, "Sala 4: se cruza la reja del este y se llega a la Sala 5 (Factory: CoreBuilder)")


## Reglas del sendero.
func _test_path_rules() -> void:
	var stones := NumberPath.new()
	var rng := RandomNumberGenerator.new()
	var ok := true
	var few_safe := true
	var numbers_ok := true
	for i in 200:
		rng.seed = i
		var m := 3 + i % 2
		stones.generate(rng, m, 3, 60)
		var path := stones.path
		ok = ok and path[0].y == stones.rows - 1 and path[-1].y == 0 and stones.goal == path[-1]
		for k in path.size():
			ok = ok and stones.is_safe(path[k])
			if k > 0:
				ok = ok and absi(path[k].x - path[k - 1].x) + absi(path[k].y - path[k - 1].y) == 1
		var safe := 0
		for c in stones.numbers:
			safe += 1 if stones.is_safe(c) else 0
			numbers_ok = numbers_ok and stones.numbers[c] >= 2 and stones.numbers[c] <= 60
		few_safe = few_safe and safe <= path.size() + 3
	stones.free()
	_check(ok, "Sendero: en 200 salas hay un camino de losas buenas, vecinas, de abajo hasta el núcleo")
	_check(few_safe and numbers_ok, "Sendero: fuera del camino hay a lo sumo 3 losas buenas; los números van de 2 a 60")


## La Sala 5 completa.
func _test_core() -> void:
	var lvl := game.level as CoreLevel
	if lvl == null:
		return
	game.dialog.close()
	game.player.place(lvl.room_entrance() + Vector2(0, 20), Vector2.UP)
	await _walk_up_until(func(): return lvl._in_hall, 3.0)
	game.dialog.close()
	var stones := lvl.stones
	_check(str(stones.multiple) in lvl.hud_line(), "Sendero: la regla de la sala está en el HUD")
	# Losa mala
	var bad := Vector2i(-1, -1)
	for x in stones.cols:
		if not stones.is_safe(Vector2i(x, stones.rows - 1)):
			bad = Vector2i(x, stones.rows - 1)
			break
	var before := game.timer.remaining
	game.player.place(stones.cell_center_global(bad), Vector2.UP)
	await _wait(1.6)
	var lost := before - game.timer.remaining - 1.6
	_check(stones.broken.has(bad) and lost > 6.5 and lost < 8.0, "Sendero: una losa mala se rompe y Tala cae (−7 s)")
	_check(game.player.global_position.distance_to(lvl.room_entrance()) < 4.0, "Sendero: después de caer, Tala vuelve a la entrada")
	# El borde de una losa buena no rompe nada
	var start: Vector2i = stones.path[0]
	var side := start + Vector2i.LEFT if start.x > 0 else start + Vector2i.RIGHT
	if not stones.is_safe(side) and not stones.broken.has(side):
		var edge := stones.cell_center_global(start).lerp(stones.cell_center_global(side), 0.5) + (stones.cell_center_global(side) - stones.cell_center_global(start)).normalized() * 2.0
		game.player.global_position = edge
		await _wait(0.3)
		_check(not stones.broken.has(side) and not game.player.falling, "Sendero: pisar la orilla de la losa buena no rompe la vecina")
	# Camino bueno hasta el núcleo
	for c in stones.path:
		game.player.global_position = stones.cell_center_global(c)
		await _wait(0.15)
	var t := 0.0
	while not game.level is ThroneLevel and t < 6.0:
		await _wait(0.2)
		t += 0.2
	_check(game.level is ThroneLevel and game.chamber_index == 5, "Núcleo: por el camino bueno se llega al núcleo y a la Sala 6 (Factory: ThroneBuilder)")
	await _test_boss(game.level as ThroneLevel)
