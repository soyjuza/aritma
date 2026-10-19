## PATRÓN ADAPTER — Una puerta aritmana vista desde el Códice:
##   puerta.abrir()   puerta.cerrar()   puerta.abierta
## Envuelve las funciones reales del nivel (abrir y consultar) sin que el lenguaje las conozca.
class_name DoorAdapter
extends ScriptObject

var _open: Callable
var _close: Callable
var _is_open: Callable


func _init(open_fn: Callable, is_open_fn: Callable, close_fn := Callable()) -> void:
	_open = open_fn
	_is_open = is_open_fn
	_close = close_fn


func type_name() -> String:
	return "puerta"


func get_method(attr: String) -> ScriptCallable:
	match attr:
		"abrir":
			return HostFunction.new("abrir", func(_c, _a, _l): _open.call(), 0, 0)
		"cerrar":
			if _close.is_valid():
				return HostFunction.new("cerrar", func(_c, _a, _l): _close.call(), 0, 0)
	return null


func get_attribute(ctx: ScriptContext, attr: String, line: int):
	if attr == "abierta":
		return bool(_is_open.call())
	return super(ctx, attr, line)
