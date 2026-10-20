## Patrón Observer: canal de eventos. Quien publica no sabe quién escucha.
class_name EventBus
extends RefCounted

var _subscribers: Dictionary = {}


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
