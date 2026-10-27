## Creadores de salas según el "kind" de chambers.json.
class_name ChamberRegistry
extends RefCounted

static var _builders: Dictionary = {}


static func register(kind: String, builder: ChamberBuilder) -> void:
	_builders[kind] = builder


static func create(data: Dictionary) -> ChamberLevel:
	if _builders.is_empty():
		_register_defaults()
	var kind := String(data.get("kind", ""))
	assert(_builders.has(kind), "No hay creador registrado para la cámara: " + kind)
	return _builders[kind].build(data)


static func _register_defaults() -> void:
	register("lock", LockBuilder.new())
	register("filter", FilterBuilder.new())
	register("roots", RootsBuilder.new())
	register("vortex", VortexBuilder.new())
	register("figures", FigureBuilder.new())
	register("core", CoreBuilder.new())
	register("throne", ThroneBuilder.new())
	register("bridge", SceneBuilder.new("res://scenes/niveles/bosque_1_puente.tscn"))
	register("garden", SceneBuilder.new("res://scenes/niveles/bosque_2_jardin.tscn"))
	register("pump", SceneBuilder.new("res://scenes/niveles/cueva_1_bomba.tscn"))
	register("mill", SceneBuilder.new("res://scenes/niveles/mirador_1_molino.tscn"))
	register("bells", SceneBuilder.new("res://scenes/niveles/cima_1_campanas.tscn"))
	register("scale", SceneBuilder.new("res://scenes/niveles/cima_2_balanza.tscn"))
	register("twins", SceneBuilder.new("res://scenes/niveles/cima_3_gemelas.tscn"))
