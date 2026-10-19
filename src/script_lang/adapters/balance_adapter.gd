## PATRÓN ADAPTER — La Balanza vista desde el Códice:
##   pesas.lista()   pesas.cantidad()   plato_izq.poner(i)   plato_der.poner(i)   plato_izq.peso()
##   plato_liviano()  (el plato que pesa menos; si empatan, el izquierdo)
## Cada objeto traduce sus llamadas a las reglas puras (BalanceRules). Los mensajes de error
## vienen de texts.json (text: Callable(clave, datos) -> String).
class_name BalanceAdapter
extends RefCounted


static func objects(rules: BalanceRules, text: Callable) -> Dictionary:
	var left := Plate.new(rules, text, BalanceRules.LEFT)
	var right := Plate.new(rules, text, BalanceRules.RIGHT)
	var lighter := func(_c, _a, _l): return left if rules.total(BalanceRules.LEFT) <= rules.total(BalanceRules.RIGHT) else right
	return {
		"pesas": Weights.new(rules),
		"plato_izq": left,
		"plato_der": right,
		"plato_liviano": HostFunction.new("plato_liviano", lighter, 0, 0),
	}


## Las pesas: su lista de valores (una copia) y cuántas son.
class Weights extends ScriptObject:
	var _rules: BalanceRules

	func _init(rules: BalanceRules) -> void:
		_rules = rules

	func type_name() -> String:
		return "pesas"

	func get_method(attr: String) -> ScriptCallable:
		match attr:
			"lista":
				return HostFunction.new("lista", func(_c, _a, _l): return _rules.weights.duplicate(), 0, 0)
			"cantidad":
				return HostFunction.new("cantidad", func(_c, _a, _l): return _rules.weights.size(), 0, 0)
		return null


## Un plato: poner(i) pone la pesa número i; peso() dice cuánto suma ese plato.
class Plate extends ScriptObject:
	var _rules: BalanceRules
	var _text: Callable
	var _side: int

	func _init(rules: BalanceRules, text: Callable, side: int) -> void:
		_rules = rules
		_text = text
		_side = side

	func type_name() -> String:
		return "plato_izq" if _side == BalanceRules.LEFT else "plato_der"

	func get_method(attr: String) -> ScriptCallable:
		match attr:
			"poner":
				return HostFunction.new("poner", _put, 1, 1)
			"peso":
				return HostFunction.new("peso", func(_c, _a, _l): return _rules.total(_side), 0, 0)
		return null

	func _put(ctx: ScriptContext, args: Array, line: int):
		var error := _rules.put(args[0], _side)
		if error != "":
			ctx.fail(_text.call("balance_" + error, {"i": ScriptContext.to_text(args[0]), "max": _rules.weights.size() - 1}), line)
		return null
