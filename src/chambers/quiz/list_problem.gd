## Patrón Strategy: ¿qué imprime esta lista? (índice desde 0 o len)
class_name ListProblem
extends QuizProblem

var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var items: Array = []
	for i in rng.randi_range(3, 5):
		var v := rng.randi_range(1, 20)
		while v in items:
			v = rng.randi_range(1, 20)
		items.append(v)
	var name: String = ["notas", "pesos", "llaves", "lista"][rng.randi() % 4]
	var out: Dictionary
	var line: String
	if rng.randf() < 0.3:
		line = "print(len(%s))" % name
		out = pick(items.size(), [items.size() - 1, items.size() + 1, items[-1]], options)
	else:
		var i := rng.randi_range(0, items.size() - 1)
		line = "print(%s[%d])" % [name, i]
		var wrong: Array = [i]
		if i + 1 < items.size():
			wrong.push_front(items[i + 1])
		if i > 0:
			wrong.push_front(items[i - 1])
		out = pick(items[i], wrong, options)
	out.title = say("quiz_list_title")
	out.question = say("quiz_list_question")
	out.code = ["%s = %s" % [name, ScriptContext.to_text(items)], line]
	return out
