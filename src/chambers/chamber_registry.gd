## Registro de creadores de cámaras por tipo ("filter", ...), según el
## campo "kind" de chambers.json. Agregar una cámara es registrar su creador (Abierto/Cerrado).
class_name ChamberRegistry
extends RefCounted

static var _builders: Dictionary = {}


static func register(kind: String, builder: ChamberBuilder) -> void:
	_builders[kind] = builder


static func create(data: Dictionary) -> Level:
	if _builders.is_empty():
		_register_defaults()
	var kind := String(data.get("kind", ""))
	assert(_builders.has(kind), "No hay creador registrado para la cámara: " + kind)
	return _builders[kind].build(data)


static func _register_defaults() -> void:
	register("filter", FilterBuilder.new())
	register("roots", RootsBuilder.new())
	register("vortex", VortexBuilder.new())
	register("balance", BalanceBuilder.new())
	register("core", CoreBuilder.new())
	register("throne", ThroneBuilder.new())
