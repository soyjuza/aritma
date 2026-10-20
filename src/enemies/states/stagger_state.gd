## Patrón State: aturdido por un golpe.
class_name StaggerState
extends GuardianState

const TIME := 0.28

var push := Vector2.DOWN


func enter() -> void:
	super()
	guardian.velocity = push * 130.0
	guardian.glow = 1.0


func exit() -> void:
	guardian.glow = 0.0


func physics(delta: float) -> String:
	t += delta
	guardian.glow = 1.0 - t / TIME
	guardian.velocity = guardian.velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	guardian.move_and_slide()
	return "chase" if t >= TIME else ""


func animation() -> String:
	return "idle"


func hittable() -> bool:
	return true
