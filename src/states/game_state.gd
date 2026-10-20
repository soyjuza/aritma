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


## ¿Corre el reloj?
func timer_runs() -> bool:
	return false

