## Patrón Strategy: ax + b = c, ¿cuánto vale x? (Sala 2)
class_name SolveProblem
extends QuizProblem

var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var c := RootsTrial.make_case("plus" if rng.randf() < 0.5 else "minus", rng)
	var x: int = c.x
	var choices := [x]
	for wrong in [c.c - c.b, c.c + c.b, x + 1, x - 1, x + 2]:
		if choices.size() < options and not wrong in choices:
			choices.append(wrong)
	choices.shuffle()
	return {
		"title": say("quiz_solve_title"),
		"question": say("quiz_solve_question", {"equation": RootsTrial.equation(c.a, c.b, c.c)}),
		"options": choices.map(func(n): return str(n).replace("-", "−")),
		"answer": choices.find(x),
	}
