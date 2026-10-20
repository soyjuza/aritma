## Patrón State: escudo de fase mientras Tala responde el problema.
class_name BossShieldState
extends BossState

const MIN_TIME := 1.0


func enter() -> void:
	super()
	boss.awaiting_answer = true
	boss.publish(GameEvents.BOSS_SHIELD)
	boss.shielded.emit()


func physics(delta: float) -> String:
	t += delta
	boss.return_home()
	if t > MIN_TIME and not boss.awaiting_answer and (boss.alarm == null or not boss.alarm.fighting()):
		boss.shield_down.emit()
		return "chase"
	return ""


func hittable() -> bool:
	return false
