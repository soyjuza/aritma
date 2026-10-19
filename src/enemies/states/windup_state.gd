## PATRÓN STATE — Prepara el ataque: se detiene y brilla cada vez más rápido. Es el aviso para
## esquivar (o para golpearlo primero: al centinela un golpe de Tala le cancela el ataque).
class_name WindupState
extends GuardianState

var _duration := 0.45


func enter() -> void:
	super()
	_duration = guardian.attack.windup_time() / guardian.pace()
	guardian.velocity = Vector2.ZERO
	guardian.on_windup()


func exit() -> void:
	guardian.glow = 0.0
	guardian.charge = 0.0


func physics(delta: float) -> String:
	t += delta
	guardian.charge = clampf(t / _duration, 0.0, 1.0)
	guardian.velocity = guardian.velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	guardian.move_and_slide()
	var to := guardian.to_player()
	if to.length() > 0.1:
		guardian.facing = to.normalized()
	guardian.glow = 0.5 + 0.5 * sin(t * (24.0 + 40.0 * guardian.charge))
	return "strike" if t >= _duration else ""


func hittable() -> bool:
	return true
