## Zona invisible que avisa cuando Tala la cruza.
class_name TriggerZone
extends Area2D

signal crossed

@export var once := true

var _fired := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


## Marcarla sin avisar (al cargar partida).
func mark_fired() -> void:
	_fired = true


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and not (once and _fired):
		_fired = true
		crossed.emit()
