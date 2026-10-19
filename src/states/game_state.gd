## PATRÓN STATE — Estado del juego abstracto.
## Cada fase (título, menú, historia, juego, Códice, pausa, libro, ajustes, final) decide
## cómo reaccionar a las teclas y al mouse, cómo actualizarse y cómo dibujar su interfaz.
## Game delega todo en el estado actual, sin cadenas de if/match por fase.
class_name GameState
extends RefCounted

var game  # Game: contexto que expone los servicios (datos, audio, mundo, jugador...)


func _init(context) -> void:
	game = context


func enter(_params: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


## actions: acciones del InputMap que se acaban de presionar ("ui_up", "accept", "pause"...)
func handle_input(_actions: Array) -> void:
	pass


## Una tecla cualquiera (no solo las acciones). Devuelve true si el estado la usó; así el
## reto de teclas recibe A, S, D... aunque también muevan a Tala.
func handle_key(_event: InputEventKey) -> bool:
	return false


func update(_delta: float) -> void:
	pass


func draw(_ui: UIKit) -> void:
	pass


## ¿Se congela el mundo (guardianes, prensas, Tala) mientras este estado está activo?
func freezes_world() -> bool:
	return false


## ¿Corre el reloj de 15 minutos mientras este estado está activo?
func timer_runs() -> bool:
	return false

