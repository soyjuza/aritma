## PATRÓN STRATEGY — Estrategia concreta del centinela de piedra: un golpe de puño que quita
## medio corazón si Tala sigue al alcance cuando lo suelta.
class_name MeleeStrike
extends GuardianAttack


func perform(guardian: Guardian, player: PlayerController) -> void:
	if player == null:
		return
	if (player.global_position - guardian.global_position).length() <= guardian.reach + 8.0:
		player.hurt(guardian.damage, guardian.global_position)
