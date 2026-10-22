## Sala 1: la Compuerta. Variables: el nivel del sensor más algo.
class_name LockLevel
extends ChamberLevel

var _in_hall := false

@onready var machine: LockMachine = $Actores/Compuerta


func wire() -> void:
	machine.setup(_game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_solved)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_lock_machine"
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine_blocked():
		return
	if machine.is_solved:
		_game.dialog.say([_game.data.message("lock_already")])
		return
	_game.open_codex(machine.session)


func _on_solved() -> void:
	objective_key = "objective_lock_done"
	open_exit()
