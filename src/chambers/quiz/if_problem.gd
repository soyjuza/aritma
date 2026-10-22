## Patrón Strategy: ¿qué imprime este if? Con else = false puede no imprimir nada.
class_name IfProblem
extends QuizProblem

const COMPARE := [">", "<", "=="]

var with_else := 1
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var name: String = VariableProblem.NAMES[rng.randi() % VariableProblem.NAMES.size()]
	var n := rng.randi_range(1, 12)
	var op: String = COMPARE[rng.randi() % COMPARE.size()]
	var k := n if op == "==" and rng.randf() < 0.5 else rng.randi_range(2, 10)
	var yes := _test(n, op, k)
	var a := rng.randi_range(2, 5)
	var b := rng.randi_range(6, 9)
	var code := ["%s = %d" % [name, n], "if %s %s %d:" % [name, op, k], "    print(%s + %d)" % [name, a]]
	var right := str(n + a)
	var choices := [str(n + a), str(n), str(n + b), str(n + a + 1)]
	if with_else > 0:
		code.append_array(["else:", "    print(%s - %d)" % [name, a]])
		choices = [str(n + a), str(n - a), str(n), str(n + a + 1)]
		if not yes:
			right = str(n - a)
	elif not yes:
		right = say("quiz_if_nothing")
		choices = [str(n + a), say("quiz_if_nothing"), str(n), str(n - a)]
	var unique: Array = []
	for c in choices:
		if not c in unique:
			unique.append(c)
	var extra := 2
	while unique.size() < options:
		if not str(n + a + extra) in unique:
			unique.append(str(n + a + extra))
		extra += 1
	unique = unique.slice(0, options)
	if not right in unique:
		unique[unique.size() - 1] = right
	unique.shuffle()
	return {
		"title": say("quiz_if_title"),
		"question": say("quiz_if_question"),
		"code": code,
		"options": unique.map(func(o): return String(o).replace("-", "−")),
		"answer": unique.find(right),
	}


static func _test(n: int, op: String, k: int) -> bool:
	match op:
		">":
			return n > k
		"<":
			return n < k
	return n == k
