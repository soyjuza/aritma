## Reja (o sello) de bronce que cierra un paso. Los barrotes, el piso que queda debajo, el
## polvo y la luz son nodos hijos: se ven y se acomodan en el editor. open() la levanta y
## close() la vuelve a bajar. «Umbral» (opcional) es un bloqueo extra que se quita al abrir
## y no vuelve (la oscuridad de la puerta del templo).
class_name Grate
extends Node2D

var is_open := false

@onready var _bars: Node2D = $Barrotes
@onready var _floor: Node2D = $Piso
@onready var _body: StaticBody2D = $Cuerpo
@onready var _dust: CPUParticles2D = $Polvo


func open() -> void:
	if is_open:
		return
	is_open = true
	_dust.emitting = true
	_bars.visible = false
	_floor.visible = true
	_set_solid(_body, false)
	if has_node("Umbral"):
		_set_solid($Umbral, false)
		$Umbral.visible = false     # también deja de tapar la luz
	if has_node("Luz"):
		$Luz.visible = true


func close() -> void:
	if not is_open:
		return
	is_open = false
	_bars.visible = true
	_set_solid(_body, true)


static func _set_solid(body: StaticBody2D, on: bool) -> void:
	for shape in body.get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled", not on)
