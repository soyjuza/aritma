## Patrón State: persigue a Tala y cada cierto tiempo ataca.
class_name BossChaseState
extends BossState


func physics(delta: float) -> String:
	t += delta
	var p := boss.player()
	if p == null:
		return ""
	var to := p.global_position - boss.global_position
	var want := Vector2.ZERO
	if to.length() > boss.keep_distance:
		want = to.normalized() * boss.speed * (1.0 + boss.speed_per_phase * boss.phase)
	boss.velocity = boss.velocity.move_toward(want, boss.accel * delta)
	boss.move_and_slide()
	boss.sprite.flip_h = to.x < 0.0
	if to.length() < boss.radius + 6.0 and not p.airborne:
		p.hurt(boss.touch_damage, boss.global_position)
	boss.next_attack -= delta
	if boss.next_attack > 0.0:
		return ""
	boss.next_attack = boss.attack_every - boss.attack_every_step * boss.phase
	return "slam" if to.length() < boss.slam_range else "volley"


func animation() -> String:
	return "walk" if boss.velocity.length() > 5.0 else "idle"
