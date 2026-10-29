## Problemas del jefe y de las misiones. Elige la estrategia (QuizProblem) según el nombre.
class_name BossQuiz
extends RefCounted

var _problems: Dictionary = {}


## settings: chambers.json, quiz.problems (o quests.json, settings).
func _init(text: Callable = Callable(), settings: Dictionary = {}) -> void:
	_problems = {
		"palabra": KeywordProblem.new(text, _with({}, settings.get("palabra", {}))),
		"columnas": SelectProblem.new(text, _with({}, settings.get("columnas", {}))),
		"cuantas_columnas": SelectProblem.new(text, _with({"count": 1}, settings.get("cuantas_columnas", {}))),
		"orden": OrderProblem.new(text, _with({}, settings.get("orden", {}))),
		"donde": WhereProblem.new(text, _with({}, settings.get("donde", {}))),
		"donde_cuantas": WhereProblem.new(text, _with({"count": 1}, settings.get("donde_cuantas", {}))),
		"y_o": WhereProblem.new(text, _with({"logic": 1}, settings.get("y_o", {}))),
		"y_o_cuantas": WhereProblem.new(text, _with({"logic": 1, "count": 1}, settings.get("y_o_cuantas", {}))),
		"ordenar": SortProblem.new(text, _with({}, settings.get("ordenar", {}))),
		"limite": SortProblem.new(text, _with({"limit": 1}, settings.get("limite", {}))),
		"unir": JoinProblem.new(text, _with({}, settings.get("unir", {}))),
		"unir_cuantas": JoinProblem.new(text, _with({"count": 1}, settings.get("unir_cuantas", {}))),
	}


## Lo que trae settings, sobre lo que el tipo pide siempre (count, logic...).
static func _with(base: Dictionary, settings: Dictionary) -> Dictionary:
	var out := base.duplicate()
	out.merge(settings, true)
	return out


func kinds() -> Array:
	return _problems.keys()


## Un problema nuevo del tipo kind.
func make(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	assert(_problems.has(kind), "Tipo de problema desconocido: " + kind)
	return (_problems[kind] as QuizProblem).make(rng)
