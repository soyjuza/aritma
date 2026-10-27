## Patrón Strategy: ¿qué imprime este while? o ¿cuántas veces se repite?
class_name WhileProblem
extends QuizProblem

var times := 0     # 1 = pregunta cuántas veces se repite
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var name: String = VariableProblem.NAMES[rng.randi() % VariableProblem.NAMES.size()]
	var start := rng.randi_range(0, 5)
	var step := rng.randi_range(2, 4)
	var limit := start + step * rng.randi_range(2, 4) - rng.randi_range(0, step - 1)
	var value := start
	var count := 0
	while value < limit:
		value += step
		count += 1
	var code := ["%s = %d" % [name, start], "while %s < %d:" % [name, limit], "    %s = %s + %d" % [name, name, step], "print(%s)" % name]
	var out := pick(count, [count + 1, count - 1, limit - start], options) if times > 0 else pick(value, [value - step, value + step, limit], options)
	out.title = say("quiz_while_title")
	out.question = say("quiz_while_times" if times > 0 else "quiz_while_value", {"name": name})
	out.code = code
	return out
