## Patrón State: estado base del jefe.
class_name BossState
extends RefCounted

var boss: ZeroBoss
var t := 0.0


func _init(p_boss: ZeroBoss) -> void:
	boss = p_boss


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
	return true


## Avisos que dibuja este estado.
func draw() -> void:
	pass
