## Patrón Factory Method: crea la Sala 4.
class_name FigureBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_4_figuras.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
