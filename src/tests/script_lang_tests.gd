## Pruebas del lenguaje del Códice: cada caso es un programa y lo que debe imprimir
## (o el error que debe dar). Las usa SelfTest y también script_lang_runner.gd:
##   Godot --headless --path . -s res://src/tests/script_lang_runner.gd
class_name ScriptLangTests
extends RefCounted

const CASES := [
	["aritmética", "print(7 + 3 * 2, 2 ** 10, 7 // 2, -7 // 2, 7 % 3, -7 % 3, 7 / 2)", "13 1024 3 -4 1 2 3.5"],
	["texto", "a = 'hola'\nb = \"mundo\"\nprint(a + ' ' + b, len(a))", "hola mundo 4"],
	["listas", "l = [3, 1, 2]\nl.append(9)\nl[0] = 5\nprint(l, len(l), l[-1], sorted(l))", "[5, 1, 2, 9] 4 9 [1, 2, 5, 9]"],
	["if/elif/else", "x = 15\nif x % 3 == 0 and x % 5 == 0:\n    print('ambos')\nelif x % 3 == 0:\n    print('tres')\nelse:\n    print('nada')", "ambos"],
	["for range", "t = 0\nfor i in range(1, 11):\n    t += i\nprint(t)", "55"],
	["while break continue", "i = 0\nwhile True:\n    i += 1\n    if i % 2 == 0:\n        continue\n    if i > 7:\n        break\n    print(i)", "1\n3\n5\n7"],
	["def y return", "def cuadrado(n):\n    return n * n\nprint(cuadrado(12))", "144"],
	["recursión", "def fact(n):\n    if n <= 1:\n        return 1\n    return n * fact(n - 1)\nprint(fact(10))", "3628800"],
	["factores primos", "def factores(n):\n    f = []\n    d = 2\n    while n > 1:\n        while n % d == 0:\n            f.append(d)\n            n //= d\n        d += 1\n    return f\nprint(factores(2310), factores(360))", "[2, 3, 5, 7, 11] [2, 2, 2, 3, 3, 5]"],
	["binario y XOR", "print(bin(182), 182 ^ 255, 5 & 3, 5 | 3, 1 << 7)", "0b10110110 73 1 7 128"],
	["comparación encadenada", "print(1 < 2 < 3, 3 < 2 < 4, 2 in [1, 2], 5 not in [1, 2])", "True False True True"],
	["min max sum", "print(min(4, 2, 8), max([4, 2, 8]), sum([1, 2, 3]), abs(-5))", "2 8 6 5"],
	["comentarios", "# un comentario\nx = 3  # otro\nprint(x)", "3"],
]

const ERRORS := [
	["nombre desconocido", "avanzr()", "No conozco «avanzr»"],
	["sugerencia", "contador = 1\nprint(contadr)", "¿Quisiste decir «contador»?"],
	["falta los dos puntos", "for i in range(3)\n    print(i)", "Falta «:»"],
	["sin sangría", "if True:\nprint(1)", "con sangría"],
	["bucle infinito", "while True:\n    pass", "tardó demasiado"],
	["división entre cero", "print(1 / 0)", "División entre cero"],
	["tipos", "print('a' + 1)", "No se puede usar «+» entre str e int"],
	["índice", "l = [1]\nprint(l[3])", "fuera de rango"],
	["argumentos", "def f(a):\n    return a\nf(1, 2)", "recibe 1 argumento"],
]

var failures := 0


## report(ok: bool, etiqueta: String) se llama por cada caso.
func run_all(report: Callable) -> int:
	failures = 0
	var sandbox := ScriptSandbox.new()
	for case in CASES:
		var result := sandbox.run(case[1])
		var got := "\n".join(result.output) if result.ok else "ERROR " + result.error_text()
		var ok: bool = got == case[2]
		if not ok:
			failures += 1
		report.call(ok, "Códice: %s%s" % [case[0], "" if ok else " → obtuve «%s»" % got])
	for case in ERRORS:
		var result := sandbox.run(case[1], {}, 5000)
		var ok: bool = not result.ok and case[2] in result.error
		if not ok:
			failures += 1
		report.call(ok, "Códice (error): %s%s" % [case[0], "" if ok else " → obtuve «%s»" % result.error_text()])
	var archive := sandbox.run("def clave(n):\n    c = 0\n    d = 2\n    while n > 1:\n        while n % d == 0:\n            c += 1\n            n //= d\n        d += 1\n    return c")
	var answers := [sandbox.call_function(archive, "clave", [12]), sandbox.call_function(archive, "clave", [360]), sandbox.call_function(archive, "clave", [1])]
	var ok_call: bool = answers[0][1] == 3 and answers[1][1] == 6 and answers[2][1] == 0
	if not ok_call:
		failures += 1
	report.call(ok_call, "Códice: el Archivo puede llamar la función clave(n) del jugador")
	return failures
