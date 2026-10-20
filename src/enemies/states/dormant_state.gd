## Patrón State: estatua dormida sobre su pedestal.
class_name DormantState
extends GuardianState

var _flashed := false
var _flash := 0.0


func enter() -> void:
	super()
	_flashed = false
	_flash = 0.0
	guardian.stone = 1.0
	guardian.cracks = 0.0
	guardian.glow = 0.0
	guardian.shake = 0.0
	guardian.lift = guardian.pedestal_height
	guardian.facing = Vector2.DOWN
	guardian.velocity = Vector2.ZERO
	guardian.eyes.energy = 0.0


func physics(delta: float) -> String:
	if not _flashed and guardian.to_player().length() < float(guardian.setting("eyes_distance", 64.0)):
		_flashed = true
		_flash = 0.6
	_flash = maxf(0.0, _flash - delta)
	guardian.eyes.energy = sin(_flash / 0.6 * PI) * 1.6 if _flash > 0.0 else 0.0
	return ""
