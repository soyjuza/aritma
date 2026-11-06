## Reglas del Mural (Sala 2): despejar(...) devuelve x.
## La forma cambia con la variante: ax + b = c, x/a + b = c, a(x + b) = c,
## ax + b = cx + d (cuatro números) o sin_solucion (si a = 0 se devuelve None).
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
		"zero":
			# 0x + b = c con c distinto de b: ninguna x sirve
			var c0 := b + rng.randi_range(1, 12) * (1 if rng.randf() < 0.5 else -1)
			return {"a": 0, "b": b, "c": c0, "x": null}
	match p_form:
		"dos_lados":
			# ax + b = cx + d, con c distinto de a para que haya una sola x
			var cx := rng.randi_range(1, 8)
			if cx >= a:
				cx += 1
			return {"a": a, "b": b, "c": cx, "d": a * x + b - cx * x, "x": x}
		"fraccion":
			# x es múltiplo de a para que x / a dé entero
			x *= a
			return {"a": a, "b": b, "c": x / a + b, "x": x}
		"parentesis":
			return {"a": a, "b": b, "c": a * (x + b), "x": x}
	return {"a": a, "b": b, "c": a * x + b, "x": x}


## Los números con los que el Mural llama a despejar.
static func args(case: Dictionary, p_form := "lineal") -> Array:
	if p_form == "dos_lados":
		return [case.a, case.b, case.c, case.d]
	return [case.a, case.b, case.c]


## "despejar(3, 5, 20)", para los mensajes.
static func call_text(case: Dictionary, p_form := "lineal") -> String:
	return "despejar(%s)" % ", ".join(args(case, p_form).map(func(n): return str(n)))


## La ecuación de un caso, como se ve en el Mural.
static func case_equation(case: Dictionary, p_form := "lineal") -> String:
	if p_form == "dos_lados":
		return "%s%s = %s%s" % [_x_term(case.a), _plus(case.b), _x_term(case.c), _plus(case.d)]
	return equation(case.a, case.b, case.c, p_form)


static func _x_term(k: int) -> String:
	return "x" if k == 1 else str(k) + "x"


static func _plus(n: int) -> String:
	if n == 0:
		return ""
	return (" − " if n < 0 else " + ") + str(absi(n))


static func equation(a: int, b: int, c: int, p_form := "lineal") -> String:
	var sign := _plus(b)
	var right := " = " + str(c).replace("-", "−")
	match p_form:
		"fraccion":
			return "x/%d%s%s" % [a, sign, right]
		"parentesis":
			return "%d(x%s)%s" % [a, sign, right]
	return "%dx%s%s" % [a, sign, right]


static func answer(value) -> String:
	if typeof(value) == TYPE_NIL:
		return "sin x"
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, round(value)):
		value = int(round(value))
	return "x = " + str(value).replace("-", "−")


## Revisa lo que devolvió despejar.
static func judge(case: Dictionary, value) -> Verdict:
	if typeof(case.x) == TYPE_NIL:
		return Verdict.RIGHT if typeof(value) == TYPE_NIL else Verdict.WRONG
	if not typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return Verdict.BAD_SHAPE
	return Verdict.RIGHT if is_equal_approx(float(value), float(case.x)) else Verdict.WRONG
