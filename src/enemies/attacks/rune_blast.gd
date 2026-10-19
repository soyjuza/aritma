## PATRÓN STRATEGY — Estrategia concreta del guardián rúnico: no golpea; se carga un buen rato
## (el círculo rojo del suelo marca el alcance) y explota. Si Tala sigue dentro del círculo,
## el juego le pone el reto de teclas. El rúnico se destruye en su propia explosión.
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
