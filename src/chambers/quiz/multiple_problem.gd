## Patrón Strategy: ¿cuál es múltiplo de m? (Sala 5)
class_name MultipleProblem
extends QuizProblem

var min_divisor := 3
var max_divisor := 6
var min_factor := 3
var max_factor := 12
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var m := rng.randi_range(min_divisor, max_divisor)
	var good := m * rng.randi_range(min_factor, max_factor)
	var numbers := [good]
	while numbers.size() < options:
		var n := rng.randi_range(10, m * max_factor)
		if n % m != 0 and not n in numbers:
			numbers.append(n)
	numbers.shuffle()
	return {
		"title": say("quiz_multiple_title"),
		"question": say("quiz_multiple_question", {"m": m}),
		"options": numbers.map(func(n): return str(n)),
		"answer": numbers.find(good),
	}
