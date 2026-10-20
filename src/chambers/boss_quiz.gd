## Los problemas del Guardián del Cero (Sala 6), sin nada visible. Cada vez que el jefe pierde
## una parte de su vida pone a prueba a Tala con un repaso de una sala ya superada:
##   "paridad"  — Sala 1: ¿el número es PAR o IMPAR?
##   "multiplo" — Sala 5: ¿cuál de estas losas es múltiplo de n?
##   "despejar" — Sala 2: ax + b = c, ¿cuánto vale x?
## Cada problema trae su enunciado, las opciones (texto) y cuál es la buena.
class_name BossQuiz
extends RefCounted


## {"title": "...", "question": "...", "options": ["...", ...], "answer": índice}
static func make(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	match kind:
		"paridad":
			return _parity(rng)
		"multiplo":
			return _multiple(rng)
		_:
			return _solve(rng)


static func _parity(rng: RandomNumberGenerator) -> Dictionary:
	var n := rng.randi_range(11, 99)
	return {
		"title": "La Criba",
		"question": "¿El número %d es PAR o IMPAR?" % n,
		"options": ["PAR", "IMPAR"],
		"answer": 0 if n % 2 == 0 else 1,
	}


static func _multiple(rng: RandomNumberGenerator) -> Dictionary:
	var m := rng.randi_range(3, 6)
	var good := m * rng.randi_range(3, 12)
	var numbers := [good]
	while numbers.size() < 4:
		var n := rng.randi_range(10, m * 12)
		if n % m != 0 and not n in numbers:
			numbers.append(n)
	numbers.shuffle()
	return {
		"title": "El Sendero",
		"question": "¿Qué losa te sostiene? Solo los múltiplos de %d." % m,
		"options": numbers.map(func(n): return str(n)),
		"answer": numbers.find(good),
	}


static func _solve(rng: RandomNumberGenerator) -> Dictionary:
	var c := RootsTrial.make_case("plus" if rng.randf() < 0.5 else "minus", rng)
	var x: int = c.x
	# Respuestas equivocadas típicas: olvidar dividir, sumar b en vez de restarlo, x ± 1
	var options := [x]
	for wrong in [c.c - c.b, c.c + c.b, x + 1, x - 1, x + 2]:
		if options.size() < 4 and not wrong in options:
			options.append(wrong)
	options.shuffle()
	return {
		"title": "El Mural",
		"question": "%s      x = ?" % RootsTrial.equation(c.a, c.b, c.c),
		"options": options.map(func(n): return str(n).replace("-", "−")),
		"answer": options.find(x),
	}
