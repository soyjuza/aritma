## Práctica con un atril: primero usarlo y luego una etapa por cada programa.
class_name PracticeCodeLevel
extends PracticeLevel

var stage := 0

@onready var machine: CodeMachine = $Actores/Maquina


func wire() -> void:
	var text := func(k, args): return _game.data.message(k, args)
	if machine is TorchMachine:
		machine.setup(text, $Actores/Braseros.get_children(), _open_machine)
	else:
		machine.setup(text, _open_machine)
	machine.set_stage(stages()[0])
	machine.solved.connect(_on_solved)


func stages() -> Array:
	return data.get("stages", [])


func _open_machine() -> void:
	if finished:
		_game.dialog.say([_game.data.message("practice_machine_done")])
		return
	complete("atril")
	_game.open_codex(machine.session)


func _on_solved() -> void:
	complete("etapa%d" % (stage + 1))
	stage += 1
	if stage < stages().size():
		# Después de que el Códice se cierre
		_next_stage.call_deferred()


func _next_stage() -> void:
	machine.set_stage(stages()[stage])


func guide_point(id: String) -> Vector2:
	if id == "atril" or id.begins_with("etapa"):
		return machine.global_position + Vector2(0, -20)
	return Vector2.INF
