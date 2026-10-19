## PATRÓN FACTORY METHOD — Creador concreto de la Sala 6: El Trono del Cero (el jefe final).
class_name ThroneBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_6_trono.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
