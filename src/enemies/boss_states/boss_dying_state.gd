## Patrón State: el jefe vencido se desvanece.
class_name BossDyingState
extends BossState

const FADE_START := 1.0


func enter() -> void:
	super()
	boss.body_shape.set_deferred("disabled", true)
	boss.publish(GameEvents.BOSS_DEFEATED)


func physics(delta: float) -> String:
	t += delta
	boss.modulate.a = 1.0 - clampf((t - FADE_START) / (boss.dying_time - FADE_START), 0.0, 1.0)
	if randf() < 0.15:
		var burst := NumberBurst.new()
		burst.count = 3
		burst.tint = ZeroBoss.RED if randf() < 0.5 else ZeroBoss.CYAN
		burst.position = boss.position + Vector2(randf_range(-14, 14), randf_range(-30, -6))
		boss.get_parent().add_child(burst)
	if t < boss.dying_time:
		return ""
	boss.modulate.a = 1.0
	boss.defeated.emit()
	return "hidden"


func animation() -> String:
	return "hit"


func hittable() -> bool:
	return false
