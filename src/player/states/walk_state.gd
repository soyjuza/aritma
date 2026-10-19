## PATRÓN STATE — Caminar.
class_name WalkState
extends GroundState


func speed() -> float:
	return player.walk_speed


func transition() -> String:
	if not player.has_move_input():
		return "idle"
	if player.wants_run():
		return "run"
	return ""


func animation() -> String:
	return "walk"
