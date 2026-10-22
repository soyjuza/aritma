## Patrón Strategy: ¿cuánto vale la variable al final? (sin bucles)
class_name VariableProblem
extends QuizProblem

const NAMES := ["n", "x", "a", "total"]

var min_lines := 2
var max_lines := 3
var max_start := 9
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var p := program(rng, rng.randi_range(min_lines, max_lines), max_start)
	var value: int = p.value
	var choices := [value]
	for wrong in [p.before, p.first, value + 1, value - 1, value + 2]:
		if choices.size() < options and not wrong in choices:
			choices.append(wrong)
	choices.shuffle()
	return {
		"title": say("quiz_variable_title"),
		"question": say("quiz_variable_question", {"name": p.name}),
		"code": p.code,
		"options": choices.map(func(n): return str(n)),
		"answer": choices.find(value),
	}


## Unas líneas que cambian una variable. También lo usa ParityProblem.
static func program(rng: RandomNumberGenerator, lines: int, start_max: int) -> Dictionary:
	var name: String = NAMES[rng.randi() % NAMES.size()]
	var value := rng.randi_range(2, start_max)
	var first := value
	var before := value
	var code := ["%s = %d" % [name, value]]
	for i in lines - 1:
		before = value
		var op := rng.randi() % 3
		var k := rng.randi_range(2, 3) if op == 2 else rng.randi_range(2, 6)
		if op == 1 and value - k < 0:
			op = 0
		match op:
			0:
				value += k
				code.append("%s = %s + %d" % [name, name, k])
			1:
				value -= k
				code.append("%s = %s - %d" % [name, name, k])
			2:
				value *= k
				code.append("%s = %s * %d" % [name, name, k])
	return {"name": name, "code": code, "value": value, "before": before, "first": first}
