## PATRÓN FACTORY METHOD — Creador concreto de la Sala 4: La Mesa de las Figuras.
class_name FigureBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_4_figuras.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
