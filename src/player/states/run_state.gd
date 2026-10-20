## Patrón State: correr, gasta aliento.
class_name RunState
extends GroundState


func speed() -> float:
	return player.run_speed


func physics(delta: float) -> String:
	player.spend_stamina(delta)
	return super(delta)


func transition() -> String:
	if not player.has_move_input():
		return "idle"
	if not player.wants_run():
		return "walk"
	return ""


func animation() -> String:
	return "walk"


func animation_speed() -> float:
	return 1.7


func regenerates_stamina() -> bool:
	return false
