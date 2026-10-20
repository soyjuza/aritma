## Patrón Factory Method: creador base de las salas.
class_name ChamberBuilder
extends RefCounted


func build(data: Dictionary) -> ChamberLevel:
	var chamber := create_level()
	chamber.data = data
	chamber.title = String(data.get("name", ""))
	return chamber


## Cada creador dice qué sala crea.
func create_level() -> ChamberLevel:
	push_error("ChamberBuilder.create_level() debe redefinirse en la subclase")
	return ChamberLevel.new()
