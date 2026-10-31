## Reglas de la Criba (Sala 1). Cada paso queda como un FilterCommand.
## La regla cambia con la variante: múltiplos de k (k = 2: pares) o mayores que t.
class_name ParityFilter
extends RefCounted

enum Fault { NONE, WRONG_SIDE, LEFT_OVER }

var rule: Dictionary = {"kind": "multiple", "k": 2}
var rounds: Array = []
var round_index := 0
var commands: Array = []
var fault := Fault.NONE
var fault_value := 0

var _queue: Array = []
var _held: Variant = null


## rules: "rounds" de chambers.json. p_rule: "rule" de la variante.
func _init(rules: Array, rng: RandomNumberGenerator, p_rule: Dictionary = {}) -> void:
	if not p_rule.is_empty():
		rule = p_rule
	for r: Dictionary in rules:
		rounds.append(make_round(r, rng))


func make_round(spec: Dictionary, rng: RandomNumberGenerator) -> Array:
	var counts: Array = spec.get("count", [8, 8])
	var count := rng.randi_range(int(counts[0]), int(counts[-1]))
	var low := int(spec.get("min", 1))
	var high := int(spec.get("max", 20))
	var values: Array = []
	for i in count:
		values.append(rng.randi_range(low, high))
	if bool(spec.get("zero", false)) and not 0 in values:
		values[rng.randi_range(0, count - 1)] = 0
	# Siempre hay al menos una que entra y una que no
	if not values.any(accepts):
		values[0] = _accepted_number(rng, low, high)
	if values.all(accepts):
		values[-1] = _rejected_number(rng, low, high)
	return values


## ¿La esfera va al cáliz?
func accepts(value: int) -> bool:
	match String(rule.get("kind", "multiple")):
		"greater":
			return value > int(rule.get("t", 0))
	return posmod(value, maxi(1, int(rule.get("k", 2)))) == 0


func _accepted_number(rng: RandomNumberGenerator, low: int, high: int) -> int:
	if String(rule.get("kind", "")) == "greater":
		var t := int(rule.get("t", 0))
		return rng.randi_range(t + 1, maxi(high, t + 10))
	var k := maxi(1, int(rule.get("k", 2)))
	return k * rng.randi_range(maxi(1, ceili(low / float(k))), maxi(1, high / k))


func _rejected_number(rng: RandomNumberGenerator, low: int, high: int) -> int:
	if String(rule.get("kind", "")) == "greater":
		return rng.randi_range(mini(low, int(rule.get("t", 0))), int(rule.get("t", 0)))
	return _accepted_number(rng, low, high) + 1



## Empieza la ronda index.
func start_round(index: int) -> void:
	round_index = index
	_queue = rounds[index].duplicate()
	_held = null
	commands.append(FilterCommand.RoundStart.new(index, _queue.duplicate()))


func failed() -> bool:
	return fault != Fault.NONE


func remaining() -> int:
	return 0 if failed() else _queue.size()


func held() -> Variant:
	return _held


## Suelta la siguiente esfera. Devuelve el error o "".
func release() -> String:
	if failed():
		return ""
	if _held != null:
		return "release_busy"
	if _queue.is_empty():
		return "release_empty"
	_held = _queue.pop_front()
	commands.append(FilterCommand.Release.new(_held))
	return ""


## Manda la esfera al cáliz o al crisol.
func send(to_chalice: bool) -> String:
	if failed():
		return ""
	if _held == null:
		return "send_empty"
	var value: int = _held
	_held = null
	var right := accepts(value) == to_chalice
	commands.append(FilterCommand.Send.new(value, to_chalice, right))
	if not right:
		fault = Fault.WRONG_SIDE
		fault_value = value
	return ""


## No pueden quedar esferas sin clasificar.
func end_round() -> void:
	if failed():
		return
	var left := _queue.size() + (1 if _held != null else 0)
	if left > 0:
		fault = Fault.LEFT_OVER
		fault_value = left
		commands.append(FilterCommand.Jam.new())
	else:
		commands.append(FilterCommand.RoundDone.new(round_index))
