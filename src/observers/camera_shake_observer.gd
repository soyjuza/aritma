## Patrón Observer: hace temblar la cámara con algunos eventos.
class_name CameraShakeObserver
extends RefCounted

var _rig: CameraRig


func _init(bus: EventBus, rig: CameraRig, table: Dictionary) -> void:
	_rig = rig
	for event in table.keys():
		var amount := float(table[event])
		bus.subscribe(StringName(event), func(_payload): _rig.shake(amount))
