## Problemas del jefe. Elige la estrategia (QuizProblem) según el nombre.
class_name BossQuiz
extends RefCounted

var _problems: Dictionary = {}


## settings: chambers.json, quiz.problems.
func _init(text: Callable = Callable(), settings: Dictionary = {}) -> void:
	_problems = {
		"paridad": ParityProblem.new(text, settings.get("paridad", {})),
		"multiplo": MultipleProblem.new(text, settings.get("multiplo", {})),
		"despejar": SolveProblem.new(text, settings.get("despejar", {})),
	}


func kinds() -> Array:
	return _problems.keys()


## Un problema nuevo del tipo kind.
func make(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	assert(_problems.has(kind), "Tipo de problema desconocido: " + kind)
	return (_problems[kind] as QuizProblem).make(rng)
