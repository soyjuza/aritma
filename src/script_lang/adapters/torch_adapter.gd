## Patrón Adapter: los braseros de la práctica en el Códice (antorchas.encender()).
class_name TorchAdapter
extends ScriptObject

var lit := 0
var total := 5


func _init(p_lit: int, p_total: int) -> void:
	lit = p_lit
	total = p_total


func type_name() -> String:
	return "antorchas"


func get_method(attr: String) -> ScriptCallable:
	match attr:
		"encender":
			return HostFunction.new("encender", func(_c, _a, _l): lit = mini(lit + 1, total), 0, 0)
		"apagar":
			return HostFunction.new("apagar", func(_c, _a, _l): lit = maxi(lit - 1, 0), 0, 0)
		"quedan":
			return HostFunction.new("quedan", func(_c, _a, _l): return total - lit, 0, 0)
	return null
