## Patrón Factory Method: crea la Sala 3.
class_name VortexBuilder
extends ChamberBuilder

const SCENE := "res://scenes/niveles/sala_3_vortice.tscn"


func create_level() -> ChamberLevel:
	return (load(SCENE) as PackedScene).instantiate()
