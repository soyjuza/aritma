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


## Opciones con la respuesta y errores típicos, sin repetir. {options, answer}
static func pick(right: int, wrong: Array, count: int) -> Dictionary:
	var choices := [right]
	for w in wrong + [right + 1, right - 1, right + 2, right + 3]:
		if choices.size() < count and not w in choices and w >= 0:
			choices.append(w)
	choices.shuffle()
	return {"options": choices.map(func(n): return str(n)), "answer": choices.find(right)}
