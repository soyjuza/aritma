## Patrón Factory Method: crea la Sala 1.
class_name LockBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_1_compuerta.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
