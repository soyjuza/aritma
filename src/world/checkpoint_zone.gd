## Punto seguro: al cruzar la zona, si Tala cae o la aplastan, vuelve al Marker2D «Punto».
class_name CheckpointZone
extends TriggerZone


func point() -> Vector2:
	return ($Punto as Marker2D).global_position
