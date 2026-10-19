## PATRÓN FACTORY METHOD — Creador concreto de la Sala 4: La Balanza de los Aritmanos.
class_name BalanceBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_4_balanza.tscn"


func create_level() -> Level:
	return (load(SCENE) as PackedScene).instantiate()
