## Patrón Factory Method: crea la Sala 2.
class_name RootsBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_2_raices.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
