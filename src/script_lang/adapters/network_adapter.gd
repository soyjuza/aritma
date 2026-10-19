## PATRÓN ADAPTER — La red de la Singularidad vista desde el Códice:
##   red.inicio   red.salida   red.cantidad()   red.vecinos(id)   red.distancia(id)
##   red.mas_cercano(id)
##   puentes.levantar(camino)
## Traduce las llamadas a las reglas puras (NetworkRules). Los mensajes de error vienen de
## texts.json (text: Callable(clave, datos) -> String).
class_name NetworkAdapter
extends RefCounted


static func objects(rules: NetworkRules, text: Callable) -> Dictionary:
	return {"red": Network.new(rules, text), "puentes": Bridges.new(rules, text)}


## La red: dónde se empieza, dónde está el núcleo y quién está conectado con quién.
class Network extends ScriptObject:
	var _rules: NetworkRules
	var _text: Callable

	func _init(rules: NetworkRules, text: Callable) -> void:
		_rules = rules
		_text = text

	func type_name() -> String:
		return "red"

	func get_attribute(ctx: ScriptContext, attr: String, line: int) -> Variant:
		match attr:
			"inicio":
				return _rules.start
			"salida":
				return _rules.goal
		return super(ctx, attr, line)

	func get_method(attr: String) -> ScriptCallable:
		match attr:
			"cantidad":
				return HostFunction.new("cantidad", func(_c, _a, _l): return _rules.count(), 0, 0)
			"vecinos":
				return HostFunction.new("vecinos", _neighbors, 1, 1)
			"distancia":
				return HostFunction.new("distancia", _distance, 1, 1)
			"mas_cercano":
				return HostFunction.new("mas_cercano", _closest, 1, 1)
		return null

	func _closest(ctx: ScriptContext, args: Array, line: int):
		var id = args[0]
		if typeof(id) != TYPE_INT or id < 0 or id >= _rules.count():
			ctx.fail(_text.call("network_bad_id", {"id": ScriptContext.to_text(id), "max": _rules.count() - 1}), line)
			return null
		return _rules.closest_neighbor(id)

	func _distance(ctx: ScriptContext, args: Array, line: int):
		var id = args[0]
		if typeof(id) != TYPE_INT or id < 0 or id >= _rules.count():
			ctx.fail(_text.call("network_bad_id", {"id": ScriptContext.to_text(id), "max": _rules.count() - 1}), line)
			return null
		return _rules.distance_to_goal(id)

	func _neighbors(ctx: ScriptContext, args: Array, line: int):
		var id = args[0]
		if typeof(id) != TYPE_INT or id < 0 or id >= _rules.count():
			ctx.fail(_text.call("network_bad_id", {"id": ScriptContext.to_text(id), "max": _rules.count() - 1}), line)
			return null
		return _rules.neighbors(id)


## Los puentes: se levantan una sola vez, siguiendo el camino que se les da.
class Bridges extends ScriptObject:
	var _rules: NetworkRules
	var _text: Callable

	func _init(rules: NetworkRules, text: Callable) -> void:
		_rules = rules
		_text = text

	func type_name() -> String:
		return "puentes"

	func get_method(attr: String) -> ScriptCallable:
		if attr == "levantar":
			return HostFunction.new("levantar", _raise, 1, 1)
		return null

	func _raise(ctx: ScriptContext, args: Array, line: int):
		if _rules.raised:
			ctx.fail(_text.call("network_twice", {}), line)
			return null
		_rules.raised = true
		_rules.path = args[0].duplicate() if typeof(args[0]) == TYPE_ARRAY else args[0]
		return null
