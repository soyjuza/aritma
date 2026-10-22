## Patrón Strategy: un tipo de problema del jefe.
class_name QuizProblem
extends RefCounted

var _text: Callable


func _init(text: Callable, settings: Dictionary = {}) -> void:
	_text = text
	for key in settings.keys():
		if key in self:
			set(key, settings[key] if settings[key] is Array else int(settings[key]))


func make(_rng: RandomNumberGenerator) -> Dictionary:
	push_error("QuizProblem.make() debe redefinirse en la subclase")
	return {}


func say(key: String, params: Dictionary = {}) -> String:
	return String(_text.call(key, params)) if _text.is_valid() else key
