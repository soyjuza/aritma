## Reglas del Mural (Sala 2): despejar(a, b, c) devuelve x.
class_name RootsTrial
extends RefCounted

enum Verdict { RIGHT, WRONG, BAD_SHAPE, TOO_SLOW, ERROR }

var cases: Array = []


func _init(kinds: Array, rng: RandomNumberGenerator) -> void:
	for kind in kinds:
		cases.append(make_case(String(kind), rng))


static func make_case(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var x := rng.randi_range(2, 12)
	var b := rng.randi_range(1, 15)
	match kind:
		"plus":
			pass
		"minus":
			b = -b
		"negative":
			x = -rng.randi_range(1, 9)
			b = b * (1 if rng.randf() < 0.5 else -1)
	return {"a": a, "b": b, "c": a * x + b, "x": x}


static func equation(a: int, b: int, c: int) -> String:
	var text := "%dx" % a
	if b != 0:
		text += (" − " if b < 0 else " + ") + str(absi(b))
	return text + " = " + str(c).replace("-", "−")


static func answer(value) -> String:
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, round(value)):
		value = int(round(value))
	return "x = " + str(value).replace("-", "−")


## Revisa lo que devolvió despejar.
static func judge(case: Dictionary, value) -> Verdict:
	if not typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return Verdict.BAD_SHAPE
	return Verdict.RIGHT if is_equal_approx(float(value), float(case.x)) else Verdict.WRONG
