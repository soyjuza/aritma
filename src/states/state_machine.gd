## PATRÓN STATE — Máquina de estados: guarda el estado actual y hace las transiciones.
class_name StateMachine
extends RefCounted

var current: GameState
var current_name := ""
var _states: Dictionary = {}


func add(state_name: String, state: GameState) -> void:
	_states[state_name] = state


func get_state(state_name: String) -> GameState:
	return _states[state_name]


func change(state_name: String, params: Dictionary = {}) -> void:
	assert(_states.has(state_name), "Estado desconocido: " + state_name)
	if current:
		current.exit()
	current = _states[state_name]
	current_name = state_name
	current.enter(params)
