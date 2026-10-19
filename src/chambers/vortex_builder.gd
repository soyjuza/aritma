## PATRÓN FACTORY METHOD — Creador concreto de la Sala 3: El Vórtice de Celdas.
class_name VortexBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_3_vortice.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
