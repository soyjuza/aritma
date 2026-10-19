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
	game.codex.editor.text = "def factorizar(b, c):\n    for p in range(-abs(c), abs(c) + 1):\n        q = b - p\n        if p * q == c:\n            return [p, q]\n"
	await _shot("24_codice_mural")
	game.machine.current.run()
	await _wait(1.6)
	await _shot("25_mural_trabajando")
	while not lvl.machine.is_solved:
		await _wait(0.3)
	await _wait(1.0)
	await _shot("26_mural_resuelto")


func _wait(seconds: float) -> void:
	await game.get_tree().create_timer(seconds, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(folder.path_join(name + ".png"))
	print("recorrido ", name)
