## Patrón Strategy: cómo ataca un guardián.
class_name GuardianAttack
extends RefCounted


## Segundos que brilla antes de atacar.
func windup_time() -> float:
	return 0.45


## Segundos de descanso después de atacar.
func cooldown() -> float:
	return 0.9


## Hace el ataque.
func perform(_guardian: Guardian, _player: PlayerController) -> void:
	pass
