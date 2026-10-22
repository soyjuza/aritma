## Patrón Adapter: la Compuerta en el Códice (compuerta.subir(nivel)).
class_name LockAdapter
extends ScriptObject

var _raise: Callable


func _init(raise_fn: Callable) -> void:
	_raise = raise_fn


func type_name() -> String:
	return "compuerta"


func get_method(attr: String) -> ScriptCallable:
	if attr == "subir":
		return HostFunction.new("subir", _subir, 1, 1)
	return null


func _subir(ctx: ScriptContext, args: Array, line: int):
	var n = args[0]
	if not (n is int or n is float):
		ctx.fail(ScriptMessages.text("compuerta_numero"), line)
		return null
	_raise.call(int(n))
	return null
