## Reglas del Mural (Sala 2): despejar(a, b, c) devuelve x.
## La forma cambia con la variante: ax + b = c, x/a + b = c o a(x + b) = c.
class_name RootsTrial
extends RefCounted

enum Verdict { RIGHT, WRONG, BAD_SHAPE, TOO_SLOW, ERROR }

var cases: Array = []
var form := "lineal"


func _init(kinds: Array, rng: RandomNumberGenerator, p_form := "lineal") -> void:
	form = p_form
	for kind in kinds:
		cases.append(make_case(String(kind), rng, form))


static func make_case(kind: String, rng: RandomNumberGenerator, p_form := "lineal") -> Dictionary:
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
	match p_form:
		"fraccion":
			# x es múltiplo de a para que x / a dé entero
			x *= a
			return {"a": a, "b": b, "c": x / a + b, "x": x}
		"parentesis":
			return {"a": a, "b": b, "c": a * (x + b), "x": x}
	return {"a": a, "b": b, "c": a * x + b, "x": x}


static func equation(a: int, b: int, c: int, p_form := "lineal") -> String:
	var sign := ""
	if b != 0:
		sign = (" − " if b < 0 else " + ") + str(absi(b))
	var right := " = " + str(c).replace("-", "−")
	match p_form:
		"fraccion":
			return "x/%d%s%s" % [a, sign, right]
		"parentesis":
			return "%d(x%s)%s" % [a, sign, right]
	return "%dx%s%s" % [a, sign, right]


static func answer(value) -> String:
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, round(value)):
		value = int(round(value))
	return "x = " + str(value).replace("-", "−")


## Revisa lo que devolvió despejar.
static func judge(case: Dictionary, value) -> Verdict:
	if not typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return Verdict.BAD_SHAPE
	return Verdict.RIGHT if is_equal_approx(float(value), float(case.x)) else Verdict.WRONG
