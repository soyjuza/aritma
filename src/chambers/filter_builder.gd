## PATRÓN FACTORY METHOD — Creador concreto de la Sala 1: El Filtro de la Dualidad.
class_name FilterBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_1_filtro.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
