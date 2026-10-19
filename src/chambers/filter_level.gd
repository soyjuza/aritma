## Sala 1 — El Filtro de la Dualidad (escena: scenes/niveles/sala_1_filtro.tscn).
## Se entra por un pasillo con dos fosos que solo se cruzan saltando a la carrera. Después,
## la sala de la Criba: hay que programarla para que solo las esferas pares lleguen al cáliz.
## Al lograrlo, la reja de la salida (al norte) se levanta.
class_name FilterLevel
extends ChamberLevel

var _in_hall := false

@onready var machine: CribaMachine = $Actores/Criba


func wire() -> void:
	machine.setup(kit, _game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_solved)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_filter_machine"
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine_blocked():
		return
	if machine.is_solved:
		_game.dialog.say([_game.data.message("filter_already")])
		return
	_game.open_codex(machine.session)


func _on_solved() -> void:
	objective_key = "objective_filter_done"
	open_exit()
