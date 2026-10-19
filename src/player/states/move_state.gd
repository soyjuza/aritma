## PATRÓN STATE (comportamiento) — Estado de movimiento de Tala. El jugador (contexto) le
## delega cada paso de física; el estado decide la velocidad, la animación y a qué estado
## pasar. Así no hay un gran "match" de casos en el controlador.
class_name MoveState
extends RefCounted

var player: PlayerController


func _init(p_player: PlayerController) -> void:
	player = p_player


func enter(_previous: String) -> void:
	pass


func exit() -> void:
	pass


## Un paso de física. Devuelve el nombre del siguiente estado o "" para seguir.
func physics(_delta: float) -> String:
	return ""


## Animación base ("idle", "walk", "jump"); el controlador le agrega la dirección.
func animation() -> String:
	return "idle"


func animation_speed() -> float:
	return 1.0
