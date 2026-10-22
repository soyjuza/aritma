## Patrón Factory Method: crea la Criba (capítulo 3).
class_name FilterBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_1_filtro.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
