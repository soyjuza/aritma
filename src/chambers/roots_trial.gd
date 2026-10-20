## Reglas del Mural de la Incógnita (Sala 2), sin nada visible.
## Cada caso es una ecuación ax + b = c con una solución entera. El programa del jugador define
## despejar(a, b, c), que debe devolver x = (c − b) / a. Se acepta un entero o un decimal
## (15 / 3 da 5.0 y también vale).
class_name RootsTrial
extends RefCounted

enum Verdict { RIGHT, WRONG, BAD_SHAPE, TOO_SLOW, ERROR }

var cases: Array = []     # [{a, b, c, x}], el primero es el visible


## kinds: la lista "cases" de chambers.json; cada tipo dice cómo elegir los números.
func _init(kinds: Array, rng: RandomNumberGenerator) -> void:
	for kind in kinds:
		cases.append(make_case(String(kind), rng))


static func make_case(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var x := rng.randi_range(2, 12)
	var b := rng.randi_range(1, 15)
	match kind:
		"plus":              # 3x + 5 = 20: el del mural
			pass
		"minus":             # 2x − 4 = 10: b negativo
			b = -b
		"negative":          # la x da negativa: 4x + 9 = −7
			x = -rng.randi_range(1, 9)
			b = b * (1 if rng.randf() < 0.5 else -1)
	return {"a": a, "b": b, "c": a * x + b, "x": x}


## "3x + 5 = 20" (con los signos bien puestos).
static func equation(a: int, b: int, c: int) -> String:
	var text := "%dx" % a
	if b != 0:
		text += (" − " if b < 0 else " + ") + str(absi(b))
	return text + " = " + str(c).replace("-", "−")


## "x = 5" (o "x = 2.5" si el programa devolvió un decimal que no es entero).
static func answer(value) -> String:
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, round(value)):
		value = int(round(value))
	return "x = " + str(value).replace("-", "−")


## Revisa lo que devolvió despejar(a, b, c). value: lo que devolvió (o null).
static func judge(case: Dictionary, value) -> Verdict:
	if not typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return Verdict.BAD_SHAPE
	return Verdict.RIGHT if is_equal_approx(float(value), float(case.x)) else Verdict.WRONG
