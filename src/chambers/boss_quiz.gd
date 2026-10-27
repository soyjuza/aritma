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
		"variable": VariableProblem.new(text, settings.get("variable", {})),
		"orden": OrderProblem.new(text, settings.get("orden", {})),
		"si": IfProblem.new(text, settings.get("si", {"with_else": 0})),
		"si_sino": IfProblem.new(text, settings.get("si_sino", {"with_else": 1})),
		"mientras": WhileProblem.new(text, settings.get("mientras", {})),
		"mientras_veces": WhileProblem.new(text, settings.get("mientras_veces", {"times": 1})),
		"funcion": FuncProblem.new(text, settings.get("funcion", {})),
		"funcion_doble": FuncProblem.new(text, settings.get("funcion_doble", {"nested": 1})),
		"lista": ListProblem.new(text, settings.get("lista", {})),
		"para": ForProblem.new(text, settings.get("para", {})),
		"para_lista": ForProblem.new(text, settings.get("para_lista", {"over_list": 1})),
	}


func kinds() -> Array:
	return _problems.keys()


## Un problema nuevo del tipo kind.
func make(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	assert(_problems.has(kind), "Tipo de problema desconocido: " + kind)
	return (_problems[kind] as QuizProblem).make(rng)
