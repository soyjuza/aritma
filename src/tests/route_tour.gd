## Capturas del recorrido (necesita ventana):
## Godot --path . -- --recorrido=/ruta/carpeta
class_name RouteTour
extends RefCounted

const CRIBA := "while tolva.quedan() > 0:\n    n = tolva.soltar()\n    if n % 2 == 0:\n        caliz.recibir()\n    else:\n        crisol.desintegrar()\n"

## Orden de antes (Criba → Mural → ...): los recorridos viejos usan estos números
const OLD_ORDER := ["filter", "roots", "vortex", "figures", "core", "throne"]
const LOCK_OK := "nivel = sensor.leer()\nnivel = nivel + 3\ncompuerta.subir(nivel)\n"

var game: Game
var folder := ""


func _init(context: Game) -> void:
	game = context


func run(arg: String) -> void:
	var parts := arg.split(":")
	folder = parts[0]
	DirAccess.make_dir_recursive_absolute(folder)
	game.set_process_unhandled_input(false)
	if parts.size() > 1 and parts[1] == "compuerta":
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(0)
		await _lock_room()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "bosque":
		await _forest_tour()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "mundo":
		await _world_tour()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "misiones":
		await _quests_tour()
		game.get_tree().quit()
		return
	game.data.use_order(OLD_ORDER)
	if parts.size() > 1 and parts[1] == "sala2":
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(1)
		await _roots_room()
		game.get_tree().quit()
		return
	var rooms := {"sala3": [2, _vortex_room], "sala4": [3, _figures_room], "sala5": [4, _path_room]}
	if parts.size() > 1 and rooms.has(parts[1]):
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(rooms[parts[1]][0])
		await rooms[parts[1]][1].call()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "practicas":
		await _practice_tour()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "celular":
		await _phone_tour()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "bloques":
		await _blocks_tour()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "jefe":
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(5)
		await _boss_fight()
		game.get_tree().quit()
		return
	await _wait(1.0)
	await _shot("00_titulo")
	game.machine.change("play", {"mode": "new"})
	await _wait(1.2)
	await _shot("01_llegada")
	game.dialog.close()
	var town := game.level as TownLevel
	for stop in [["02_orun", Vector2i(16, 18)], ["03_fachada", Vector2i(17, 9)], ["04_casas", Vector2i(8, 12)]]:
		game.player.place(Level.cell_center(stop[1]), Vector2.UP)
		await _wait(0.8)
		await _shot(stop[0])
	game.player.place(town.gate.global_position + Vector2(0, 16), Vector2.UP)
	game.open_codex(town.gate.session)
	await _wait(1.2)
	await _shot("05_codice_puerta_vacio")
	_arm("puerta.abrir()\n")
	await _shot("05_codice_puerta")
	game.machine.current.run()
	await _wait(2.0)
	game.dialog.close()
	await _shot("06_puerta_abierta")
	# Este recorrido va sin prácticas (tienen el suyo: practicas)
	for i in game.data.chamber_count():
		for key in game.data.chamber_data(i).get("practices", []):
			game.practices_done[key] = true
	await game.enter_temple()
	await _wait(1.0)
	game.dialog.close()
	await _shot("07_pasillo")
	var lvl := game.level as FilterLevel
	var pit: Pit = lvl.get_node("Fosos/Foso1")
	game.player.place(pit.global_position + Vector2(pit.size.x / 2.0, pit.size.y + 24), Vector2.UP)
	await _wait(0.6)
	await _shot("08_foso")
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	await _wait(1.0)
	game.dialog.close()
	await _shot("09_sala")
	game.player.place(Level.cell_center(Vector2i(15, 9)), Vector2.UP)
	await _wait(0.8)
	await _shot("10_criba_cerca")
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	_arm(CRIBA, 3)
	await _shot("11_codice_criba_a_medias")
	_arm(CRIBA)
	await _shot("11_codice_criba")
	game.machine.current.run()
	await _wait(1.4)
	await _shot("12_trabajando_a")
	await _wait(0.9)
	await _shot("12_trabajando_b")
	while not lvl.machine.is_solved:
		await _wait(0.3)
	await _wait(1.2)
	await _shot("13_resuelta")
	game.dialog.close()
	game.player.place(Level.cell_center(Vector2i(15, 5)), Vector2.UP)
	await _wait(0.8)
	await _shot("14_salida")
	game.get_tree().quit()


## Capturas de la Sala 2.
func _roots_room() -> void:
	var lvl := game.level as RootsLevel
	await _wait(0.8)
	game.dialog.close()
	await _shot("20_prensas_abajo")
	game.player.place(lvl.get_node("Efectos/Prensa2").global_position + Vector2(0, 32), Vector2.UP)
	var press: Crusher = null
	for n in lvl.fx.get_children():
		if n is Crusher and absf(n.global_position.y - game.player.global_position.y) < 48:
			press = n
	while press.extension() < 0.95:
		await _wait(0.02)
	await _shot("21_prensa_cerrada")
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	await _wait(1.0)
	game.dialog.close()
	await _shot("22_sala_mural")
	game.player.place(Level.cell_center(Vector2i(15, 14)), Vector2.UP)
	await _wait(0.6)
	await _shot("23_mural_cerca")
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	game.codex.write("def despejar(a, b, c):\n    return (c - b) / a\n")
	await _shot("24_codice_mural")
	game.machine.current.run()
	await _wait(1.6)
	await _shot("25_mural_trabajando")
	while not lvl.machine.is_solved:
		await _wait(0.3)
	await _wait(1.0)
	await _shot("26_mural_resuelto")


## Capturas de la Sala 3.
func _vortex_room() -> void:
	var lvl := game.level as VortexLevel
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	lvl._on_hall_entered()
	await _wait(1.0)
	game.dialog.close()
	await _shot("30_vortice_apagado")
	game.player.place(lvl.machine.global_position + Vector2(0, 30), Vector2.UP)
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	game.codex.write("luces.encender(\n")
	game.machine.current.run()
	game.machine.change("play")
	game.open_codex(lvl.machine.session)
	await _wait(0.6)
	await _shot("31a_error_conservado")
	game.codex.write("luces.encender()\n")
	await _shot("31_codice_luces")
	game.machine.current.run()
	await _wait(2.5)
	await _shot("32_faro_encendido")
	game.dialog.close()
	game.player.place(lvl.board.cell_center(Vector2i(3, 6)), Vector2.UP)
	await _wait(1.0)
	await _shot("33_tablero_encendido")
	# Lo limpia caminando y con E
	for c in lvl.board.cells():
		if lvl.board.mines.is_empty() or not (lvl.board.mines.has(c) or lvl.board.revealed.has(c)):
			game.player.place(lvl.board.cell_center(c), Vector2.UP)
			lvl.handle_action(["interact"])
	await _wait(0.6)
	await _shot("34_tablero_limpio")
	await _wait(2.0)
	game.dialog.close()
	game.player.place(lvl.board.cell_center(Vector2i(3, 0)) + Vector2(0, -10), Vector2.UP)
	await _wait(1.0)
	await _shot("35_tablero_limpio_reja")


## Capturas de la Sala 4.
func _figures_room() -> void:
	var lvl := game.level as FigureLevel
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	lvl._on_hall_entered()
	await _wait(1.0)
	await _shot("39_intro_mesa")
	game.dialog.close()
	await _shot("40_sala_mesa")
	game.player.place(lvl.table.global_position + Vector2(0, 46), Vector2.UP)
	await _wait(0.6)
	await _shot("41_mesa_cerca")
	lvl._open_table()
	await _wait(0.4)
	await _shot("42_rompecabezas")
	var puzzle := lvl.table.puzzle()
	for i in 2:
		puzzle.place(i, puzzle.solution[i].at)
	await _wait(0.3)
	await _shot("43_rompecabezas_medio")
	puzzle.place(2, puzzle.solution[2].at)
	(game.machine.current as PuzzleState).check_solved(game.ui)
	await _wait(0.5)
	await _shot("44_figura_llena")
	await _wait(1.5)
	await _shot("45_segunda_figura")
	puzzle = lvl.table.puzzle()
	for i in puzzle.pieces.size():
		for k in 4:
			if puzzle.cells_of(i) == puzzle.solution[i].cells:
				break
			puzzle.rotate(i)
		puzzle.place(i, puzzle.solution[i].at)
		await _wait(0.3)
		await _shot("45_%d_casa_pieza_%d" % [i + 1, i + 1])
	(game.machine.current as PuzzleState).check_solved(game.ui)
	await _wait(0.5)
	await _shot("45_9_casa_resuelta")
	game.machine.change("play")
	await _wait(0.6)
	await _shot("46_mesa_una_lista")


## Capturas de la Sala 5.
func _path_room() -> void:
	var lvl := game.level as CoreLevel
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	lvl.set_checkpoint(lvl.room_entrance())
	lvl._on_hall_entered()
	await _wait(1.0)
	await _shot("50_regla_dialogo")
	game.dialog.close()
	await _wait(0.3)
	await _shot("51_sendero")
	var stones := lvl.stones
	for k in 3:
		game.player.global_position = stones.cell_center_global(stones.path[k])
		await _wait(0.4)
	await _shot("52_cruzando")
	var bad := Vector2i(-1, -1)
	for x in stones.cols:
		if not stones.is_safe(Vector2i(x, stones.rows - 1)):
			bad = Vector2i(x, stones.rows - 1)
	game.player.global_position = stones.cell_center_global(bad)
	await _wait(0.35)
	await _shot("53_losa_rompiendose")
	await _wait(2.0)
	await _shot("54_aviso_losa")
	for k in stones.path.size() - 1:
		game.player.global_position = stones.cell_center_global(stones.path[k])
		await _wait(0.25)
	await _shot("55_junto_al_nucleo")


## Capturas del jefe.
func _boss_fight() -> void:
	var lvl := game.level as ThroneLevel
	await _wait(1.0)
	game.dialog.close()
	await _shot("j0_pasillo")
	game.player.place(lvl.room_entrance(), Vector2.UP)
	lvl._on_hall_entered()
	await _wait(1.6)
	await _shot("j1_aparece")
	await _wait(0.8)
	game.dialog.close()
	await _shot("j2_sala")
	game.player.place(lvl.boss.global_position + Vector2(-60, 60), Vector2.UP)
	lvl.boss.change("volley")
	await _wait(0.9)
	await _shot("j3_rafaga")
	game.health.refill()
	game.player.place(lvl.boss.global_position + Vector2(20, 30), Vector2.LEFT)
	lvl.boss.change("slam")
	await _wait(0.8)
	await _shot("j4_pisoton")
	await _wait(0.8)
	await _shot("j5_cansado")
	game.health.refill()
	for i in lvl.boss.phase_hp():
		lvl.boss.take_hit(1, Vector2.UP)
	await _wait(0.5)
	await _shot("j6_escudo")
	while not game.machine.current is QuizState:
		await _wait(0.1)
	await _wait(0.6)
	await _shot("j6a_problema")
	var quiz := game.machine.current as QuizState
	quiz.choose((int(quiz.quiz.answer) + 1) % quiz.quiz.options.size())
	await _wait(0.4)
	await _shot("j6b_problema_mal")
	await _wait(2.6)
	await _shot("j6c_guardianes")
	var potion_shot := false
	while lvl.boss.hp > 0:
		var potions := game.get_tree().get_nodes_in_group("potions")
		if not potion_shot and not potions.is_empty():
			potion_shot = true
			await _wait(0.6)
			game.player.place((potions[0] as Node2D).global_position + Vector2(-40, 20), Vector2.RIGHT)
			await _wait(0.5)
			await _shot("j6f_pocion")
		if game.machine.current is QuizState:
			quiz = game.machine.current as QuizState
			await _wait(0.5)
			await _shot("j6d_problema_%d" % lvl.boss.phase)
			quiz.choose(int(quiz.quiz.answer))
			await _wait(0.4)
			await _shot("j6e_problema_bien_%d" % lvl.boss.phase)
			await _wait(1.5)
		elif lvl.boss.can_be_hit():
			lvl.boss.take_hit(1, Vector2.UP)
		else:
			for g in lvl.nodes_of(Guardian):
				if g.is_active() and g.can_be_hit():
					g.take_hit(99, Vector2.UP)
			await _wait(1.0)
	await _wait(0.8)
	await _shot("j7_vencido")
	await _wait(3.5)
	await _shot("j8_final")


func _wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(folder.path_join(name + ".png"))
	print("recorrido ", name)


## Arma con las piezas las primeras lines líneas del programa.
func _arm(code: String, lines := 99) -> void:
	var board := game.codex.board
	board.session.use_blocks = true
	board.session.placed.clear()
	for line in code.split("\n").slice(0, lines):
		if line.strip_edges() != "":
			var indent := (line.length() - line.strip_edges(true, false).length()) / 4
			board.place(board.session.blocks.find(line.strip_edges()), board.session.placed.size(), indent)
	game.codex.show_mode()


## Solo el Códice con bloques en la puerta, la Criba y el Mural.
func _blocks_tour() -> void:
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	var town := game.level as TownLevel
	game.player.place(town.gate.global_position + Vector2(0, 16), Vector2.UP)
	game.open_codex(town.gate.session)
	await _wait(1.2)
	await _shot("b1_puerta_vacia")
	_arm("puerta.abrir()\n")
	await _shot("b2_puerta_armada")
	game.machine.change("play")
	game.load_chamber(0)
	await _wait(0.5)
	game.dialog.close()
	var lvl := game.level as FilterLevel
	game.player.place(Level.cell_center(Vector2i(15, 9)), Vector2.UP)
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	await _shot("b3_criba_vacia")
	_arm(CRIBA, 3)
	await _shot("b4_criba_a_medias")
	_arm(CRIBA)
	await _shot("b5_criba_armada")
	game.codex.toggle_mode()
	await _wait(0.2)
	await _shot("b6_criba_texto")
	game.codex.toggle_mode()
	game.machine.change("play")
	game.load_chamber(1)
	await _wait(0.5)
	game.dialog.close()
	var mural := game.level as RootsLevel
	game.player.place(mural.machine.global_position + Vector2(0, 30), Vector2.UP)
	game.open_codex(mural.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	await _shot("b7_mural_vacio")
	_arm("def despejar(a, b, c):\n    return (c - b) / a\n")
	await _shot("b8_mural_armado")


## La Compuerta (Sala 1 del capítulo 1).
func _lock_room() -> void:
	var lvl := game.level as LockLevel
	game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
	lvl._on_hall_entered()
	await _wait(1.0)
	await _shot("l0_compuerta_intro")
	game.dialog.close()
	game.player.place(lvl.machine.global_position + Vector2(0, 40), Vector2.UP)
	await _wait(0.6)
	await _shot("l1_compuerta_sala")
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	await _shot("l2_codice_vacio")
	game.codex.write("nivel = sensor.leer()\ncompuerta.subir(nivel)\n")
	game.machine.current.run()
	await _wait(1.6)
	await _shot("l3_ronda_mal")
	await _wait(1.5)
	await _shot("l4_mensaje_mal")
	# Vence a los guardianes para volver a usar el atril
	await _wait(3.0)
	for g in lvl.nodes_of(Guardian):
		if g.is_active():
			g.take_hit(99, Vector2.UP)
	await _wait(2.0)
	game.dialog.close()
	game.open_codex(lvl.machine.session)
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	game.codex.write(LOCK_OK)
	game.machine.current.run()
	await _wait(1.4)
	await _shot("l5_ronda_bien")
	await _wait(4.0)
	await _shot("l6_compuerta_abierta")
	game.dialog.close()


## Las cinco prácticas, paso a paso.
func _practice_tour() -> void:
	game.data.use_order(["lock", "roots", "vortex"])
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	await game.enter_temple()
	await _wait(1.0)
	await _shot("p1_pasos_intro")
	game.dialog.close()
	var move := game.level as PracticeMoveLevel
	await _wait(0.4)
	await _shot("p1_pasos_1")
	for id in ["caminar", "correr", "saltar"]:
		game.player.place(move.get_node("Marcas/" + id).global_position, Vector2.UP)
		move.complete(id)
		await _wait(0.6)
	game.player.place(move.get_node("Marcas/saltar").global_position + Vector2(0, -8), Vector2.UP)
	await _wait(0.6)
	await _shot("p1_pasos_foso_largo")
	move.complete("foso_largo")
	await _wait(0.8)
	await _shot("p1_pasos_fin")
	game.dialog.close()
	game.leave_practice()
	await _until(func(): return game.level is PracticeFightLevel)
	game.dialog.close()
	var fight := game.level as PracticeFightLevel
	game.player.place(fight.dummy.global_position + Vector2(0, 18), Vector2.UP)
	await _wait(0.5)
	await _shot("p2_pelea_muneco")
	for i in 3:
		fight.dummy.take_hit(1, Vector2.UP)
	await _wait(1.2)
	await _shot("p2_pelea_caballero")
	for g in fight.nodes_of(Guardian):
		g.take_hit(99, Vector2.UP)
	await _wait(2.5)
	await _shot("p2_pelea_hechicero")
	for g in fight.nodes_of(Guardian):
		g.take_hit(99, Vector2.UP)
	await _wait(2.0)
	await _shot("p2_pelea_fin")
	game.dialog.close()
	game.leave_practice()
	await _until(func(): return game.level is PracticeCodeLevel)
	game.dialog.close()
	var blocks := game.level as PracticeCodeLevel
	game.player.place(blocks.machine.global_position + Vector2(0, 18), Vector2.UP)
	await _wait(0.5)
	await _shot("p3_bloques_atril")
	await _code_stage(blocks, "p3_bloques_etapa1", "antorchas.encender()\n")
	await _code_stage(blocks, "p3_bloques_etapa2", "antorchas.encender()\nantorchas.encender()\nantorchas.encender()\n")
	await _shot("p3_bloques_fin")
	game.dialog.close()
	game.leave_practice()
	await _until(func(): return game.level is LockLevel)
	await _wait(1.0)
	await _shot("p4_sala1_llega")
	game.dialog.close()
	game.enter_chamber(1)
	await _until(func(): return game.level is PracticeCodeLevel)
	game.dialog.close()
	var funcs := game.level as PracticeCodeLevel
	game.player.place(funcs.machine.global_position + Vector2(0, 18), Vector2.UP)
	await _wait(0.5)
	await _shot("p4_funciones_atril")
	await _code_stage(funcs, "p4_funciones_etapa1", "def doble(n):\n    return n * 2\n")
	await _code_stage(funcs, "p4_funciones_etapa2", "def restar(a, b):\n    return a - b\n")
	await _shot("p4_funciones_fin")
	game.dialog.close()
	game.enter_chamber(2)
	await _until(func(): return game.level is PracticeMinesLevel)
	game.dialog.close()
	var mines := game.level as PracticeMinesLevel
	game.player.place(mines.board.cell_center(Vector2i(1, 3)), Vector2.UP)
	await _wait(0.5)
	await _shot("p5_minas_1")
	game.player.place(mines.board.cell_center(Vector2i(1, 2)), Vector2.UP)
	mines.handle_action(["interact"])
	await _wait(0.6)
	await _shot("p5_minas_2")
	game.player.place(mines.board.cell_center(Vector2i(4, 1)), Vector2.UP)
	mines.handle_action(["flag"])
	await _wait(0.6)
	await _shot("p5_minas_3")
	game.player.place(mines.board.cell_center(Vector2i(4, 0)), Vector2.UP)
	mines.handle_action(["interact"])
	await _wait(0.8)
	await _shot("p5_minas_fin")


## Abre el atril, arma el programa, lo corre y espera.
func _code_stage(lvl: PracticeCodeLevel, shot_name: String, code: String) -> void:
	# Como si presionara E en el atril
	lvl._open_machine()
	while game.rig.is_gliding():
		await _wait(0.1)
	await _wait(0.4)
	await _shot(shot_name + "_vacio")
	_arm(code)
	await _shot(shot_name + "_armado")
	game.machine.current.run()
	await _wait(2.5)
	await _shot(shot_name + "_resultado")
	game.dialog.close()


func _until(done: Callable) -> void:
	var t := 0.0
	while not done.call() and t < 20.0:
		await _wait(0.2)
		t += 0.2
	await _wait(0.6)


## Pantallas con los controles táctiles (correr con --tactil).
func _phone_tour() -> void:
	var touch := game.touch
	await _wait(0.8)
	await _shot("c00_titulo")
	game.machine.change("menu")
	await _wait(0.4)
	await _shot("c01_menu")
	game.machine.change("intro")
	await _wait(1.0)
	await _shot("c02_historia")
	game.machine.change("play", {"mode": "new"})
	await _wait(1.0)
	await _shot("c03_llegada_dialogo")
	game.dialog.close()
	await _wait(0.3)
	await _shot("c04_pueblo")
	# Palanca a medias caminando; luego CORRER prendido
	game.settings.set_value("pad", 0)
	var base := Vector2(230, touch.size.y - 215)
	touch._finger_down(1, base)
	touch._finger_move(1, base + Vector2(0, -70))
	await _wait(0.6)
	await _shot("c05a_palanca_caminando")
	touch._finger_down(2, touch._button_center("run"))
	touch._finger_up(2)
	await _wait(0.6)
	await _shot("c05b_corriendo")
	touch._finger_up(1)
	touch._finger_down(2, touch._button_center("run"))
	touch._finger_up(2)
	# Cruceta fija
	game.settings.set_value("pad", 1)
	touch._finger_down(1, base + Vector2(78, 0))
	await _wait(0.6)
	await _shot("c05c_cruceta")
	touch._finger_up(1)
	var town := game.level as TownLevel
	game.player.place(town.gate.global_position + Vector2(0, 16), Vector2.UP)
	await _wait(0.5)
	await _shot("c06_frente_al_atril")
	game.open_codex(town.gate.session)
	await _wait(0.6)
	await _shot("c07_codice_bloques")
	game.machine.change("play")
	game.machine.change("pause")
	await _wait(0.3)
	await _shot("c08_pausa")
	game.machine.change("settings", {"return_to": "pause"})
	await _wait(0.3)
	await _shot("c09_ajustes")
	game.machine.change("book", {"return_to": "play"})
	await _wait(0.3)
	await _shot("c10_libro_ultima")
	game.machine.current._page = 0
	await _wait(0.2)
	await _shot("c11_libro_pag1")
	game.machine.change("play")
	for key in ["buscaminas_2", "buscaminas_4"]:
		game.load_practice(key, 2)
		await _wait(0.5)
		await _shot("c12_%s_intro" % key)
		game.dialog.close()
		var mines := game.level as PracticeMinesLevel
		var first: Array = mines.steps()[0].cell
		game.player.global_position = mines.board.cell_center(Vector2i(int(first[0]), int(first[1])))
		mines.handle_action(["interact"])
		await _wait(0.6)
		await _shot("c13_%s_paso2" % key)
	game.load_chamber(3)
	await _wait(0.4)
	game.dialog.close()
	game.machine.change("puzzle", {"table": (game.level as FigureLevel).table})
	await _wait(0.4)
	await _shot("c14_piezas")
	game.machine.change("play")
	game.machine.change("keys", {"keys": ["J", "D", "K", "S"], "seconds": 30.0, "ready": 0.0})
	await _wait(0.3)
	await _shot("c15_reto_teclas")
	game.machine.change("quiz", {"quiz": {"title": "Sala 1", "question": "¿18 es par?", "options": ["Sí", "No"], "answer": 0}, "seconds": 15.0})
	await _wait(0.3)
	await _shot("c16_problema")
	game.finish(true)
	await _wait(2.0)
	await _shot("c17_final")


func _skip_dialog() -> void:
	var t := 0
	while game.dialog.is_open() and t < 40:
		game.dialog.advance()
		game.dialog.advance()
		t += 1
	await _wait(0.3)


## Misiones: personajes, preguntas, pausa y engranajes.
func _quests_tour() -> void:
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	var town := game.level as TownLevel
	var mila: Npc = town.get_node("Actores/Mila")
	var brasa: Npc = town.get_node("Actores/Brasa")
	game.player.place(mila.global_position + Vector2(0, 24), Vector2.UP)
	await _wait(0.8)
	await _shot("m0_mila")
	game.player.place(brasa.global_position + Vector2(0, 24), Vector2.UP)
	await _wait(0.8)
	await _shot("m1_brasa")
	game.talk_to(mila)
	await _wait(1.2)
	await _shot("m2_mila_habla")
	await _skip_dialog()
	await _wait(0.4)
	await _shot("m3_cuenta_mila")
	for i in 3:
		var quiz := game.machine.current as QuizState
		quiz.choose(int(quiz.quiz.answer))
		await _wait(0.6)
		if i == 0:
			await _shot("m4_cuenta_bien")
		await _wait(QuizState.RESULT_TIME)
	await _wait(0.6)
	await _shot("m5_mision_cumplida")
	await _skip_dialog()
	game.talk_to(brasa)
	await _skip_dialog()
	game.machine.change("pause")
	await _wait(0.6)
	await _shot("m6_pausa_misiones")
	game.machine.change("play")
	for key in game.data.practices.keys():
		game.practices_done[key] = true
	game.load_chamber(0)
	await _wait(0.6)
	game.dialog.close()
	var tuerca: Npc = game.level.get_node("Actores/Tuerca")
	game.player.place(tuerca.global_position + Vector2(0, 24), Vector2.UP)
	await _wait(0.8)
	await _shot("m7_tuerca")
	for i in 3:
		game.load_chamber(i)
		await _wait(0.6)
		game.dialog.close()
		var gear: GearPickup = game.level.nodes_of(GearPickup)[0]
		game.player.place(gear.global_position + Vector2(0, 30), Vector2.UP)
		await _wait(0.8)
		await _shot("m8_engranaje_%d" % i)


## Capítulo 2: llegada al Bosque, personajes, salas y jefe.
func _forest_tour() -> void:
	game.data.use_chapter(0)
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	game.load_chamber(4)
	await _wait(0.3)
	game.chapter_done()
	await _wait(1.6)
	await _shot("b0_llegada")
	await _skip_dialog()
	await _wait(0.6)
	await _shot("b1_bosque_inicio")
	var hub := game.level
	for n in ["Sauce", "Letrero", "Ramas", "Lia", "Hongo"]:
		var at: Vector2 = hub.get_node("Actores/" + n).global_position
		game.player.place(at + Vector2(0, 24), Vector2.UP)
		await _wait(0.7)
		await _shot("b2_" + n.to_lower())
	game.player.place(hub.get_node("Zonas/EntradaRuinas").global_position + Vector2(0, 70), Vector2.UP)
	await _wait(0.7)
	await _shot("b3_ruinas")
	game.quests.talk("ramas")
	await _skip_dialog()
	await _wait(0.4)
	await _shot("b4_pregunta_ramas")
	var quiz := game.machine.current as QuizState
	if quiz:
		quiz.choose(int(quiz.quiz.answer))
		await _wait(QuizState.RESULT_TIME + 0.4)
	game.machine.change("play")
	game.machine.change("pause")
	await _wait(0.5)
	await _shot("b5_pausa_bosque")
	game.skills.grant(3)
	game.skills.raise("vida")
	game.apply_skills()
	game.machine.change("skills")
	game.machine.current.handle_input(["ui_down"])
	await _shot("b5_habilidades")
	game.machine.change("pause")
	game.machine.change("play")
	var rooms := [["b6_puente", "peso = carreta.peso()\nif peso > 10:\n    puente.reforzar()\n"], ["b7_jardin", "agua = maceta.medir()\nif agua < 5:\n    maceta.regar()\nelse:\n    maceta.asolear()\n"]]
	for i in 2:
		game.load_chamber(i)
		await _wait(0.6)
		var lvl := game.level as RoundsLevel
		game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
		lvl._on_hall_entered()
		await _wait(1.0)
		await _shot(rooms[i][0] + "_intro")
		game.dialog.close()
		game.player.place(lvl.machine.global_position + Vector2(0, 40), Vector2.UP)
		game.open_codex(lvl.machine.session)
		while game.rig.is_gliding():
			await _wait(0.1)
		await _wait(0.4)
		await _shot(rooms[i][0] + "_codice")
		game.codex.write(rooms[i][1])
		game.machine.current.run()
		await _wait(1.0)
		await _shot(rooms[i][0] + "_ronda")
		await _wait(4.0)
		await _shot(rooms[i][0] + "_fin")
		game.dialog.close()
	game.load_chamber(2)
	await _wait(0.6)
	var throne := game.level as ThroneLevel
	await _wait(0.5)
	await _shot("b8_jefe_intro")
	game.dialog.close()
	throne._ask_question()
	await _wait(1.6)
	await _shot("b9_jefe_pregunta")

## El mundo unido y los capítulos 3 a 5: mapas, salas nuevas y jefes.
func _world_tour() -> void:
	game.machine.change("play", {"mode": "new"})
	await _wait(0.5)
	game.dialog.close()
	# Vuelta del templo: las rocas del este se deshacen
	game.load_chamber(4)
	await _wait(0.3)
	game.chapter_done()
	await _wait(2.2)
	await _shot("w00_rocas_se_abren")
	await _skip_dialog()
	await _wait(1.2)
	await _shot("w01_raiz_camino_este")
	var maps := ["bosque", "cueva", "mirador", "cima"]
	game.reached = 4
	for i in maps.size():
		game.go_to_map(maps[i], "Oeste")
		await _wait(1.4)
		await _shot("w1%d_%s_llegada" % [i, maps[i]])
		game.player.place(game.level.get_node("Entradas/Puerta").global_position + Vector2(-40, 120), Vector2.UP)
		await _wait(0.8)
		await _shot("w1%d_%s_centro" % [i, maps[i]])
		for npc in game.level.nodes_of(Npc):
			game.player.place(npc.global_position + Vector2(0, 26), Vector2.UP)
			await _wait(0.6)
			await _shot("w1%d_%s_%s" % [i, maps[i], String(npc.name).to_lower()])
	game.reached = 2
	game.load_map("cueva", "Este")
	await _wait(0.6)
	await _shot("w20_cueva_rocas_cerradas")
	game.player.place(game.level.get_node("Actores/Rocas3").global_position + Vector2(-34, 0), Vector2.RIGHT)
	await _wait(0.5)
	await _shot("w21_cueva_mirar_rocas")
	game.reached = 4
	game.load_map("mirador", "Oeste")
	game.player.place(game.level.get_node("Zonas/Balcon").global_position + Vector2(0, -30), Vector2.DOWN)
	await _wait(0.3)
	game.level.call("_show_view")
	await _wait(1.8)
	await _shot("w22_mirador_valle")
	await _skip_dialog()
	# Salas nuevas
	var rooms := [
		[2, 0, "w30_bomba", "while tanque.nivel() < 10:\n    bomba.bombear()\n"],
		[3, 0, "w31_molino", "def moler(sacos):\n    return sacos * 3\n"],
		[4, 0, "w32_campanas", "notas = partitura.leer()\nfor n in notas:\n    campana.tocar(n)\n"],
		[4, 1, "w33_balanza", "total = 0\nfor p in pesas.lista():\n    total = total + p\nbalanza.poner(total)\n"],
		[4, 2, "w34_gemelas", "def factorizar(b, c):\n    for p in range(-10, 11):\n        q = b - p\n        if p * q == c:\n            return [p, q]\n"],
	]
	for r in rooms:
		game.data.use_chapter(r[0])
		game.practices_done["funciones"] = true
		game.load_chamber(r[1])
		await _wait(0.6)
		var lvl := game.level as RoundsLevel
		game.player.place(lvl.get_node("Zonas/EntradaSala").point(), Vector2.UP)
		lvl._on_hall_entered()
		await _wait(1.0)
		await _shot(r[2] + "_intro")
		game.dialog.close()
		game.player.place(lvl.machine.global_position + Vector2(0, 40), Vector2.UP)
		game.open_codex(lvl.machine.session)
		while game.rig.is_gliding():
			await _wait(0.1)
		await _wait(0.4)
		await _shot(r[2] + "_codice")
		_arm(r[3])
		await _wait(0.3)
		await _shot(r[2] + "_bloques")
		game.codex.write(r[3])
		game.machine.current.run()
		await _wait(1.0)
		await _shot(r[2] + "_ronda")
		await _wait(4.0)
		await _shot(r[2] + "_fin")
		game.dialog.close()
		game.machine.change("play")
	# Jefes nuevos y sus preguntas
	for b in [[2, "w40_cueva"], [3, "w41_ruinas"], [4, "w42_cima"]]:
		game.data.use_chapter(b[0])
		game.load_chamber(game.data.chamber_count() - 1)
		await _wait(0.6)
		var throne := game.level as ThroneLevel
		game.player.place(throne.get_node("Zonas/EntradaSala").point(), Vector2.UP)
		throne._on_hall_entered()
		await _wait(1.4)
		await _shot(b[1] + "_jefe")
		await _skip_dialog()
		for phase in 3:
			throne.boss.phase = phase + 1
			throne._ask_question()
			await _wait(1.6)
			await _shot("%s_pregunta%d" % [b[1], phase + 1])
			var quiz := game.machine.current as QuizState
			if quiz:
				quiz.choose(int(quiz.quiz.answer))
				await _wait(QuizState.RESULT_TIME + 0.4)
			game.machine.change("play")
	game.reached = 4
	game.chapter_done()
	await _wait(2.5)
	await _shot("w50_final")
