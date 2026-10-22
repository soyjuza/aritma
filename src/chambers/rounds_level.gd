## Sala con una máquina de rondas (Bosque). Los textos vienen de chambers.json.
class_name RoundsLevel
extends ChamberLevel

var _in_hall := false

@onready var machine: RoundsMachine = $Actores/Maquina


func wire() -> void:
	machine.setup(_game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_solved)
	objective_key = "objective_rounds_tunnel"
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = String(data.get("objective_key", ""))
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine_blocked():
		return
	if machine.is_solved:
		_game.dialog.say([_game.data.message("rounds_already")])
		return
	_game.open_codex(machine.session)


func _on_solved() -> void:
	objective_key = "objective_rounds_done"
	open_exit()
