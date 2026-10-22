## Patrón Adapter: el sensor de la Compuerta en el Códice (sensor.leer()).
class_name SensorAdapter
extends ScriptObject

var value := 0


func _init(p_value: int) -> void:
	value = p_value


func type_name() -> String:
	return "sensor"


func get_method(attr: String) -> ScriptCallable:
	if attr == "leer":
		return HostFunction.new("leer", func(_c, _a, _l): return value, 0, 0)
	return null
