## Práctica del buscaminas: un tablero chico con las minas fijas y pasos guiados.
## Cada paso dice "do": reveal (destapar), flag (bandera) o clear (terminar el tablero).
## Con "pick" no se marca la baldosa: hay que deducirla mirando el número "clue".
class_name PracticeMinesLevel
extends PracticeLevel

var _busy := false

@onready var board: MineBoard = $Tablero


func wire() -> void:
	var size: Array = data.get("board", [5, 4])
	board.cols = int(size[0])
	board.rows = int(size[1])
	# Centrado en la sala; el tablero de 5 x 4 queda donde está en la escena
	board.position = Vector2(floorf(6.5 - board.cols / 2.0), 9 - board.rows) * TileKit.TILE
	board.preset = _cells(data.get("mines", []))
	board.mine_count = board.preset.size()
	board.power_on()
	board.exploded.connect(_on_exploded)


func _cells(list: Array) -> Dictionary:
	var out := {}
	for c in list:
		out[Vector2i(int(c[0]), int(c[1]))] = true
	return out


func _step_cell(field: String) -> Vector2i:
	var c: Array = steps()[step].get(field, [-1, -1]) if step < steps().size() else [-1, -1]
	return Vector2i(int(c[0]), int(c[1]))


func _step_do() -> String:
	return String(steps()[step].get("do", "clear")) if step < steps().size() else ""


func _picks() -> bool:
	return step < steps().size() and bool(steps()[step].get("pick", false))


func on_step(_id: String) -> void:
	board.guide = Vector2i(-1, -1) if _picks() else _step_cell("cell")
	board.clue = _step_cell("clue")


func guide_point(_id: String) -> Vector2:
	var cell := _step_cell("clue") if _picks() else _step_cell("cell")
	return board.cell_center(cell) if cell != Vector2i(-1, -1) else Vector2.INF


## ¿Esta baldosa cumple el paso? Con "pick" vale cualquiera junto al número que sea correcta.
func _is_target(cell: Vector2i) -> bool:
	if not _picks():
		return cell == _step_cell("cell")
	var right := board.mines.has(cell) if _step_do() == "flag" else not board.mines.has(cell)
	return right and cell in board.neighbors(_step_cell("clue"))


## E destapa y Q marca, como en el Vórtice.
func handle_action(actions: Array) -> bool:
	if finished or _busy:
		return false
	var cell := board.cell_at(_game.player.global_position)
	if cell == Vector2i(-1, -1):
		return false
	if "interact" in actions:
		if board.reveal(cell) == MineBoard.Result.SAFE:
			_game.bus.publish(GameEvents.TILE_REVEALED)
			if board.is_cleared():
				while not finished:
					complete(step_id())
			elif _step_do() == "reveal" and _is_target(cell):
				complete(step_id())
		return true
	if "flag" in actions:
		if board.toggle_flag(cell):
			_game.bus.publish(GameEvents.TILE_FLAGGED)
			if _step_do() == "flag" and board.flags.has(cell) and _is_target(cell):
				complete(step_id())
			elif _step_do() == "flag" and board.flags.has(cell):
				_game.notify([_game.data.message("practice_flag_pick" if _picks() else "practice_flag_wrong")], 3.0)
		return true
	return false


func action_prompt() -> Dictionary:
	if finished or board.cell_at(_game.player.global_position) == Vector2i(-1, -1):
		return {}
	return {"key": InputSetup.key_name("interact"), "text": _game.data.message("prompt_board", {"flag": InputSetup.key_name("flag")})}


## En la práctica una mina no quita corazones: el tablero vuelve a empezar.
func _on_exploded(_cell: Vector2i) -> void:
	_busy = true
	_game.bus.publish(GameEvents.MINE_EXPLODED)
	_game.notify([_game.data.message("practice_boom")], 4.0)
	await get_tree().create_timer(1.0).timeout
	board.reset()
	back_to(String(steps()[0].get("id", "")))
	_busy = false


## Sobre el tablero aparece el botón de bandera.
func touch_actions() -> Array:
	return ["flag"] if not action_prompt().is_empty() else []
