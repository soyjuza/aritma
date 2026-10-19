## PATRÓN FACTORY METHOD — Creador abstracto de cámaras de desafío.
## build() es el paso común (crear el nivel y pasarle sus datos de chambers.json); el
## método fábrica create_level() lo redefine cada creador concreto para decidir qué
## escena de cámara se instancia. Una cámara nueva es una escena y un creador nuevos, sin
## tocar los demás.
class_name ChamberBuilder
extends RefCounted


func build(data: Dictionary) -> Level:
	var chamber := create_level()
	chamber.data = data
	chamber.title = String(data.get("name", ""))
	return chamber


## Método fábrica: la cámara concreta de este tipo.
func create_level() -> Level:
	push_error("ChamberBuilder.create_level() debe redefinirse en la subclase")
	return Level.new()
