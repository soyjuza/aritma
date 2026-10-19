## PATRÓN STATE — Saltar: Tala se eleva en un arco y mantiene el impulso que llevaba (en el
## aire casi no se puede corregir el rumbo). Mientras está en el aire los fosos no la tumban.
class_name JumpState
extends MoveState

var _t := 0.0
var _carry := Vector2.ZERO


func enter(_previous: String) -> void:
	_t = 0.0
	_carry = player.velocity
	player.airborne = true
	player.jumped()


func exit() -> void:
	player.airborne = false
	player.hop_height = 0.0


func physics(delta: float) -> String:
	_t += delta
	var k := clampf(_t / player.jump_time, 0.0, 1.0)
	player.hop_height = sin(k * PI) * player.jump_height
	# Un poco de control en el aire, pero sobre todo el impulso del despegue
	var steer := player.input_vector() * player.walk_speed * 0.25
	player.velocity = _carry + steer
	player.move_and_slide()
	if k >= 1.0:
		player.landed()
		return "walk" if player.has_move_input() else "idle"
	return ""


func animation() -> String:
	return "jump"
