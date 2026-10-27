## Rocas que tapan un camino hasta vencer al jefe del capítulo anterior.
class_name Barrier
extends Node2D

## Capítulo que abre el camino (1 = al vencer al Guardián del Cero).
@export var need := 1
@export var text_key := "barrier_rocks"

var is_open := false

@onready var reading: Interactable = $Lectura


func set_open(on: bool) -> void:
	is_open = on
	visible = not on
	for body in find_children("*", "StaticBody2D", true, false):
		for shape in body.get_children():
			if shape is CollisionShape2D:
				shape.set_deferred("disabled", on)
	reading.collision_layer = 0 if on else Interactable.LAYER


## Se deshacen con polvo (al volver del jefe).
func crumble() -> void:
	($Polvo as CPUParticles2D).emitting = true
	var tween := create_tween()
	tween.tween_property($Rocas, "modulate:a", 0.0, 0.9)
	tween.tween_callback(_gone)


func _gone() -> void:
	set_open(true)
	visible = true    # el polvo sigue a la vista
	$Rocas.visible = false
