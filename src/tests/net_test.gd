## Pruebas en línea contra un servidor de verdad (server/):
##   node server/server.js   y luego   Godot --headless --path . -- --nettest=ws://127.0.0.1:8080
## Con ",carpeta" al final (y sin --headless) guarda capturas de las pantallas.
## El juego hace de jugador y después de admin; otra OnlineSession hace el otro papel.
class_name NetTest
extends RefCounted

var game: Game
var _failures := 0
var _other: OnlineSession
var _shots := ""


func _init(context: Game) -> void:
	game = context


func run(arg: String) -> void:
	var url := arg.get_slice(",", 0)
	_shots = arg.get_slice(",", 1) if "," in arg else ""
	if _shots != "":
		DirAccess.make_dir_recursive_absolute(_shots)
	game.fixed_challenges = true
	await _wait_frames(5)
	await _as_player(url)
	await _as_admin(url)
	print("NETTEST ", "OK" if _failures == 0 else "FALLO (%d)" % _failures)
	game.get_tree().quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	print(("  ok   " if condition else "  FALLO ") + label)
	if not condition:
		_failures += 1


func _wait_frames(n: int) -> void:
	for i in n:
		await game.get_tree().process_frame


## Espera a que done() sea true, revisando también la otra sesión.
func _until(done: Callable, limit := 5.0) -> bool:
	var t := 0.0
	while not done.call() and t < limit:
		await game.get_tree().process_frame
		var delta := game.get_process_delta_time()
		if _other:
			_other.poll(delta)
		t += delta
	return done.call()


func _shot(shot_name: String) -> void:
	if _shots == "":
		return
	await _until(func(): return false, 0.4)
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(_shots.path_join(shot_name + ".png"))


func _press(action: String) -> void:
	game.machine.current.handle_input([action])


# ------------------------------------------------------------------ el juego es jugador

func _as_player(url: String) -> void:
	_other = OnlineSession.new(url)
	_other.create_room(url)
	_check(await _until(func(): return _other.code != ""), "Admin: crea la sala y recibe el código")
	game.machine.change("online")
	await _shot("1_en_linea")
	game.online.join_room(url, _other.code, "Prueba")
	_check(await _until(func(): return game.machine.current_name == "lobby"), "Jugador: con EN LÍNEA → UNIRSE entra a la sala de espera")
	_check(await _until(func(): return _other.players.size() == 1), "Admin: ve al jugador en la lista")
	_other.send_config({"time_min": 7, "hearts": 3, "fall_penalty": 9, "death_penalty": 30, "max_players": 30, "same_exercises": true, "spectate": true, "skip_town": true})
	await _until(func(): return int(game.online.config.get("time_min", 0)) == 7)
	await _shot("2_sala_de_espera")
	_other.start_match()
	_check(await _until(func(): return game.in_online_match and game.chamber_index == 0, 8.0), "Inicio: el jugador empieza directo en el templo (Sala 1)")
	_check(is_equal_approx(game.timer.limit, 420.0) and game.health.max_halves == 6, "Inicio: el tiempo (7 min) y los corazones (3) son los del admin")
	_check(is_equal_approx(float(game.combat("fall_penalty_sec", 0)), 9.0), "Inicio: el castigo por caída es el del admin")
	var me := game.online.my_id
	_check(await _until(func(): return String(_other.player(me).get("status", "")) == "playing" and int(_other.player(me).get("chamber", -9)) == 0), "Tablero: el admin ve que el jugador va en la Sala 1")
	_other.watch(me)
	_check(await _until(func(): return _other.snaps.has(me)), "En vivo: al admin le llegan las posiciones del jugador")
	_check(int(_other.snaps[me].get("sd", 0)) == game.challenge_seed, "En vivo: el espectador recibe la semilla de los ejercicios")
	_other.set_paused(true)
	await _until(func(): return game.admin_paused())
	var before := game.timer.remaining
	await _until(func(): return false, 0.5)
	_check(game.admin_paused() and is_equal_approx(game.timer.remaining, before), "Pausa del admin: el reloj del jugador no avanza")
	await _shot("3_pausa_del_admin")
	_other.set_paused(false)
	await _until(func(): return not game.admin_paused())
	before = game.timer.remaining
	_other.add_time(60)
	_check(await _until(func(): return game.timer.remaining > before + 50.0), "Admin: +1 minuto llega al reloj del jugador")
	game.machine.change("pause")
	var t0 := game.timer.remaining
	await _until(func(): return false, 0.4)
	_check(game.timer.remaining < t0, "En línea: la pausa del jugador no detiene el reloj")
	game.machine.change("play")
	game.finish(false)
	_check(await _until(func(): return String(_other.player(me).get("status", "")) == "lost"), "Fin: el admin ve que el jugador perdió")
	await _until(func(): return false, 1.7)
	_press("accept")
	_check(game.machine.current_name == "watch", "Fin: al perder, Enter lleva a mirar a los demás")
	await _shot("4_espectador_sin_nadie")
	_other.end_match()
	_check(await _until(func(): return game.online.phase == "ended"), "Admin: termina la partida y el jugador ve la clasificación final")
	_other.reset_room()
	_check(await _until(func(): return game.machine.current_name == "lobby"), "Otra partida: el jugador vuelve a la sala de espera")
	_other.kick(me)
	_check(await _until(func(): return game.machine.current_name == "title" and not game.online.active()), "Admin: al sacarlo, el jugador vuelve al título")
	_other.close_room()
	_other = null


# ------------------------------------------------------------------ el juego es admin

func _as_admin(url: String) -> void:
	game.machine.change("online")
	game.online.create_room(url)
	_check(await _until(func(): return game.machine.current_name == "admin"), "Admin: CREAR SALA abre el panel del admin")
	_other = OnlineSession.new(url)
	_other.join_room(url, game.online.code, "Lupe")
	_check(await _until(func(): return game.online.players.size() == 1), "Panel: aparece el jugador que entró")
	var admin := game.machine.current as AdminState
	# Sube el tiempo con la flecha derecha (primera fila: TIEMPO)
	var time_before := int(game.online.config.get("time_min", 15))
	_press("ui_right")
	_check(await _until(func(): return int(game.online.config.get("time_min", 0)) == time_before + 1), "Panel: con → cambia el tiempo de la partida")
	await _shot("5_panel_admin_espera")
	var seed_got := [0]
	_other.match_started.connect(func(seed_value, _config): seed_got[0] = seed_value)
	admin._do("start")
	_check(await _until(func(): return seed_got[0] != 0), "Panel: INICIAR PARTIDA empieza la partida del jugador")
	var lupe := _other.my_id
	var room_seed: int = seed_got[0]
	var picks := ChallengeDeck.roll(game.data.chambers, room_seed)
	var spot := Level.cell_center(Vector2i(12, 10))
	var send_state := func(): _other.report(1.0, {"c": 1, "x": spot.x, "y": spot.y, "a": "walk_up", "hop": 0, "h": 7, "mh": 10, "tl": 400, "sd": room_seed, "ok": false})
	send_state.call()
	_check(await _until(func(): return int(game.online.player(lupe).get("chamber", -1)) == 1), "Panel: el tablero muestra que Lupe va en la Sala 2")
	await _shot("6_panel_admin_partida")
	_press("book")
	_press("accept")
	for i in 40:
		send_state.call()
		if await _until(func(): return game.level is RootsLevel and admin.view.ghost != null, 0.15):
			break
	_check(game.level is RootsLevel and is_instance_valid(admin.view.ghost), "En vivo: el admin ve la Sala 2 de Lupe con su personaje")
	_check(String(game.level.data.get("form", "")) == String(picks[1].get("form", "")), "En vivo: el Mural tiene las mismas ecuaciones (variante) que el de Lupe")
	_check(not game.player.visible and admin.view.ghost.position.distance_to(spot) < 2.0, "En vivo: Tala está escondida y el fantasma está donde está Lupe")
	for i in 6:
		send_state.call()
		await _until(func(): return false, 0.1)
	await _shot("7_admin_en_vivo")
	_press("cancel")
	_check(game.level is TownLevel, "En vivo: al volver al panel se ve el pueblo de fondo")
	admin._do("end")
	await _until(func(): return game.online.phase == "ended")
	admin._do("close")
	_check(game.machine.current_name == "title" and not game.online.active(), "Panel: CERRAR SALA vuelve al título")
	_check(await _until(func(): return not _other.active()), "Panel: al cerrar la sala el jugador sale")
	_other = null
