## Patrón Strategy: ¿par o impar? Con code_lines > 0 primero hay que calcular la variable.
class_name ParityProblem
extends QuizProblem

var min_number := 11
var max_number := 99
var code_lines := 0


func make(rng: RandomNumberGenerator) -> Dictionary:
	var quiz := {"title": say("quiz_parity_title"), "options": [say("quiz_parity_even"), say("quiz_parity_odd")]}
	var n := rng.randi_range(min_number, max_number)
	if code_lines > 0:
		var p := VariableProblem.program(rng, code_lines, 9)
		n = p.value
		quiz.code = p.code
		quiz.question = say("quiz_parity_code_question", {"name": p.name})
	else:
		quiz.question = say("quiz_parity_question", {"n": n})
	quiz.answer = 0 if n % 2 == 0 else 1
	return quiz
