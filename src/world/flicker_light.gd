## Luz de fuego (antorchas y braseros): la energía tiembla un poco, como una llama.
## phase separa unas llamas de otras (negativa = una al azar al empezar).
class_name FlickerLight
extends PointLight2D

@export var base_energy := 1.0
@export var phase := -1.0

var _time := 0.0


func _ready() -> void:
	if phase < 0.0:
		phase = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	energy = base_energy * (1.0 + sin(_time * 9.0 + phase) * 0.12 + sin(_time * 23.0 + phase / 1.7) * 0.08)
