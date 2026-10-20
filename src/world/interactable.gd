## Algo que se usa con E. El nivel conecta la señal used.
class_name Interactable
extends Area2D

signal used

const LAYER := 1 << 3

@export var prompt_key := "prompt_read"


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func interact() -> void:
	used.emit()
