## PATRÓN STATE (comportamiento) — Estado de un guardián. El guardián (contexto) le delega
## cada paso de física; el estado decide qué hace, qué animación muestra, si se le puede
## golpear y a qué estado pasa.
class_name GuardianState
extends RefCounted

var guardian: Guardian
var t := 0.0


func _init(p_guardian: Guardian) -> void:
	guardian = p_guardian


func enter() -> void:
	t = 0.0


func exit() -> void:
	pass


## Un paso de física. Devuelve el nombre del siguiente estado o "" para seguir.
func physics(_delta: float) -> String:
	return ""


## Animación base ("idle", "walk", "attack", "jump"); el guardián le agrega la dirección.
func animation() -> String:
	return "idle"


func hittable() -> bool:
	return false
