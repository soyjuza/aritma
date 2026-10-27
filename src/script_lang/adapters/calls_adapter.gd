## Patrón Adapter: un objeto del juego con métodos simples (carreta.peso(), maceta.regar()...).
class_name CallsAdapter
extends ScriptObject

var _name: String
var _methods: Dictionary    # nombre → Callable (con o sin argumentos)


func _init(p_name: String, methods: Dictionary) -> void:
	_name = p_name
	_methods = methods


func type_name() -> String:
	return _name


func get_method(attr: String) -> ScriptCallable:
	if _methods.has(attr):
		var fn: Callable = _methods[attr]
		var count := fn.get_argument_count()
		return HostFunction.new(attr, func(_c, a, _l): return fn.callv(a), count, count)
	return null
