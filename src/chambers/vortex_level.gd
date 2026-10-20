## Sala 3 — El Vórtice de Celdas (escena: scenes/niveles/sala_3_vortice.tscn).
## Un pasillo sin trampas lleva a la sala del tablero. El Faro enciende el tablero cuando el
## jugador ordena luces.encender(). Encendido, es un buscaminas que se juega caminando: E destapa
## la baldosa que pisa Tala y Q le pone o quita la bandera. Destapar una mina cuesta 2 corazones
## y devuelve a Tala a la entrada con un tablero nuevo. Esta sala no tiene guardianes.
class_name VortexLevel
extends ChamberLevel

var _in_hall := false
var _busy := false          # mostrando una explosión: no se destapa nada más

@onready var machine: BeaconMachine = $Actores/Faro
@onready var board: MineBoard = $Tablero


func wire() -> void:
	var settings: Dictionary = data.get("board", {})
	board.cols = int(settings.get("cols", 8))
	board.rows = int(settings.get("rows", 8))
	board.mine_count = int(settings.get("mines", 10))
	board.exploded.connect(_on_exploded)
	board.cleared.connect(_on_cleared)
	machine.setup(_game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_powered)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	_in_hall = true
	if not board.powered:
		objective_key = "objective_vortex_machine"
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine.is_solved:
		_game.dialog.say([_game.data.message("beacon_already")])
		return
	_game.open_codex(machine.session)


func _on_powered() -> void:
	board.power_on()
	# Se encienden las luces: la sala entera se aclara
	create_tween().tween_property($Ambiente, "color", Color(0.62, 0.6, 0.74), 1.2)
	objective_key = "objective_vortex_board"
	_game.bus.publish(GameEvents.BOARD_POWERED)


## E destapa y Q marca la baldosa que pisa Tala (si el tablero está encendido).
func handle_action(actions: Array) -> bool:
	if not board.powered or solved or _busy:
		return false
	var cell := board.cell_at(_game.player.global_position)
	if cell == Vector2i(-1, -1):
		return false
	if "interact" in actions:
		if board.reveal(cell) == MineBoard.Result.SAFE:
			_game.bus.publish(GameEvents.TILE_REVEALED)
		return true
	if "flag" in actions:
		if board.toggle_flag(cell):
			_game.bus.publish(GameEvents.TILE_FLAGGED)
		return true
	return false


func action_prompt() -> Dictionary:
	if not board.powered or solved or board.cell_at(_game.player.global_position) == Vector2i(-1, -1):
		return {}
	return {"key": InputSetup.key_name("interact"), "text": _game.data.message("prompt_board", {"flag": InputSetup.key_name("flag")})}


func hud_line() -> String:
	if not board.powered or solved:
		return ""
	var left := board.cols * board.rows - board.mine_count - board.revealed.size()
	return _game.data.message("hud_board", {"mines": board.mine_count, "flags": board.flags.size(), "left": left})


## Una mina: explota, −2 corazones y, tras un instante, Tala vuelve a la entrada con un
## tablero nuevo (si con eso se quedó sin corazones, manda el castigo de siempre).
func _on_exploded(cell: Vector2i) -> void:
	_busy = true
	_game.bus.publish(GameEvents.MINE_EXPLODED)
	var boom := Sprite2D.new()
	boom.texture = RunicGuardian.EXPLOSION
	boom.hframes = 9
	boom.scale = Vector2.ONE * 1.4
	boom.z_index = 6
	boom.position = actors.to_local(board.cell_center(cell)) + Vector2(0, -6)
	actors.add_child(boom)
	var t := boom.create_tween()
	t.tween_property(boom, "frame", 8, 0.5)
	t.tween_callback(boom.queue_free)
	_game.notify([_game.data.message("board_boom", {"n": int(_game.combat("mine_damage", 4)) / 2})], 4.0)
	_game.player.hurt(int(_game.combat("mine_damage", 4)), board.cell_center(cell), true)
	if _game.health.is_dead():
		_busy = false
		return    # el juego se encarga (−1 minuto o fin) y llama a restart_after_death()
	await get_tree().create_timer(1.3).timeout
	await _game.fade_out()
	board.reset()
	_game.player.place(room_entrance(), Vector2.UP)
	_game.fade_in()
	_busy = false


func restart_after_death() -> void:
	board.reset()
	super()


func _on_cleared() -> void:
	objective_key = "objective_vortex_done"
	_game.dialog.say([_game.data.message("board_cleared")])
	open_exit()
