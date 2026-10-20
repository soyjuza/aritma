## Patrón Factory Method: crea la Sala 1.
class_name FilterBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_1_filtro.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
