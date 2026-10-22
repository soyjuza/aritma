## Sala 2: el Mural. Hay que escribir despejar(a, b, c).
class_name RootsLevel
extends ChamberLevel

var _in_hall := false

@onready var machine: MuralMachine = $Actores/Mural


func wire() -> void:
	var periods: Array = data.get("press_periods", [])
	var presses := nodes_of(Crusher)
	for i in presses.size():
		if i < periods.size():
			presses[i].period = float(periods[i])
		presses[i].crushed.connect(_on_crushed)
	machine.setup(kit, _game.bus, data, func(key, args): return _game.data.message(key, args), _open_machine)
	machine.solved.connect(_on_solved)
	$Zonas/EntradaSala.crossed.connect(_on_hall_entered)


func _on_crushed() -> void:
	_game.bus.publish(GameEvents.PLAYER_FELL)
	_game.fall_damage()
	_game.notify([_game.data.message("player_crushed")], 2.5)
	if not _game.health.is_dead():
		respawn_player()


func _on_hall_entered() -> void:
	_in_hall = true
	objective_key = "objective_roots_machine"
	_game.dialog.say(data.get("intro", []))


func _open_machine() -> void:
	if machine_blocked():
		return
	if machine.is_solved:
		_game.dialog.say([_game.data.message("roots_already")])
		return
	_game.open_codex(machine.session)


func _on_solved() -> void:
	objective_key = "objective_roots_done"
	open_exit()
