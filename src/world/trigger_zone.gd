## Zona invisible que avisa (señal crossed) cuando Tala la cruza. Su forma es el
## CollisionShape2D hijo. once: solo avisa la primera vez.
class_name TriggerZone
extends Area2D

signal crossed

@export var once := true

var _fired := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and not (once and _fired):
		_fired = true
		crossed.emit()
