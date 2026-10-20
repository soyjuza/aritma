## Patrón State: espera en su lugar hasta que Tala se acerca.
class_name BossWaitState
extends BossState


func physics(delta: float) -> String:
	t += delta
	boss.return_home()
	var p := boss.player()
	if p and t > boss.wake_delay and p.global_position.distance_to(boss.position) < boss.wake_distance:
		return "chase"
	return ""
