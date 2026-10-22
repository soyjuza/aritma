## Práctica: caminar, correr y saltar fosos.
class_name PracticeMoveLevel
extends PracticeLevel


func wire() -> void:
	for zone in $Pasos.get_children():
		var id := String(zone.name)
		(zone as TriggerZone).crossed.connect(func(): _on_zone(id))


func _on_zone(id: String) -> void:
	if id == "correr" and step_id() == "correr" and _game.player.state_name != "run":
		_game.notify([_game.data.message("practice_run_hint", _game.key_names())], 3.0)
		return
	complete(id)
