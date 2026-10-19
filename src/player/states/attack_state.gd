## PATRÓN STATE — Golpear con el garrote: Tala casi se detiene, el garrote barre un arco
## delante de ella y, a un tercio del golpe, alcanza a los guardianes que estén en el arco.
class_name AttackState
extends MoveState

var _t := 0.0
var _struck := false


func enter(_previous: String) -> void:
	_t = 0.0
	_struck = false
	player.start_swing()


func exit() -> void:
	player.end_swing()


func physics(delta: float) -> String:
	_t += delta
	player.velocity = player.velocity.move_toward(Vector2.ZERO, player.accel * delta)
	player.move_and_slide()
	var k := clampf(_t / player.attack_time, 0.0, 1.0)
	player.update_swing(k)
	if not _struck and k >= 0.35:
		_struck = true
		player.strike()
	if k >= 1.0:
		return "walk" if player.has_move_input() else "idle"
	return ""


func animation() -> String:
	return "attack"
