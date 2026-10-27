## Borde del mapa que lleva a otro mapa, como en Pokémon.
class_name MapExit
extends TriggerZone

@export var target := ""    # id del mapa (chambers.json, "maps")
@export var entry := ""     # marcador de llegada en Entradas/ del otro mapa


func _init() -> void:
	once = false
