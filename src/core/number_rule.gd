## Reglas de números que usan la Criba (Sala 1) y el Sendero (Sala 5).
## Cada regla es un diccionario de chambers.json, por ejemplo {"kind": "between", "lo": 10, "hi": 30}.
## Así una sala puede pedir cosas distintas: un if simple, uno con and, uno con or, etc.
class_name NumberRule
extends RefCounted


## ¿El número n cumple la regla?
static func accepts(rule: Dictionary, n: int) -> bool:
	match String(rule.get("kind", "multiple")):
		"greater":
			return n > _num(rule, "t")
		"between":
			return n >= _num(rule, "lo") and n <= _num(rule, "hi")
		"multiple_or_greater":
			return _multiple(n, _num(rule, "k", 2)) or n > _num(rule, "t")
		"multiple_and_greater":
			return _multiple(n, _num(rule, "k", 2)) and n > _num(rule, "t")
		"last_digit":
			return posmod(n, 10) == _num(rule, "d")
		"divisor":
			return n > 0 and _num(rule, "of", 60) % n == 0
		"prime":
			return is_prime(n)
	return _multiple(n, _num(rule, "k", _num(rule, "multiple", 2)))


## Números en el borde de la regla (sirven para ver si se usó < o <=).
static func edges(rule: Dictionary) -> Array:
	match String(rule.get("kind", "multiple")):
		"greater":
			return [_num(rule, "t"), _num(rule, "t") + 1]
		"multiple_or_greater":
			# Los impares de cada lado de t: ahí es donde importa el "or"
			return [_near(rule, _num(rule, "t"), -1, false), _near(rule, _num(rule, "t") + 1, 1, false)]
		"multiple_and_greater":
			# Los pares de cada lado de t: ahí es donde importa el "and"
			return [_near(rule, _num(rule, "t"), -1, true), _near(rule, _num(rule, "t") + 1, 1, true)]
		"between":
			return [_num(rule, "lo") - 1, _num(rule, "lo"), _num(rule, "hi"), _num(rule, "hi") + 1]
	return []


## El cero no puede salir con "divisor": 60 % 0 sería dividir entre cero.
static func allows_zero(rule: Dictionary) -> bool:
	return String(rule.get("kind", "")) != "divisor"


## Un número entre low y high que cumple (want = true) o no cumple la regla.
## Si en ese rango no hay ninguno, busca en uno más grande.
static func pick(rule: Dictionary, rng: RandomNumberGenerator, low: int, high: int, want: bool) -> int:
	for span in [[low, high], [mini(low, 1), maxi(high, 120)]]:
		var options: Array = []
		for n in range(span[0], span[1] + 1):
			if (n != 0 or allows_zero(rule)) and accepts(rule, n) == want:
				options.append(n)
		if not options.is_empty():
			return options[rng.randi_range(0, options.size() - 1)]
	return low


static func is_prime(n: int) -> bool:
	if n < 2:
		return false
	var d := 2
	while d * d <= n:
		if n % d == 0:
			return false
		d += 1
	return true


## Desde n, el primer número (hacia step) que es o no es múltiplo de k.
static func _near(rule: Dictionary, n: int, step: int, multiple: bool) -> int:
	if _num(rule, "k", 2) <= 1:
		return n
	while _multiple(n, _num(rule, "k", 2)) != multiple:
		n += step
	return n


static func _multiple(n: int, k: int) -> bool:
	return posmod(n, maxi(1, k)) == 0


## Los parámetros pueden venir como texto ("3") porque ChallengeDeck los rellena con format().
static func _num(rule: Dictionary, key: String, default := 0) -> int:
	return int(rule.get(key, default))
