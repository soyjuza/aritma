## Patrón State: cayendo a un foso.
class_name FallState
extends MoveState


func physics(_delta: float) -> String:
	player.velocity = Vector2.ZERO
	return ""


func animation() -> String:
	return "jump"
