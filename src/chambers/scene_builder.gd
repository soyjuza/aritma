## Patrón Factory Method: crea una sala a partir de la ruta de su escena.
class_name SceneBuilder
extends ChamberBuilder

var _scene: String


func _init(scene: String) -> void:
	_scene = scene


func create_level() -> ChamberLevel:
	return (load(_scene) as PackedScene).instantiate()
