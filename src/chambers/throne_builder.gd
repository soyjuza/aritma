## Patrón Factory Method: crea la Sala 6.
class_name ThroneBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_6_trono.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
