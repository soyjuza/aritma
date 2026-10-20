## Patrón State: el jefe sale del abismo.
class_name BossAppearState
extends BossState


func enter() -> void:
	super()
	boss.visible = true
	boss.position = boss.home
	boss.body_shape.set_deferred("disabled", false)
	boss.bar.visible = true
	boss.publish(GameEvents.BOSS_APPEARED)


func physics(delta: float) -> String:
	t += delta
	boss.lift = 0.0
	return "chase" if t >= boss.anim_length("appear") + boss.appear_pause else ""


func animation() -> String:
	return "appear"


func hittable() -> bool:
	return false
