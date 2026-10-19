## PATRÓN STATE — Base de los estados en el suelo: aplican la velocidad del estado, revisan
## el salto y dejan las demás transiciones a cada subclase.
class_name GroundState
extends MoveState


func speed() -> float:
	return 0.0


func physics(delta: float) -> String:
	player.move_toward_input(speed(), delta)
	player.move_and_slide()
	if player.wants_jump():
		return "jump"
	if player.wants_attack():
		return "attack"
	return transition()


func transition() -> String:
	return ""
