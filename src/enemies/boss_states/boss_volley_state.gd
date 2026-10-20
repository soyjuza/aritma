## Patrón State: ráfaga de orbes hacia Tala.
class_name BossVolleyState
extends BossState

const ORB := preload("res://scenes/enemigos/orbe.tscn")


func enter() -> void:
	super()
	boss.publish(GameEvents.GUARDIAN_CHARGING)


func physics(delta: float) -> String:
	t += delta
	boss.brake(delta)
	if t >= boss.volley_fire_at and t - delta < boss.volley_fire_at:
		_fire_fan(boss.orbs_per_phase[boss.phase])
	return "chase" if t >= boss.anim_length("attack") else ""


func animation() -> String:
	return "attack"


func _fire_fan(count: int) -> void:
	var p := boss.player()
	if p == null:
		return
	var from := boss.global_position + Vector2(0, -16)
	var aim := (p.global_position + Vector2(0, -4) - from).angle()
	for i in count:
		var orb: RuneOrb = ORB.instantiate()
		var angle := aim + (i - (count - 1) / 2.0) * boss.orb_spread
		orb.position = boss.get_parent().to_local(from)
		orb.velocity = Vector2.from_angle(angle) * boss.orb_speed
		orb.color = ZeroBoss.RED
		orb.damage = 1
		orb.life = boss.orb_life
		boss.get_parent().add_child(orb)
	boss.publish(GameEvents.ORB_FIRED)
