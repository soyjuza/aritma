## PATRÓN STATE — Quieta.
class_name IdleState
extends GroundState


func transition() -> String:
	if player.has_move_input():
		return "run" if player.wants_run() else "walk"
	return ""
