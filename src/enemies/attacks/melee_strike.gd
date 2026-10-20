## Patrón Strategy: golpe de puño del caballero.
class_name MeleeStrike
extends GuardianAttack


func perform(guardian: Guardian, player: PlayerController) -> void:
	if player == null:
		return
	if (player.global_position - guardian.global_position).length() <= guardian.reach + 8.0:
		player.hurt(guardian.damage, guardian.global_position)
