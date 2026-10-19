## Lienzo de la interfaz, encima del mundo. Cubre toda la pantalla, no captura el
## ratón y, al redibujarse, llama a la función que le pasaron (la del estado actual).
class_name OverlayCanvas
extends Control

## La función que dibuja (la pone el juego al arrancar).
var painter: Callable


func _draw() -> void:
	if painter.is_valid():
		painter.call()
