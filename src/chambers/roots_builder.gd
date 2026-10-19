## PATRÓN FACTORY METHOD — Creador concreto de la Sala 2: Las Raíces Gemelas.
class_name RootsBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_2_raices.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
