## Nodo principal: crea los servicios, carga los niveles y delega en el estado actual.
class_name Game
extends Node2D

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "run", "jump", "interact", "book", "pause", "accept", "cancel", "ui_up", "ui_down", "ui_left", "ui_right", "fullscreen", "run_code", "attack", "flag", "rotate"]

## Primer nivel. Las salas las crean sus fábricas.
@export var town_scene: PackedScene

var data: DataRepository
var bus: EventBus
var audio: AudioService
var settings: SettingsRepository
var saves: SaveRepository
var timer: CountdownTimer
var health: PlayerHealth
var dialog: DialogBox
var machine: StateMachine
var ui: UIKit
var kit: TileKit
var level: Level
var quality: QualityProfile
var chamber_index := -1
var show_fps := true
var notices := NoticeBoard.new()
var fade: ScreenFade
var rules: LifeRules
var challenge_seed := 0          # semilla de los ejercicios de la partida
var fixed_challenges := false    # pruebas: siempre la primera variante
var online: OnlineSession
var in_online_match := false     # jugando una partida del admin
var touch: TouchControls         # controles en pantalla (Android); null con teclado
var screen_locked := false       # en línea: pantalla completa obligada (solo PC)

# Contadores de la partida, para la clasificación final
var match_errors := 0            # errores: máquina, mina, losa o reto de teclas
var match_hits := 0              # veces que Tala recibió daño
var match_kills := 0             # guardianes derrotados
var match_outs := 0              # veces que salió del juego (Alt+Tab) en línea

var _rules_override: Dictionary = {}    # castigos que eligió el admin

var _observers: Array = []
var _tool: RefCounted
var _secret: SecretCodeDetector
var _changing := false    # evita dos cambios de sala a la vez
var _bbcode := RegEx.create_from_string("\\[/?[a-z]+(=[^\\]]*)?\\]")

@onready var rig: CameraRig = $Camara
@onready var player: PlayerController = $Tala
@onready var codex: CodexPanel = $Interfaz/Codice
@onready var overlay: OverlayCanvas = $Interfaz/Pantalla


func _ready() -> void:
	data = DataRepository.new()
	InputSetup.register(data.setting("controls", {}))
	InputSetup.mouse_names = data.texts.get("mouse_names", {})
	bus = EventBus.new()
	audio = AudioService.new(self)
	saves = SaveRepository.new()
	timer = CountdownTimer.new(bus, float(data.setting("time_limit_sec", 900)), float(data.setting("time_warning_sec", 60)))
	kit = TileKit.new()
	health = PlayerHealth.new(bus, int(combat("hearts", 5)))
	rig.base_zoom = float(data.setting("zoom", 3))
	overlay.painter = _draw_ui
	codex.text = data.message
	ui = UIKit.new(overlay)
	dialog = DialogBox.new(bus, ui)
	_secret = SecretCodeDetector.new(String(data.setting("secret_code", "")))
	settings = SettingsRepository.new(data.setting("default_settings", {}), audio)
	quality = QualityProfile.create(settings.get_int("quality"), data.setting("quality_presets", {}))
	player.setup(bus, data.setting("movement", {}))
	player.health = health
	player.apply_combat(data.setting("combat", {}))
	_observers = [
		SoundObserver.new(bus, audio, data.setting("sounds", {})),
		CameraShakeObserver.new(bus, rig, data.setting("camera_shake", {})),
	]
	bus.subscribe(GameEvents.TIME_UP, func(_p): finish(false))
	for event in [GameEvents.MACHINE_FAILED, GameEvents.MINE_EXPLODED, GameEvents.SLAB_COLLAPSED, GameEvents.KEYS_LOST]:
		bus.subscribe(event, func(_p): match_errors += 1)
	bus.subscribe(GameEvents.PLAYER_HURT, func(_p): match_hits += 1)
	bus.subscribe(GameEvents.GUARDIAN_DEFEATED, func(_p): match_kills += 1)
	fade = ScreenFade.new(get_tree())
	rules = LifeRules.new(self)
	online = OnlineSession.new(String(data.setting("server_url", "")))
	_wire_online()
	machine = _create_states()
	if TouchControls.wanted():
		touch = TouchControls.new(self)
		$Interfaz.add_child(touch)
	load_level(town_scene.instantiate())
	settings.applied.connect(_apply_settings)
	settings.apply()
	machine.change("title")
	_run_tools_from_command_line()


func _create_states() -> StateMachine:
	var m := StateMachine.new()
	m.add("title", TitleState.new(self))
	m.add("menu", MenuState.new(self))
	m.add("intro", IntroState.new(self))
	m.add("play", PlayState.new(self))
	m.add("pause", PauseState.new(self))
	m.add("settings", SettingsState.new(self))
	m.add("credits", CreditsState.new(self))
	m.add("codex", CodexState.new(self))
	m.add("end", EndState.new(self))
	m.add("book", BookState.new(self))
	m.add("keys", KeyChallengeState.new(self))
	m.add("puzzle", PuzzleState.new(self))
	m.add("quiz", QuizState.new(self))
	m.add("online", OnlineState.new(self))
	m.add("lobby", LobbyState.new(self))
	m.add("admin", AdminState.new(self))
	m.add("watch", WatchState.new(self))
	m.add("ranking", RankingState.new(self))
	return m


func _process(delta: float) -> void:
	ui.time += delta
	notices.tick(delta)
	fade.tick(delta)
	online.poll(delta)
	var held := admin_paused()
	if machine.current.timer_runs() and not held:
		timer.tick(delta)
	if level:
		# En pausa se detiene todo el nivel
		level.process_mode = Node.PROCESS_MODE_DISABLED if machine.current.freezes_world() or held else Node.PROCESS_MODE_INHERIT
	if not held:
		machine.current.update(delta)
	if in_online_match and player.is_inside_tree():
		# El estado se arma solo cuando toca mandarlo (recorre los enemigos)
		if online.state_due(delta):
			online.send_state(net_state())
		if machine.current_name == "codex" and online.code_due(delta):
			online.report_code(codex_state())
	overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if admin_paused() or (touch and touch.typing()):
		return
	if event is InputEventMouse and machine.current.handle_mouse(event):
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and machine.current.handle_key(event):
		return
	if event is InputEventKey and _secret.feed(event.unicode):
		bus.publish(GameEvents.GUIDE_TOGGLED)
	var actions: Array = []
	for action in ACTIONS:
		if event.is_action_pressed(action):
			actions.append(action)
	if "fullscreen" in actions:
		if screen_locked:
			notify([data.message("net_screen_locked")], 3.0)
			return
		settings.set_value("full", not settings.get_bool("full"))
		settings.save()
		return
	if not actions.is_empty():
		machine.current.handle_input(actions)


func _draw_ui() -> void:
	machine.current.draw(ui)
	if admin_paused():
		ui.dim(0.55)
		ui.text_centered(data.message("net_admin_paused"), ui.size().y * 0.4, 56, UIKit.GOLD, "title")
		ui.text_centered(data.message("net_admin_paused_sub"), ui.size().y * 0.4 + 76, 24, UIKit.TEXT)
	if fade.amount > 0.0:
		ui.rect(Rect2(Vector2.ZERO, ui.size()), Color(0, 0, 0, fade.amount))


func _apply_settings() -> void:
	var new_quality := QualityProfile.create(settings.get_int("quality"), data.setting("quality_presets", {}))
	if new_quality.id() != quality.id():
		bus.publish(GameEvents.QUALITY_CHANGED, {"quality": new_quality.id()})
	quality = new_quality
	kit.particle_scale = quality.particle_scale()
	if level:
		level.apply_quality(quality)


# ---------------------------------------------------------------- niveles

func load_level(new_level: Level) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	if level:
		# Se saca del árbol para que sus áreas ya no detecten a Tala
		remove_child(level)
		level.queue_free()
	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	level = new_level
	add_child(level)
	level.setup(self, kit)
	player.place(level.spawn, level.spawn_facing)
	level.actors.add_child(player)
	player.set_lamp(level.dark)
	level.apply_quality(quality)
	_set_camera_limits()
	player.place(level.spawn, level.spawn_facing)
	rig.follow(player)
	bus.publish(GameEvents.LEVEL_LOADED)


func _set_camera_limits() -> void:
	var b := level.bounds
	rig.set_bounds(Rect2i(b.position * TileKit.TILE, b.size * TileKit.TILE))


## Pasa a otra sala con un fundido.
func enter_chamber(index: int) -> void:
	if index >= data.chamber_count() or _changing:
		return
	_changing = true
	await fade_out()
	load_chamber(index)
	_changing = false
	bus.publish(GameEvents.CHAMBER_ENTERED, {"index": index, "name": place_title()})
	fade_in()


## Tala entra al templo: empieza el reloj y va a la Sala 1.
func enter_temple() -> void:
	if chamber_index >= 0:
		return
	timer.reset()
	timer.start()
	bus.publish(GameEvents.TEMPLE_ENTERED)
	await enter_chamber(0)
	var minutes := {"min": roundi(timer.limit / 60.0)}
	notify(data.messages("temple_start").map(func(line): return String(line).format(minutes)), 6.0)


## Carga una sala sin fundido.
func load_chamber(index: int) -> void:
	var chamber := ChamberRegistry.create(data.chamber_data(index))
	chamber.index = index
	chamber_index = index
	load_level(chamber)
	play_music(chamber.music_key)


## Solo el pueblo de fondo (menús en línea, panel del admin).
func show_town() -> void:
	chamber_index = -1
	load_level(town_scene.instantiate())
	show_title_shot()


## Espectador: la sala de otro jugador, con sus ejercicios, y sin Tala.
func load_watch_level(index: int, seed_value: int) -> void:
	if seed_value != 0:
		data.roll_challenges(seed_value)
	if index < 0 or index >= data.chamber_count():
		show_town()
	else:
		load_chamber(index)
	player.visible = false
	player.controls_enabled = false
	# Fuera de la física: la sala del espectador se mueve, pero Tala no pisa nada
	player.process_mode = Node.PROCESS_MODE_DISABLED


func show_title_shot() -> void:
	player.controls_enabled = false
	rig.frame(level.title_point(), 1.0, 0.01)


func follow_player() -> void:
	rig.follow(player)


func place_title() -> String:
	if chamber_index < 0:
		return data.message("pause_town")
	return String(data.chamber_data(chamber_index).get("name", ""))


func key_names() -> Dictionary:
	var out := {}
	for action in ACTIONS:
		out[action] = InputSetup.key_name(action)
	return out


func text_speed() -> float:
	return float(data.setting("text_speeds", [50])[settings.get_int("text")])


func play_music(key: String) -> void:
	audio.play_music(String(data.setting("music", {}).get(key, "")))


func fade_in() -> void:
	fade.fade_in()


func fade_out() -> void:
	await fade.fade_out()


func talk(key: String) -> void:
	dialog.say(data.talk(key))


## Aviso arriba de la pantalla.
func notify(lines: Array, seconds := 5.0, good := false) -> void:
	notices.notify(lines, seconds, good)


## seed_value: la semilla de los ejercicios (0: una nueva al azar).
func start_new_game(seed_value := 0) -> void:
	challenge_seed = seed_value if seed_value != 0 else randi_range(1, 2147483646)
	data.roll_challenges(challenge_seed, fixed_challenges)
	match_errors = 0
	match_hits = 0
	match_kills = 0
	match_outs = 0
	timer.reset()
	health.refill()
	Engine.time_scale = 1.0
	dialog.close()
	chamber_index = -1
	load_level(town_scene.instantiate())
	play_music(level.music_key)
	fade_in()


func open_codex(session: CodexSession) -> void:
	bus.publish(GameEvents.MENU_CONFIRM)
	machine.change("codex", {"session": session})


func save_game() -> void:
	var room := level.save_state()
	saves.save({"chamber": chamber_index, "time_left": timer.remaining, "hearts": health.halves, "room": room, "seed": challenge_seed})


func load_game() -> void:
	var snap := saves.load_snapshot()
	start_new_game(int(snap.get("seed", 0)))
	var index := int(snap.get("chamber", -1))
	if index >= 0 and index < data.chamber_count():
		load_chamber(index)
		level.resume_from_save(snap.get("room", {}))
		timer.start()
	timer.remaining = float(snap.get("time_left", timer.limit))
	health.halves = clampi(int(snap.get("hearts", health.max_halves)), 1, health.max_halves)


## Fin de la partida. ending es la clave del texto final.
func finish(won: bool, ending := "") -> void:
	timer.stop()
	Engine.time_scale = 1.0
	dialog.close()
	if in_online_match:
		in_online_match = false
		unlock_screen()
		online.report(1.0, net_state())
		online.report_done(won, timer.elapsed())
	machine.change("end", {"won": won, "ending": ending})


# ---------------------------------------------------------------- vidas y castigos de tiempo

## Valor de "combat" en config.json.
func combat(key: String, fallback):
	if _rules_override.has(key):
		return _rules_override[key]
	return (data.setting("combat", {}) as Dictionary).get(key, fallback)


## Resta segundos al reloj.
func penalize(seconds: float) -> void:
	rules.penalize(seconds)


# ---------------------------------------------------------------- en línea

## Tiempo, corazones y castigos de la partida. {}: los de config.json.
func apply_match_rules(config: Dictionary) -> void:
	_rules_override = {}
	timer.limit = float(data.setting("time_limit_sec", 900))
	var hearts := int(combat("hearts", 5))
	if not config.is_empty():
		timer.limit = float(config.get("time_min", 15)) * 60.0
		hearts = int(config.get("hearts", hearts))
		_rules_override = {
			"fall_penalty_sec": float(config.get("fall_penalty", 7)),
			"death_penalty_sec": float(config.get("death_penalty", 60)),
		}
	health.max_halves = hearts * 2
	health.refill()


## ¿El admin detuvo la partida?
func admin_paused() -> bool:
	return in_online_match and online.paused


## Lo que ve el espectador de este jugador.
func net_state() -> Dictionary:
	var pose := player.pose()
	var room := level as ChamberLevel
	var town := level as TownLevel
	return {
		"t": Time.get_ticks_msec(),    # para que el espectador interpole sin saltos
		"c": chamber_index,
		"x": roundi(player.global_position.x),
		"y": roundi(player.global_position.y),
		"a": pose.a,
		"hop": snappedf(pose.hop, 0.1),
		"h": health.halves,
		"mh": health.max_halves,
		"tl": roundi(timer.remaining),
		"er": match_errors,
		"ht": match_hits,
		"ks": match_kills,
		"out": match_outs,
		"sd": challenge_seed,
		"ok": (room != null and room.solved) or (town != null and town.gate.is_solved),
		"m": machine.current_name,    # qué está haciendo (play, codex, puzzle, quiz…)
		"w": WorldSync.capture(level),    # enemigos, jefe y orbes
	}


## Lo que el espectador ve del Códice de este jugador.
func codex_state() -> Dictionary:
	var lines: Array = []
	var log: Array = codex.session_log()
	for line in log.slice(maxi(0, log.size() - 6)):
		# [lb] es un "[" escrito por el jugador
		var parts := Array(String(line).split("[lb]")).map(func(part): return _bbcode.sub(part, "", true))
		lines.append("[".join(parts).strip_edges())
	return {
		"title": codex.title_label.text,
		"src": codex.editor.text,
		"row": codex.editor.get_caret_line(),
		"log": lines,
	}


## Vuelve a una partida en línea que había dejado: misma sala, corazones y reloj.
func resume_online_match(resume: Dictionary) -> void:
	var index := int(resume.get("c", -1))
	if index < 0 or index >= data.chamber_count():
		return
	load_chamber(index)
	if bool(resume.get("ok", false)):
		level.resume_from_save({"solved": true})
	timer.start()
	timer.remaining = maxf(1.0, float(resume.get("tl", timer.limit)))
	if resume.has("h"):
		health.halves = clampi(int(resume.h), 1, health.max_halves)
	# Los contadores de la clasificación siguen donde iban
	match_errors = int(resume.get("er", 0))
	match_hits = int(resume.get("ht", 0))
	match_kills = int(resume.get("ks", 0))
	match_outs = int(resume.get("out", 0))
	notify([data.message("net_resumed", {"room": place_title(), "time": CountdownTimer.format(timer.remaining)})], 6.0, true)


## El jugador deja la partida en línea (pausa → salir).
func leave_online_match() -> void:
	in_online_match = false
	unlock_screen()
	timer.stop()
	online.leave()
	apply_match_rules({})


## En línea el juego queda en pantalla completa y no se puede quitar (solo PC).
## La idea es que nadie busque las respuestas en otra ventana.
func lock_screen() -> void:
	if touch != null or DisplayServer.get_name() == "headless":
		return
	screen_locked = true
	settings.window_locked = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Al terminar vuelve la ventana que el jugador tenía en sus ajustes.
func unlock_screen() -> void:
	if not screen_locked:
		return
	screen_locked = false
	settings.window_locked = false
	settings.apply()


## Salió del juego (Alt+Tab, otra ventana): se cuenta y el admin lo ve.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and in_online_match and touch == null:
		match_outs += 1
		notify([data.message("net_out_warn")], 4.0)


func _wire_online() -> void:
	online.room_ready.connect(func(): machine.change("admin" if online.is_admin() else "lobby"))
	online.match_started.connect(_on_match_started)
	online.finished.connect(_on_rejoined_finished)
	online.time_added.connect(_on_time_added)
	online.paused_changed.connect(func(_on): bus.publish(GameEvents.MENU_CONFIRM))
	online.match_ended.connect(_on_match_ended)
	online.room_reset.connect(_on_room_reset)
	online.kicked.connect(func(): _drop_online("net_kicked"))
	online.failed.connect(_on_online_failed)
	online.connection_lost.connect(func(): notify([data.message("net_lost")], 4.0))


func _on_time_added(seconds: int) -> void:
	if not in_online_match:
		return
	timer.remaining = maxf(1.0, timer.remaining + seconds)
	timer.limit += seconds
	notify([data.message("net_time_added", {"s": seconds})], 3.0, true)


## El admin terminó la partida: todos pasan a la clasificación final.
func _on_match_ended() -> void:
	if in_online_match:
		finish(false, "ending_match_over")
	elif online.active() and machine.current_name in ["watch", "admin"]:
		machine.change("ranking")


## Otra partida en la misma sala: de vuelta a la espera.
func _on_room_reset() -> void:
	if online.is_player() and not in_online_match:
		apply_match_rules({})
		machine.change("lobby")


func _on_online_failed(key: String) -> void:
	if machine.current_name != "online":
		notify([data.message(key)], 4.0)
	if not online.active() and machine.current_name in ["lobby", "admin", "watch"]:
		_drop_online("")


func _on_match_started(seed_value: int, config: Dictionary, resume: Dictionary = {}) -> void:
	if not online.is_player():
		return
	apply_match_rules(config)
	in_online_match = true
	lock_screen()
	machine.change("play", {"mode": "online", "seed": seed_value, "skip_town": bool(config.get("skip_town", false)), "resume": resume})


## Volvió a la sala pero ya había terminado (o se le acabó el tiempo afuera): a mirar.
func _on_rejoined_finished() -> void:
	in_online_match = false
	apply_match_rules(online.config)
	machine.change("ranking" if online.phase == "ended" else "watch")


## Se acabó lo en línea (expulsado, sala cerrada): al título.
func _drop_online(message_key: String) -> void:
	in_online_match = false
	unlock_screen()
	timer.stop()
	apply_match_rules({})
	machine.change("title")
	if message_key != "":
		notify([data.message(message_key)], 5.0)


# ---------------------------------------------------------------- herramientas de prueba

func _run_tools_from_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recorrido="):
			_tool = RouteTour.new(self)
			_tool.run(arg.substr(12))
		elif arg.begins_with("--nettest="):
			_tool = NetTest.new(self)
			_tool.run(arg.substr(10))
		elif arg == "--selftest":
			_tool = SelfTest.new(self)
			_tool.run()
