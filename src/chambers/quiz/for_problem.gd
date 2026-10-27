## Patrón Strategy: ¿qué imprime este for? (con range o recorriendo una lista)
class_name ForProblem
extends QuizProblem

var over_list := 0    # 1 = for n in [..]
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary
	var head: String
	var add: String
	if over_list > 0:
		var items: Array = []
		for i in rng.randi_range(3, 4):
			items.append(rng.randi_range(1, 9))
		var total := 0
		for v in items:
			total += v
		head = "for n in %s:" % ScriptContext.to_text(items)
		add = "    total = total + n"
		out = pick(total, [items[-1], total - items[0], items.size()], options)
	else:
		var k := rng.randi_range(2, 5)
		var m := rng.randi_range(2, 5)
		head = "for i in range(%d):" % k
		add = "    total = total + %d" % m
		out = pick(k * m, [k + m, k * m - m, k * m + m, m], options)
	out.title = say("quiz_for_title")
	out.question = say("quiz_for_question")
	out.code = ["total = 0", head, add, "print(total)"]
	return out
