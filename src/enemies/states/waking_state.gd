## Patrón State: la estatua despierta y baja del pedestal.
class_name WakingState
extends GuardianState

var _duration := 1.5
var _start := Vector2.ZERO
var _chipped := false


func enter() -> void:
	super()
	_duration = float(guardian.setting("wake_time", 1.5))
	_start = guardian.position
	_chipped = false
	guardian.facing = Vector2.DOWN
	if guardian.bus:
		guardian.bus.publish(GameEvents.GUARDIAN_WAKING)
	guardian.burst(Vector2(0, -14), "RockGray", 6, 0.7)


func exit() -> void:
	guardian.shake = 0.0
	guardian.cracks = 0.0
	guardian.stone = 0.0
	guardian.lift = 0.0


func physics(delta: float) -> String:
	t += delta
	var k := clampf(t / _duration, 0.0, 1.0)
	if k < 0.7:
		guardian.shake = 0.5 + k * 1.2
		guardian.cracks = k / 0.7
	else:
		if not _chipped:
			_chipped = true
			guardian.burst(Vector2(0, -12), "RockGray", 12, 0.8)
			guardian.burst(Vector2(0, -4), "Smoke", 6, 0.9, Vector2(0, -20))
		var j := (k - 0.7) / 0.3
		guardian.shake = 0.0
		guardian.cracks = 1.0 - j
		guardian.stone = 1.0 - j
		guardian.position = _start + Vector2(0, 10) * j
		guardian.lift = guardian.pedestal_height * (1.0 - j) + sin(j * PI) * 5.0
		guardian.eyes.energy = j * 1.2
	return "chase" if k >= 1.0 else ""


func animation() -> String:
	return "jump" if t / _duration > 0.7 else "idle"
