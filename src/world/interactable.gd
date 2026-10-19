## Algo que el jugador puede usar con E: un personaje, una inscripción, una máquina. Es un
## área invisible; su tamaño es el del CollisionShape2D hijo (se ajusta en el editor). El texto
## de ayuda se elige en el Inspector (prompt_key) y lo que pasa al usarlo lo conecta el nivel a
## la señal used.
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
