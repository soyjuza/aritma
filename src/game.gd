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
var quests: QuestLog
var skills: SkillTree
var machine_zoom := 1.0    # en el celular la cámara se acerca más a la máquina
var practices_done := {}

var _observers: Array = []
var _tool: RefCounted
var _secret: SecretCodeDetector
var _base_stamina := -1.0
var _changing := false    # evita dos cambios de sala a la vez

@onready var rig: CameraRig = $Camara
@onready var player: PlayerController = $Tala
@onready var codex: CodexPanel = $Interfaz/Codice
@onready var overlay: OverlayCanvas = $Interfaz/Pantalla
@onready var touch: TouchControls = $Interfaz/Tactil


func _ready() -> void:
	data = DataRepository.new()
	InputSetup.register(data.setting("controls", {}))
	InputSetup.mouse_names = data.texts.get("mouse_names", {})
	_setup_touch()
	bus = EventBus.new()
	audio = AudioService.new(self)
	saves = SaveRepository.new()
	kit = TileKit.new()
	health = PlayerHealth.new(bus, int(combat("hearts", 5)))
	# En el celular el mapa se ve más de cerca
	rig.base_zoom = float(data.setting("touch_zoom" if data.touch else "zoom", 3))
	rig.frame_zoom = float(data.setting("zoom", 3))
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
	fade = ScreenFade.new(get_tree())
	rules = LifeRules.new(self)
	quests = QuestLog.new(self, data.quests)
	skills = SkillTree.new(data.setting("skills", []))
	machine = _create_states()
	load_level(town_scene.instantiate())
	settings.applied.connect(_apply_settings)
	settings.apply()
	machine.change("title")
	_run_tools_from_command_line()


## En el celular (o con --tactil en el PC) aparecen la palanca y los botones.
func _setup_touch() -> void:
	var forced := "--tactil" in OS.get_cmdline_user_args()
	var on := forced or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	touch.visible = on
	if not on:
		return
	data.use_touch()
	codex.zoom = float(data.setting("touch_codex_zoom", 1.0))
	machine_zoom = float(data.setting("touch_machine_zoom", 1.0))
	InputSetup.touch = true
	InputSetup.touch_names = data.texts.get("touch_names", {})
	InputSetup.drop_mouse_bindings()
	touch.setup(self, InputSetup.touch_names, forced)


func _create_states() -> StateMachine:
	var m := StateMachine.new()
	m.add("title", TitleState.new(self))
	m.add("menu", MenuState.new(self))
	m.add("intro", IntroState.new(self))
	m.add("play", PlayState.new(self))
	m.add("pause", PauseState.new(self))
	m.add("skills", SkillsState.new(self))
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
	notices.tick(delta)
	fade.tick(delta)
	if level:
		# En pausa se detiene todo el nivel
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


## Pasa a otra sala con un fundido. Si la sala tiene prácticas pendientes, va primero a ellas.
func enter_chamber(index: int) -> void:
	if index >= data.chamber_count() or _changing:
		return
	_changing = true
	await fade_out()
	var practice := next_practice(index)
	if practice != "":
		load_practice(practice, index)
		_changing = false
		fade_in()
		return
	load_chamber(index)
	_changing = false
	bus.publish(GameEvents.CHAMBER_ENTERED, {"index": index, "name": place_title()})
	fade_in()
	if index == 0:
		notify(data.messages("temple_start"), 6.0)


## Tala entra al templo y va a la Sala 1.
func enter_temple() -> void:
	if chamber_index >= 0:
		return
	bus.publish(GameEvents.TEMPLE_ENTERED)
	await enter_chamber(0)


## Práctica que falta antes de una sala, o "".
func next_practice(index: int) -> String:
	if not data.setting("practices_on", true):
		return ""
	for key in data.chamber_data(index).get("practices", []):
		if not practices_done.has(key):
			return String(key)
	return ""


func load_practice(key: String, index: int) -> void:
	var info: Dictionary = data.practice(key)
	var practice: PracticeLevel = (load(String(info.get("scene", ""))) as PackedScene).instantiate()
	practice.data = info
	practice.key = key
	practice.title = String(info.get("title", ""))
	practice.next_chamber = index
	chamber_index = index
	load_level(practice)
	play_music(practice.music_key)


## Termina la práctica y sigue a lo que viene.
func leave_practice() -> void:
	var practice := level as PracticeLevel
	if practice == null:
		return
	practices_done[practice.key] = true
	enter_chamber(practice.next_chamber)


## Salta todas las prácticas de esta sala.
func skip_practice() -> void:
	var practice := level as PracticeLevel
	if practice == null:
		return
	for key in data.chamber_data(practice.next_chamber).get("practices", []):
		practices_done[key] = true
	enter_chamber(practice.next_chamber)


## Carga una sala sin fundido.
func load_chamber(index: int) -> void:
	var chamber := ChamberRegistry.create(data.chamber_data(index))
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
	if level is PracticeLevel:
		return level.title
	if chamber_index < 0:
		return String(level.data.get("name", data.message("pause_town")))
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


## Habla con un personaje: su misión o su charla.
func talk_to(npc: Npc) -> void:
	if npc.quest_id != "":
		quests.talk(npc.quest_id)
	else:
		talk(npc.talk_key)


## Aviso arriba de la pantalla.
## Lo que dan los niveles de habilidad (también al cargar partida).
func apply_skills() -> void:
	var wanted := int(combat("hearts", 5)) * 2 + 2 * skills.level("vida")
	var grew := wanted - health.max_halves
	health.max_halves = wanted
	health.halves = clampi(health.halves + maxi(grew, 0), 0, wanted)
	player.attack_damage = 1 + skills.level("fuerza")
	if _base_stamina < 0.0:
		_base_stamina = player.stamina_max
	player.stamina_max = _base_stamina * (1.0 + 0.5 * skills.level("aliento"))


## Puntos nuevos: aviso para gastarlos en la pausa.
func grant_points(points: int) -> void:
	skills.grant(points)
	notify([data.message("skills_new", {"n": points})], 5.0, true)


func notify(lines: Array, seconds := 5.0, good := false) -> void:
	notices.notify(lines, seconds, good)


func start_new_game() -> void:
	quests.reset()
	skills.reset()
	apply_skills()
	health.refill()
	Engine.time_scale = 1.0
	dialog.close()
	chamber_index = -1
	practices_done.clear()
	load_level(town_scene.instantiate())
	play_music(level.music_key)
	fade_in()


func open_codex(session: CodexSession) -> void:
	bus.publish(GameEvents.MENU_CONFIRM)
	machine.change("codex", {"session": session})


func save_game() -> void:
	var room := level.save_state()
	saves.save({"chamber": chamber_index, "hearts": health.halves, "room": room, "quests": quests.save_state(), "skills": skills.save_state(), "chapter": data.chapter})


func load_game() -> void:
	var snap := saves.load_snapshot()
	start_new_game()
	var chapter := int(snap.get("chapter", -1))
	if chapter >= 0:
		data.use_chapter(chapter)
	var index := int(snap.get("chamber", -1))
	if index >= 0 and index < data.chamber_count():
		load_chamber(index)
		level.resume_from_save(snap.get("room", {}))
	elif chapter > 0:
		load_hub(chapter)
	quests.restore(snap.get("quests", {}))
	skills.restore(snap.get("skills", {"earned": quests.done_count()}))
	apply_skills()
	health.halves = clampi(int(snap.get("hearts", health.max_halves)), 1, health.max_halves)


## Mapa del capítulo i (el Bosque...). El capítulo 1 usa el pueblo.
func load_hub(i: int) -> void:
	data.use_chapter(i)
	chamber_index = -1
	var hub: Dictionary = data.chapter_data(i).get("hub", {})
	var map: Level = (load(String(hub.get("scene", ""))) as PackedScene).instantiate()
	map.data = hub
	load_level(map)
	play_music(map.music_key)


## Vencido el jefe: sigue al mapa del capítulo siguiente o termina.
func chapter_done() -> void:
	var info := data.chapter_data(data.chapter)
	var next := data.chapter_data(data.chapter + 1)
	if data.chapter < 0 or not next.has("hub"):
		finish(true, String(info.get("ending", "")))
		return
	player.controls_enabled = false
	await fade_out()
	load_hub(data.chapter + 1)
	fade_in()
	dialog.say(info.get("outro", []))
	bus.publish(GameEvents.CHAMBER_ENTERED, {"index": -1, "name": place_title()})


## Fin de la partida. ending es la clave del texto final.
func finish(won: bool, ending := "") -> void:
	Engine.time_scale = 1.0
	dialog.close()
	machine.change("end", {"won": won, "ending": ending})


# ---------------------------------------------------------------- vidas y caídas

## Valor de "combat" en config.json.
func combat(key: String, fallback):
	return (data.setting("combat", {}) as Dictionary).get(key, fallback)


## Una caída cuesta medio corazón.
func fall_damage() -> void:
	rules.fall_damage()


# ---------------------------------------------------------------- herramientas de prueba

func _run_tools_from_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recorrido="):
			_tool = RouteTour.new(self)
			_tool.run(arg.substr(12))
		elif arg == "--selftest":
			_tool = SelfTest.new(self)
			_tool.run()
