## PATRÓN STATE — Cae del techo: primero caen piedritas y crece una sombra en el suelo (el
## aviso), después el guardián cae en pose de superhéroe, levanta polvo, se queda agachado
## un instante y se levanta. Mientras cae y está agachado no hace daño ni recibe golpes.
class_name DroppingState
extends GuardianState

const HEIGHT := 150.0
const FALL := 0.2

var _warning := 1.0
var _crouch := 0.5
var _landed := false
var _pebbles := 0.0


func enter() -> void:
	super()
	_warning = float(guardian.setting("drop_warning", 1.0))
	_crouch = float(guardian.setting("crouch_time", 0.5))
	_landed = false
	_pebbles = 0.0
	guardian.stone = 0.0
	guardian.lift = HEIGHT
	guardian.sprite.visible = false
	guardian.shadow.modulate.a = 0.0
	guardian.eyes.energy = 0.0
	guardian.facing = guardian.to_player().normalized() if guardian.to_player().length() > 1.0 else Vector2.DOWN
	guardian.body_shape.set_deferred("disabled", true)
	if guardian.bus:
		guardian.bus.publish(GameEvents.GUARDIAN_DROPPING)


func exit() -> void:
	guardian.shadow_size = -1.0
	guardian.sprite.visible = true
	guardian.shadow.modulate.a = 0.75
	guardian.lift = 0.0
	guardian.body_shape.set_deferred("disabled", false)


func physics(delta: float) -> String:
	t += delta
	if t < _warning:
		# El aviso: piedritas que caen y una sombra que crece
		var k := t / _warning
		guardian.shadow.modulate.a = 0.35 + 0.65 * k
		guardian.shadow_size = 0.5 + 1.1 * k
		guardian.lift = HEIGHT * (1.0 - k * 0.15)
		_pebbles -= delta
		if _pebbles <= 0.0:
			_pebbles = 0.22
			# Piedritas que caen justo sobre la sombra
			var p := guardian.burst(Vector2(randf_range(-5, 5), -34), "RockGray", 2, 0.32, Vector2(0, 300))
			if p:
				p.direction = Vector2.DOWN
				p.spread = 8.0
				p.initial_velocity_min = 5.0
				p.initial_velocity_max = 15.0
				p.scale_amount_min = 0.35
				p.scale_amount_max = 0.5
		return ""
	guardian.sprite.visible = true
	var f := t - _warning
	if f < FALL:
		guardian.lift = HEIGHT * 0.85 * (1.0 - f / FALL)
		guardian.shadow_size = 1.6 - 0.6 * f / FALL
		return ""
	guardian.lift = 0.0
	guardian.shadow_size = -1.0
	if not _landed:
		_landed = true
		guardian.burst(Vector2(0, -2), "Smoke", 10, 0.9, Vector2(0, -10))
		guardian.burst(Vector2(0, -2), "RockGray", 8, 0.6)
		if guardian.bus:
			guardian.bus.publish(GameEvents.GUARDIAN_LANDED)
		guardian.on_landed()
	guardian.eyes.energy = 1.2 * clampf((f - FALL) / _crouch, 0.0, 1.0)
	return "chase" if f >= FALL + _crouch else ""


func animation() -> String:
	return "jump"
