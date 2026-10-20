## Patrón Strategy: el rúnico se carga y explota.
class_name RuneBlast
extends GuardianAttack


func windup_time() -> float:
	return 1.5


func cooldown() -> float:
	return 9.0


func perform(guardian: Guardian, player: PlayerController) -> void:
	var runic := guardian as RunicGuardian
	var caught := player != null and not player.dead and not player.falling \
		and player.global_position.distance_to(guardian.global_position) <= runic.blast_radius
	runic.explosion_fx()
	if guardian.bus:
		guardian.bus.publish(GameEvents.RUNE_BLAST, {"caught": caught})
	guardian.blow_up.call_deferred()
