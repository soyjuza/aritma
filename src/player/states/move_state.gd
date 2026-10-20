## Patrón State: estado base del movimiento de Tala.
class_name MoveState
extends RefCounted

var player: PlayerController


func _init(p_player: PlayerController) -> void:
	player = p_player


func enter(_previous: String) -> void:
	pass


func exit() -> void:
	pass


## Devuelve el siguiente estado o "" para seguir.
func physics(_delta: float) -> String:
	return ""


func animation() -> String:
	return "idle"


func animation_speed() -> float:
	return 1.0


## Al correr no recupera aliento.
func regenerates_stamina() -> bool:
	return true


## El golpe se corta si Tala muere.
func stops_on_death() -> bool:
	return false
