## Patrón Factory Method: crea la Sala 5.
class_name CoreBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_5_singularidad.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
