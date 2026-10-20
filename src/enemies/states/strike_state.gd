## Patrón State: golpea y después descansa.
class_name StrikeState
extends GuardianState

const TIME := 0.32

var _done := false


func enter() -> void:
	super()
	_done = false
	guardian.velocity = Vector2.ZERO if guardian.is_ranged() else guardian.facing * 90.0


func physics(delta: float) -> String:
	t += delta
	guardian.velocity = guardian.velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	guardian.move_and_slide()
	if not _done and t >= 0.08:
		_done = true
		guardian.attack.perform(guardian, guardian.player())
	if t >= TIME:
		guardian.cooldown = guardian.attack.cooldown() / guardian.pace()
		return "chase"
	return ""


func animation() -> String:
	return "attack"


func hittable() -> bool:
	return true
