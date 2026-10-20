## Punto seguro: si Tala cae vuelve aquí.
class_name CheckpointZone
extends TriggerZone


func point() -> Vector2:
	return ($Punto as Marker2D).global_position
