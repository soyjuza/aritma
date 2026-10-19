## PATRÓN STATE — Golpea: se lanza un poco hacia delante y su estrategia de ataque decide si
## alcanzó a Tala. Después descansa antes de poder volver a atacar.
class_name StrikeState
extends GuardianState

const TIME := 0.32

var _done := false


func enter() -> void:
	super()
	_done = false
	# El de cuerpo a cuerpo se lanza un poco; el de distancia dispara quieto
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
