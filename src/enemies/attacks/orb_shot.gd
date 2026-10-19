## PATRÓN STRATEGY — Estrategia concreta del hechicero: lanza un orbe que vuela hacia donde
## estaba Tala. Se esquiva moviéndose, y el garrote lo deshace en el aire.
class_name OrbShot
extends GuardianAttack

const ORB := preload("res://scenes/enemigos/orbe.tscn")


func windup_time() -> float:
	return 0.65


func cooldown() -> float:
	return 1.9


func perform(guardian: Guardian, player: PlayerController) -> void:
	if player == null:
		return
	var orb: RuneOrb = ORB.instantiate()
	var from := guardian.global_position + Vector2(guardian.facing.x * 6.0, -6.0)
	orb.position = guardian.get_parent().to_local(from)
	orb.velocity = (player.global_position + Vector2(0, -4) - from).normalized() * orb.speed
	orb.damage = guardian.damage
	orb.color = guardian.ring_color
	guardian.get_parent().add_child(orb)
	if guardian.bus:
		guardian.bus.publish(GameEvents.ORB_FIRED)
