## Lienzo de la interfaz encima del mundo.
class_name OverlayCanvas
extends Control

var painter: Callable


func _draw() -> void:
	if painter.is_valid():
		painter.call()
