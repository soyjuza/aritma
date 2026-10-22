## Mapa de un capítulo (el Bosque). La entrada de las ruinas lleva a sus salas.
class_name HubLevel
extends Level


func wire() -> void:
	objective_key = String(data.get("objective_key", ""))
	$Zonas/EntradaRuinas.crossed.connect(func(): _game.enter_temple())
