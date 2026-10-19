## PATRÓN OBSERVER (sujeto).
## Los objetos que producen eventos (reglas, casillas, temporizador) solo publican;
## no saben quién escucha. Los observadores (sonido, estadísticas, libro de reglas, HUD)
## se suscriben sin que el emisor cambie. Esto mantiene bajo el acoplamiento.
class_name EventBus
extends RefCounted

var _subscribers: Dictionary = {}  # StringName -> Array[Callable]


func subscribe(event: StringName, callback: Callable) -> void:
	if not _subscribers.has(event):
		_subscribers[event] = []
	_subscribers[event].append(callback)


func unsubscribe(event: StringName, callback: Callable) -> void:
	if _subscribers.has(event):
		_subscribers[event].erase(callback)


func publish(event: StringName, payload: Dictionary = {}) -> void:
	for callback in _subscribers.get(event, []).duplicate():
		if callback.is_valid():
			callback.call(payload)
