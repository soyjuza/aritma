## Patrón Strategy: ¿en qué orden van las líneas? (sin bucles)
class_name OrderProblem
extends QuizProblem

const LETTERS := ["A", "B", "C", "D"]

var programs: Array = []    # cada uno en el orden correcto (chambers.json)
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var program: Array = programs[rng.randi() % programs.size()]
	var shown := program.duplicate()
	while shown == program:
		_shuffle(shown, rng)
	var code: Array = []
	for i in shown.size():
		code.append("%s   %s" % [LETTERS[i], shown[i]])
	var good := ", ".join(program.map(func(line): return LETTERS[shown.find(line)]))
	var choices := [good]
	var letters := LETTERS.slice(0, program.size())
	var tries := 0
	while choices.size() < options and tries < 50:
		tries += 1
		_shuffle(letters, rng)
		var wrong := ", ".join(letters)
		if not wrong in choices:
			choices.append(wrong)
	_shuffle(choices, rng)
	return {
		"title": say("quiz_order_title"),
		"question": say("quiz_order_question"),
		"code": code,
		"options": choices,
		"answer": choices.find(good),
	}


func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp
