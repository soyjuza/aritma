## Raíz de composición del juego (contexto del patrón State). Es el nodo «Main» de main.tscn,
## que ya trae a la cámara, a Tala y la interfaz como nodos hijos. Crea los servicios,
## registra los controles, carga los niveles (escenas), aplica el perfil de efectos, conecta
## los observadores y delega cada fotograma en el estado actual. No contiene reglas del juego.
class_name Game
extends Node2D

const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "run", "jump", "interact", "book", "pause", "accept", "cancel", "ui_up", "ui_down", "ui_left", "ui_right", "fullscreen", "run_code", "attack", "flag", "rotate"]

## La escena del pueblo (el primer nivel). Las salas las crean sus fábricas (ChamberRegistry).
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
var notice := ""
var notice_left := 0.0
var notice_good := false     # true: buena noticia (franja verde y más grande)
var penalty_text := ""        # "−7 s" que flota junto al reloj tras una caída
var penalty_left := 0.0

var _observers: Array = []
var _tool: RefCounted
var _secret: SecretCodeDetector
var _fade := 0.0
var _fade_dir := 0.0
var _changing := false        # cambiando de sala: no se empieza otro cambio

@onready var rig: CameraRig = $Camara
@onready var player: PlayerController = $Tala
@onready var codex: CodexPanel = $Interfaz/Codice
@onready var overlay: OverlayCanvas = $Interfaz/Pantalla


func _ready() -> void:
	data = DataRepository.new()
	InputSetup.register(data.setting("controls", {}))
	bus = EventBus.new()
	audio = AudioService.new(self)
	saves = SaveRepository.new()
	timer = CountdownTimer.new(bus, float(data.setting("time_limit_sec", 900)), float(data.setting("time_warning_sec", 60)))
	kit = TileKit.new()
	health = PlayerHealth.new(bus, int(combat("hearts", 5)))
	rig.base_zoom = float(data.setting("zoom", 3))
	overlay.painter = _draw_ui
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
	bus.subscribe(GameEvents.PLAYER_DIED, func(_p): _on_player_died())
	machine = _create_states()
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
	return m


func _process(delta: float) -> void:
	ui.time += delta
	notice_left = maxf(0.0, notice_left - delta)
	penalty_left = maxf(0.0, penalty_left - delta)
	if _fade_dir != 0.0:
		_fade = clampf(_fade + _fade_dir * delta * 3.0, 0.0, 1.0)
	if machine.current.timer_runs():
		timer.tick(delta)
	if level:
		# En pausa (y en el libro) el nivel entero se detiene: guardianes, prensas, Tala
		level.process_mode = Node.PROCESS_MODE_DISABLED if machine.current.freezes_world() else Node.PROCESS_MODE_INHERIT
	machine.current.update(delta)
	overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
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
		settings.set_value("full", not settings.get_bool("full"))
		settings.save()
		return
	if not actions.is_empty():
		machine.current.handle_input(actions)


func _draw_ui() -> void:
	machine.current.draw(ui)
	if _fade > 0.0:
		ui.rect(Rect2(Vector2.ZERO, ui.size()), Color(0, 0, 0, _fade))


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
		# Fuera del árbol de una vez: sus áreas (salidas, fosos) ya no pueden ver a Tala
		remove_child(level)
		level.queue_free()
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


## Pasa a la sala "index" con un fundido corto (la anterior se suelta).
func enter_chamber(index: int) -> void:
	if index >= data.chamber_count() or _changing:
		return
	_changing = true
	await fade_out()
	load_chamber(index)
	_changing = false
	bus.publish(GameEvents.CHAMBER_ENTERED, {"index": index, "name": place_title()})
	fade_in()


## Tala cruza la puerta del templo: el núcleo despierta, empiezan los 15 minutos y se entra
## a la Sala 1.
func enter_temple() -> void:
	if chamber_index >= 0:
		return
	timer.reset()
	timer.start()
	bus.publish(GameEvents.TEMPLE_ENTERED)
	await enter_chamber(0)
	notify(data.messages("temple_start"), 6.0)


## Carga directo una sala (al entrar, al continuar una partida guardada).
func load_chamber(index: int) -> void:
	var chamber := ChamberRegistry.create(data.chamber_data(index))
	if chamber is ChamberLevel:
		chamber.index = index
	chamber_index = index
	load_level(chamber)
	play_music(chamber.music_key)


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
	_fade = 1.0
	_fade_dir = -1.0


func fade_out() -> void:
	_fade_dir = 1.0
	while _fade < 1.0:
		await get_tree().process_frame
	await get_tree().process_frame


func talk(key: String) -> void:
	dialog.say(data.talk(key))


## Aviso urgente: una franja arriba que se lee mientras se juega (no frena los controles).
func notify(lines: Array, seconds := 5.0, good := false) -> void:
	notice = " ".join(lines)
	notice_left = seconds
	notice_good = good


func start_new_game() -> void:
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
	var room: Dictionary = level.save_state() if level is ChamberLevel else {}
	saves.save({"chamber": chamber_index, "time_left": timer.remaining, "hearts": health.halves, "room": room})


func load_game() -> void:
	var snap := saves.load_snapshot()
	start_new_game()
	var index := int(snap.get("chamber", -1))
	if index >= 0 and index < data.chamber_count():
		load_chamber(index)
		level.resume_from_save(snap.get("room", {}))
		timer.start()
	timer.remaining = float(snap.get("time_left", timer.limit))
	health.halves = clampi(int(snap.get("hearts", health.max_halves)), 1, health.max_halves)


## Fin de la partida: la Cámara superada o el tiempo agotado. ending: clave del texto final
## en texts.json ("" = el final de siempre según se ganó o se perdió).
func finish(won: bool, ending := "") -> void:
	timer.stop()
	Engine.time_scale = 1.0
	dialog.close()
	machine.change("end", {"won": won, "ending": ending})


# ---------------------------------------------------------------- vidas y castigos de tiempo

## Un valor de la sección "combat" de config.json.
func combat(key: String, fallback):
	return (data.setting("combat", {}) as Dictionary).get(key, fallback)


## Resta segundos al reloj del núcleo (caídas, prensas, quedarse sin corazones). Solo cuenta
## dentro del templo, con el reloj andando. Si llega a cero, el reloj publica TIME_UP.
func penalize(seconds: float) -> void:
	if not timer.active or seconds <= 0.0:
		return
	timer.remaining = maxf(0.0, timer.remaining - seconds)
	penalty_text = "−%d s" % int(seconds)
	penalty_left = 2.2
	bus.publish(GameEvents.TIME_PENALTY, {"seconds": seconds})


## Sin corazones: Tala cae. Si al núcleo le queda un minuto o menos, se acaba el juego; si no,
## pierde ese minuto y vuelve a la entrada de la sala con los corazones llenos.
func _on_player_died() -> void:
	player.die()
	await get_tree().create_timer(1.6, true, false, true).timeout
	if machine.current is EndState:
		return
	var cost := float(combat("death_penalty_sec", 60))
	if timer.remaining <= cost:
		finish(false, "ending_no_lives")
		return
	penalize(cost)
	notify([data.message("player_no_lives", {"s": int(cost)})], 4.0)
	await fade_out()
	health.refill()
	if level is ChamberLevel:
		level.restart_after_death()
	else:
		level.respawn_player()
	fade_in()


# ---------------------------------------------------------------- herramientas de prueba

func _run_tools_from_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recorrido="):
			_tool = RouteTour.new(self)
			_tool.run(arg.substr(12))
		elif arg == "--selftest":
			_tool = SelfTest.new(self)
			_tool.run()
