## Patrón State: se deshace en números.
class_name DyingState
extends GuardianState


func enter() -> void:
	super()
	guardian.velocity = Vector2.ZERO
	var numbers := NumberBurst.new()
	numbers.position = guardian.position + Vector2(0, -6)
	guardian.get_parent().add_child(numbers)
	guardian.burst(Vector2(0, -6), "Smoke", 8, 0.8, Vector2(0, -20))
	guardian.visible = false
	guardian.body_shape.set_deferred("disabled", true)
	if guardian.bus:
		guardian.bus.publish(GameEvents.GUARDIAN_DEFEATED)
	guardian.defeated.emit(guardian)
	if guardian.from_ceiling:
		guardian.queue_free()
