## PATRÓN ADAPTER — Las piezas de la Criba vistas desde el Códice:
##   tolva.quedan()   tolva.soltar()   caliz.recibir()   crisol.desintegrar()
## Cada objeto traduce sus llamadas a las reglas puras (ParityFilter). Los mensajes de error
## vienen de texts.json (text: Callable(clave, datos) -> String).
class_name FilterAdapter
extends RefCounted


static func objects(rules: ParityFilter, text: Callable) -> Dictionary:
	return {
		"tolva": Hopper.new(rules, text),
		"caliz": Outlet.new(rules, text, true),
		"crisol": Outlet.new(rules, text, false),
	}


## La tolva: cuántas esferas quedan y soltar la siguiente.
class Hopper extends ScriptObject:
	var _rules: ParityFilter
	var _text: Callable

	func _init(rules: ParityFilter, text: Callable) -> void:
		_rules = rules
		_text = text

	func type_name() -> String:
		return "tolva"

	func get_method(attr: String) -> ScriptCallable:
		match attr:
			"quedan":
				return HostFunction.new("quedan", func(_c, _a, _l): return _rules.remaining(), 0, 0)
			"soltar":
				return HostFunction.new("soltar", _release, 0, 0)
		return null

	func _release(ctx: ScriptContext, _args: Array, line: int):
		var error := _rules.release()
		if error != "":
			ctx.fail(_text.call("criba_" + error, {"n": _rules.held()}), line)
			return null
		return _rules.held() if _rules.held() != null else 0


## El cáliz (pares) o el crisol (impares): recibe la esfera que está en la compuerta.
class Outlet extends ScriptObject:
	var _rules: ParityFilter
	var _text: Callable
	var _chalice: bool

	func _init(rules: ParityFilter, text: Callable, chalice: bool) -> void:
		_rules = rules
		_text = text
		_chalice = chalice

	func type_name() -> String:
		return "caliz" if _chalice else "crisol"

	func get_method(attr: String) -> ScriptCallable:
		var method := "recibir" if _chalice else "desintegrar"
		if attr == method:
			return HostFunction.new(method, _send, 0, 0)
		return null

	func _send(ctx: ScriptContext, _args: Array, line: int):
		var error := _rules.send(_chalice)
		if error != "":
			ctx.fail(_text.call("criba_" + error, {}), line)
		return null
