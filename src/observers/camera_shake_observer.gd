## PATRÓN OBSERVER — Observador concreto: hace temblar la cámara con los eventos fuertes
## (una caída alta, un mecanismo pesado). La tabla evento → intensidad viene de config.json;
## quien publica el evento no sabe que la cámara tiembla.
class_name CameraShakeObserver
extends RefCounted

var _rig: CameraRig


func _init(bus: EventBus, rig: CameraRig, table: Dictionary) -> void:
	_rig = rig
	for event in table.keys():
		var amount := float(table[event])
		bus.subscribe(StringName(event), func(_payload): _rig.shake(amount))
