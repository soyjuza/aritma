## PATRÓN ADAPTER — Las luces del Faro vistas desde el Códice:
##   luces.encender()   luces.apagar()   luces.encendidas
## Igual que la puerta del pueblo: envuelve las funciones del Faro sin que el lenguaje las conozca.
class_name LightsAdapter
extends ScriptObject

var _turn_on: Callable
var _turn_off: Callable
var _is_on: Callable


func _init(on_fn: Callable, is_on_fn: Callable, off_fn: Callable) -> void:
	_turn_on = on_fn
	_is_on = is_on_fn
	_turn_off = off_fn


func type_name() -> String:
	return "luces"


func get_method(attr: String) -> ScriptCallable:
	match attr:
		"encender":
			return HostFunction.new("encender", func(_c, _a, _l): _turn_on.call(), 0, 0)
		"apagar":
			return HostFunction.new("apagar", func(_c, _a, _l): _turn_off.call(), 0, 0)
	return null


func get_attribute(ctx: ScriptContext, attr: String, line: int):
	if attr == "encendidas":
		return bool(_is_on.call())
	return super(ctx, attr, line)
