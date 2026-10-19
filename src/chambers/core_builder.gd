## PATRÓN FACTORY METHOD — Creador concreto de la Sala 5: La Singularidad del Cero.
class_name CoreBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_5_singularidad.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
