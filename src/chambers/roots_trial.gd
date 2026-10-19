## Reglas del Mural de las Raíces (Sala 2, Las Raíces Gemelas), sin nada visible.
## Cada caso es un polinomio x² + bx + c con raíces enteras. El programa del jugador define
## factorizar(b, c), que debe devolver [p, q] tales que (x + p)(x + q) = x² + bx + c
## (es decir, p + q = b y p · q = c). El orden de p y q no importa.
## Cada llamada tiene un límite de pasos: probar todas las parejas es demasiado lento.
class_name RootsTrial
extends RefCounted

enum Verdict { RIGHT, WRONG, BAD_SHAPE, TOO_SLOW, ERROR }

var cases: Array = []     # [{b, c, roots: [p, q]}], el primero es el visible


## kinds: la lista "cases" de chambers.json; cada tipo dice cómo elegir las raíces.
func _init(kinds: Array, rng: RandomNumberGenerator) -> void:
	for kind in kinds:
		cases.append(make_case(String(kind), rng))


static func make_case(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var p := 0
	var q := 0
	match kind:
		"square":            # (x − r)²: el del mural
			p = -rng.randi_range(6, 15)
			q = p
		"mixed":             # una raíz positiva y otra negativa: c negativo
			p = rng.randi_range(20, 60)
			q = -rng.randi_range(20, 60)
		"zero":              # c = 0: una de las raíces es 0
			p = 0
			q = rng.randi_range(5, 40) * (1 if rng.randf() < 0.5 else -1)
		"both_positive":     # (x + p)(x + q) con p y q grandes: b y c positivos
			p = rng.randi_range(25, 55)
			q = rng.randi_range(25, 55)
		"near":              # raíces grandes y casi opuestas: b chico, c grande y negativo
			p = rng.randi_range(40, 55)
			q = -(p - 1) if rng.randf() < 0.5 else -(p + 1)
		_:
			p = rng.randi_range(-9, 9)
			q = rng.randi_range(-9, 9)
	return {"b": p + q, "c": p * q, "roots": [p, q]}


## "x² − 20x + 100" (con los signos bien puestos y sin términos en cero).
static func polynomial(b: int, c: int) -> String:
	var text := "x²"
	if b != 0:
		text += (" − " if b < 0 else " + ") + ("" if absi(b) == 1 else str(absi(b))) + "x"
	if c != 0:
		text += (" − " if c < 0 else " + ") + str(absi(c))
	return text


## "(x − 10)(x − 10)" a partir de [p, q].
static func factors(p: int, q: int) -> String:
	return "(%s)(%s)" % [_term(p), _term(q)]


static func _term(k: int) -> String:
	if k == 0:
		return "x"
	return "x %s %d" % ["−" if k < 0 else "+", absi(k)]


## Revisa lo que devolvió factorizar(b, c). value: lo que devolvió (o null).
static func judge(case: Dictionary, value) -> Verdict:
	if typeof(value) != TYPE_ARRAY or value.size() != 2 or typeof(value[0]) != TYPE_INT or typeof(value[1]) != TYPE_INT:
		return Verdict.BAD_SHAPE
	var p: int = value[0]
	var q: int = value[1]
	return Verdict.RIGHT if p + q == int(case.b) and p * q == int(case.c) else Verdict.WRONG
