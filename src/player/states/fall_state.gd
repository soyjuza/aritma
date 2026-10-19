## PATRÓN STATE — Cayendo a un foso: sin control; el nivel la devuelve al punto seguro.
class_name FallState
extends MoveState


func physics(_delta: float) -> String:
	player.velocity = Vector2.ZERO
	return ""


func animation() -> String:
	return "jump"
