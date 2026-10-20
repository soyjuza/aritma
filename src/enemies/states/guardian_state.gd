## Patrón State: estado base del guardián.
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


## Devuelve el siguiente estado o "" para seguir.
func physics(_delta: float) -> String:
	return ""


func animation() -> String:
	return "idle"


func hittable() -> bool:
	return false
