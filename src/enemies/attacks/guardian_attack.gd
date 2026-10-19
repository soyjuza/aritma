## PATRÓN STRATEGY — Cómo ataca un guardián. El guardián no sabe si da un golpe o explota:
## pregunta cuánto tarda en prepararlo, cuánto descansa y le pide a la estrategia que lo
## haga. Otro tipo de guardián es otra estrategia, sin tocar sus estados.
class_name GuardianAttack
extends RefCounted


## Segundos que brilla antes de atacar (el aviso para Tala).
func windup_time() -> float:
	return 0.45


## Segundos de descanso después de atacar.
func cooldown() -> float:
	return 0.9


## El instante del ataque.
func perform(_guardian: Guardian, _player: PlayerController) -> void:
	pass
