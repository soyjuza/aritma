## Director de Alarma de una sala. Patrón Observer: escucha MACHINE_FAILED.
## Cada error sube la alarma y manda una ola de guardianes.
## Mientras quede alguno, la máquina no acepta código.
class_name AlarmDirector
extends Node

const SENTINEL := preload("res://scenes/enemigos/centinela.tscn")
const RUNIC := preload("res://scenes/enemigos/runico.tscn")
const SORCERER := preload("res://scenes/enemigos/hechicero.tscn")

var level := 0    # errores en esta sala
var cleared_key := "alarm_cleared"

var _game
var _room: ChamberLevel
var _settings: Dictionary = {}
var _statues: Array = []    # estatuas sobre sus pedestales
var _drops: Array = []    # puntos donde caen del techo
var _alive: Array = []
var _pending := 0
var _wave := 0


func setup(game, room: ChamberLevel) -> void:
	_game = game
	_room = room
	_settings = game.data.setting("combat", {})
	for g in room.nodes_of(Guardian):
		if g.dormant:
			g.setup(game.bus, room.kit, _settings)
			g.defeated.connect(_on_defeated)
			_statues.append(g)
	if room.has_node("Guardianes/Caidas"):
		_drops = room.get_node("Guardianes/Caidas").get_children().filter(func(n): return n is Marker2D)
		for m in _drops:
			m.add_to_group("guardian_spots")
	if enabled():
		game.bus.subscribe(GameEvents.MACHINE_FAILED, _on_machine_failed)
		game.bus.subscribe(GameEvents.RUNE_BLAST, _on_rune_blast)
		tree_exiting.connect(func():
			game.bus.unsubscribe(GameEvents.MACHINE_FAILED, _on_machine_failed)
			game.bus.unsubscribe(GameEvents.RUNE_BLAST, _on_rune_blast))


## La sala tiene guardianes (estatuas o puntos de caída).
func enabled() -> bool:
	return not _statues.is_empty() or not _drops.is_empty()


## Hay guardianes despiertos o por caer: la máquina no acepta código.
func fighting() -> bool:
	return not _alive.is_empty() or _pending > 0


func alive_count() -> int:
	return _alive.size() + _pending


## Cuántos quedan de cada tipo: {"caballero": 2, "hechicero": 1}.
func alive_by_kind() -> Dictionary:
	var out := {}
	for g in _alive:
		if is_instance_valid(g):
			out[g.kind] = int(out.get(g.kind, 0)) + 1
	return out


## Cuántos guardianes manda la alarma n y qué tan rápidos son.
func wave_size(n: int) -> int:
	var waves: Array = _settings.get("waves", [2, 3, 3, 4, 5, 6])
	return int(waves[clampi(n - 1, 0, waves.size() - 1)])


## Cuántos rúnicos tiene la ola.
func runic_count(n: int) -> int:
	var table: Array = _settings.get("runic_waves", [0, 0, 1, 1, 2, 2])
	return mini(wave_size(n), int(table[clampi(n - 1, 0, table.size() - 1)]))


## Cuántos hechiceros tiene la ola.
func ranged_count(n: int) -> int:
	var table: Array = _settings.get("ranged_waves", [0, 1, 1, 1, 2, 2])
	return mini(wave_size(n) - runic_count(n), int(table[clampi(n - 1, 0, table.size() - 1)]))


## La ola n en orden de llegada.
func wave_kinds(n: int) -> Array:
	var runics := runic_count(n)
	var ranged := ranged_count(n)
	var kinds: Array = []
	for i in wave_size(n) - runics - ranged:
		kinds.append("caballero")
	for i in ranged:
		kinds.append("hechicero")
	for i in runics:
		kinds.append("runico")
	return kinds


## El reto de teclas según la alarma.
func challenge(n: int) -> Dictionary:
	var count := clampi(4 + n - 3, 4, 7)
	var pool: Array = _settings.get("challenge_keys", ["A", "S", "D", "F", "J", "K", "L"])
	return {
		"keys": KeyChallengeState.random_keys(pool, count),
		"pool": pool,
		"seconds": float(_settings.get("challenge_base_sec", 1.0)) + float(_settings.get("challenge_sec_per_key", 1.0)) * count,
		"ready": float(_settings.get("challenge_ready_sec", 1.0)),
		"damage": int(_settings.get("blast_damage", 4)),
	}


func wave_speed(n: int) -> float:
	var step := float(_settings.get("speed_step", 0.12))
	return minf(float(_settings.get("speed_max", 1.6)), 1.0 + step * (n - 1))


# ------------------------------------------------------------------ alarma

func _on_machine_failed(payload: Dictionary) -> void:
	if _room.solved or not is_inside_tree():
		return
	level += 1
	_game.bus.publish(GameEvents.ALARM_RAISED, {"level": level})
	var why := String(payload.get("message", ""))
	var lines := [why] if why != "" else []
	lines.append(_game.data.message("alarm_wake"))
	_game.notify(lines, 6.0)
	_room.lock_machines(true)
	# Un momento para leer el error y empieza la pelea
	await _real_wait(0.6)
	if _game.machine.current is CodexState:
		_game.machine.change("play")
	_slow_motion()
	_send_wave(level)


## El jefe llama una ola sin subir la alarma.
func summon(n: int) -> void:
	_slow_motion()
	_send_wave(n)


func _send_wave(n: int) -> void:
	var wave := _wave
	var kinds := wave_kinds(n)
	var speed := wave_speed(n)
	var knights := kinds.count("caballero")
	var woke := 0
	for statue: Guardian in _statues:
		if woke >= knights or statue.state_name != "dormant":
			continue
		statue.speed_scale = speed
		statue.wake()
		_alive.append(statue)
		woke += 1
		_crumble_pedestal(statue)
	# Los que faltan caen del techo
	var falling := kinds.slice(woke)
	var spots := _drop_spots(falling.size())
	_pending = spots.size()
	for i in spots.size():
		if wave != _wave:
			return
		var at: Vector2 = spots[i]
		var scene: PackedScene = {"caballero": SENTINEL, "hechicero": SORCERER, "runico": RUNIC}[falling[i]]
		var g: Guardian = scene.instantiate()
		g.setup(_game.bus, _room.kit, _settings)
		g.speed_scale = speed
		_room.actors.add_child(g)
		g.defeated.connect(_on_defeated)
		g.drop(at)
		_alive.append(g)
		_pending -= 1
		await _real_wait(float(_settings.get("drop_stagger", 0.5)))


func _crumble_pedestal(statue: Guardian) -> void:
	var pedestal := statue.get_parent() as Pedestal
	if pedestal == null:
		return
	var wave := _wave
	await _real_wait(float(_settings.get("wake_time", 1.5)) * 0.7)
	if wave == _wave:
		pedestal.rubble = true


## Puntos de caída lejos de Tala, sin repetir.
func _drop_spots(n: int) -> Array:
	var spots: Array = []
	if n <= 0 or _drops.is_empty():
		return spots
	var min_distance := float(_settings.get("min_drop_distance", 48.0))
	var player_at: Vector2 = _game.player.global_position
	var all: Array = _drops.map(func(m): return m.global_position)
	all.shuffle()
	var far := all.filter(func(p): return p.distance_to(player_at) >= min_distance)
	if far.is_empty():
		all.sort_custom(func(a, b): return a.distance_to(player_at) > b.distance_to(player_at))
		far = [all[0]]
	for at in far:
		if spots.size() >= n:
			break
		spots.append(at)
	var i := 0
	while spots.size() < n:
		spots.append(spots[i % spots.size()] + Vector2(randf_range(-14, 14), randf_range(-10, 10)))
		i += 1
	return spots


func _on_rune_blast(payload: Dictionary) -> void:
	if payload.get("caught", false) and _game.machine.current is PlayState:
		_game.machine.change("keys", challenge(maxi(level, 3)))


func _on_defeated(g: Guardian) -> void:
	_alive.erase(g)
	if _alive.is_empty() and _pending == 0 and not _room.solved:
		_game.bus.publish(GameEvents.WAVE_CLEARED, {"level": level})
		_game.notify([_game.data.message(cleared_key)], 3.5)
		_room.lock_machines(false)


## Cámara lenta al despertar.
func _slow_motion() -> void:
	Engine.time_scale = float(_settings.get("slowmo_scale", 0.35))
	await _real_wait(float(_settings.get("slowmo_sec", 0.6)))
	Engine.time_scale = 1.0


func _real_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


# ------------------------------------------------------------------ fin de la pelea

## Sala resuelta: la alarma se apaga y los guardianes se deshacen.
func calm() -> void:
	level = 0
	_wave += 1
	_pending = 0
	for g in _alive.duplicate():
		g.dissolve()
	_alive.clear()
	_room.lock_machines(false)


## Tala cayó: los guardianes vuelven a su lugar. La alarma no baja.
func reset_after_death() -> void:
	_wave += 1
	_pending = 0
	Engine.time_scale = 1.0
	for g in _alive:
		if is_instance_valid(g) and g.from_ceiling:
			g.queue_free()
	_alive.clear()
	for statue: Guardian in _statues:
		statue.restore()
		var pedestal := statue.get_parent() as Pedestal
		if pedestal:
			pedestal.rubble = false
	_room.lock_machines(false)
