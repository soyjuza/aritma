## Capturas del camino real en 2D (necesita ventana):
##   Godot --path . -- --recorrido=/ruta/carpeta
class_name RouteTour
extends RefCounted

var game: Game
var folder := ""


func _init(context: Game) -> void:
	game = context


func run(arg: String) -> void:
	var parts := arg.split(":")
	folder = parts[0]
	DirAccess.make_dir_recursive_absolute(folder)
	game.set_process_unhandled_input(false)
	if parts.size() > 1 and parts[1] == "sala2":
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(1)
		game.timer.start()
		await _roots_room()
		game.get_tree().quit()
		return
	var rooms := {"sala3": [2, _vortex_room], "sala4": [3, _figures_room], "sala5": [4, _path_room]}
	if parts.size() > 1 and rooms.has(parts[1]):
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(rooms[parts[1]][0])
		game.timer.start()
		await rooms[parts[1]][1].call()
		game.get_tree().quit()
		return
	if parts.size() > 1 and parts[1] == "jefe":
		game.machine.change("play", {"mode": "new"})
		await _wait(0.5)
		game.dialog.close()
		game.load_chamber(5)
		game.timer.start()
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
	game.codex.editor.text = "puerta.abrir()\n"
	await _shot("05_codice_puerta")
	game.machine.current.run()
	await _wait(2.0)
	game.dialog.close()
	await _shot("06_puerta_abierta")
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
	game.codex.editor.text = "while tolva.quedan() > 0:\n    n = tolva.soltar()\n    if n % 2 == 0:\n        caliz.recibir()\n    else:\n        crisol.desintegrar()\n"
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


## La Sala 2 por dentro: prensas, sala, Mural, Códice y el Mural trabajando.
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
	game.codex.editor.text = "def despejar(a, b, c):\n    return (c - b) / a\n"
	await _shot("24_codice_mural")
	game.machine.current.run()
	await _wait(1.6)
	await _shot("25_mural_trabajando")
	while not lvl.machine.is_solved:
		await _wait(0.3)
	await _wait(1.0)
	await _shot("26_mural_resuelto")


## La Sala 3: el Faro apagado, el Códice con luces.encender() y la sala encendida.
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
	game.codex.editor.text = "luces.encender(\n"
	game.machine.current.run()
	game.machine.change("play")
	game.open_codex(lvl.machine.session)
	await _wait(0.6)
	await _shot("31a_error_conservado")
	game.codex.editor.text = lvl.machine.session.code + "luces.encender()\n"
	await _shot("31_codice_luces")
	game.machine.current.run()
	await _wait(2.5)
	await _shot("32_faro_encendido")
	game.dialog.close()
	game.player.place(lvl.board.cell_center(Vector2i(3, 6)), Vector2.UP)
	await _wait(1.0)
	await _shot("33_tablero_encendido")
	# Lo limpia como una persona: parada en cada baldosa segura, E
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


## La Sala 4: la Mesa en la sala, el rompecabezas vacío, a medias, lleno y la segunda figura.
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
	# La segunda figura llega con las piezas giradas: se giran hasta quedar como en el dibujo
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


## La Sala 5: el sendero con la regla, una losa rota y Tala cruzando hasta el núcleo.
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


## El jefe final (Sala 6): el pasillo, la entrada a la sala y cada parte de la pelea.
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
