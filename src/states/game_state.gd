## Patrón State: estado base del juego. Game le pasa todo al estado actual.
class_name GameState
extends RefCounted

var game


func _init(context) -> void:
	game = context


func enter(_params: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


## Acciones presionadas.
func handle_input(_actions: Array) -> void:
	pass


## Cualquier tecla. true si el estado la usó.
func handle_key(_event: InputEventKey) -> bool:
	return false


## Mouse. true si el estado lo usó.
func handle_mouse(_event: InputEventMouse) -> bool:
	return false


func update(_delta: float) -> void:
	pass


func draw(_ui: UIKit) -> void:
	pass


## ¿Se congela el mundo?
func freezes_world() -> bool:
	return false


# En el celular: qué controles táctiles muestra cada estado

## Botones (acciones de config.json).
func touch_buttons() -> Array:
	return []


## Acción al tocar fuera de los botones ("" = ninguna).
func touch_tap() -> String:
	return ""


## ¿Se muestra la palanca?
func touch_stick() -> bool:
	return false


## Teclas en pantalla (reto del rúnico).
func touch_keys() -> Array:
	return []
