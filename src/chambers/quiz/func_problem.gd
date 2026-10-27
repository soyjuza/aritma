## Patrón Strategy: ¿qué imprime esta función con return?
class_name FuncProblem
extends QuizProblem

const NAMES := ["doble", "calcular", "magia", "subir"]

var nested := 0    # 1 = f(f(x))
var options := 4


func make(rng: RandomNumberGenerator) -> Dictionary:
	var name: String = NAMES[rng.randi() % NAMES.size()]
	var a := rng.randi_range(2, 3)
	var b := rng.randi_range(1, 5)
	var x := rng.randi_range(2, 6)
	var kind := rng.randi() % 3
	var body: String = ["n * %d" % a, "n + %d" % b, "n * %d + %d" % [a, b]][kind]
	var f := func(n: int) -> int: return [n * a, n + b, n * a + b][kind]
	var right: int = f.call(f.call(x)) if nested > 0 else f.call(x)
	var call := "%s(%s(%d))" % [name, name, x] if nested > 0 else "%s(%d)" % [name, x]
	var out := pick(right, [f.call(x), x, x * a, x + a + b], options)
	out.title = say("quiz_func_title")
	out.question = say("quiz_func_question")
	out.code = ["def %s(n):" % name, "    return " + body, "", "print(%s)" % call]
	return out
