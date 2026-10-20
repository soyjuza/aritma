## Patrón Strategy: ¿par o impar? (Sala 1)
class_name ParityProblem
extends QuizProblem

var min_number := 11
var max_number := 99


func make(rng: RandomNumberGenerator) -> Dictionary:
	var n := rng.randi_range(min_number, max_number)
	return {
		"title": say("quiz_parity_title"),
		"question": say("quiz_parity_question", {"n": n}),
		"options": [say("quiz_parity_even"), say("quiz_parity_odd")],
		"answer": 0 if n % 2 == 0 else 1,
	}
