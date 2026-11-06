## Reglas de la Criba (Sala 1). Cada paso queda como un FilterCommand.
## La regla cambia con la variante (ver NumberRule): múltiplos, mayores que, entre dos
## números (and), par o mayor (or), última cifra o divisores.
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
	for i in rules.size():
		rounds.append(make_round(rules[i], rng, i > 0))


## with_edge: en las rondas ocultas salen los números del borde (t, lo, hi...),
## así se nota si el programa usa < cuando debía usar <=.
func make_round(spec: Dictionary, rng: RandomNumberGenerator, with_edge := false) -> Array:
	var counts: Array = spec.get("count", [8, 8])
	var count := rng.randi_range(int(counts[0]), int(counts[-1]))
	var low := int(spec.get("min", 1))
	var high := int(spec.get("max", 20))
	if not NumberRule.allows_zero(rule):
		low = maxi(low, 1)
	var values: Array = []
	for i in count:
		# Mitad y mitad más o menos, aunque la regla sea rara (divisores, entre...)
		values.append(NumberRule.pick(rule, rng, low, high, rng.randf() < 0.5))
	# Lugares libres: el cero y los bordes no se pisan entre ellos
	var spots := range(count)
	var must: Array = []
	if bool(spec.get("zero", false)) and NumberRule.allows_zero(rule):
		must.append(0)
	if with_edge:
		must.append_array(NumberRule.edges(rule).filter(func(n): return n >= low and n <= high))
	for n in must:
		if n in values:
			spots.erase(values.find(n))    # ya está: que no lo tape otro
		elif spots.size() > 1:
			values[spots.pop_at(rng.randi_range(0, spots.size() - 1))] = n
	# Siempre hay al menos una que entra y una que no (en un lugar libre)
	if not values.any(accepts):
		values[spots[0]] = NumberRule.pick(rule, rng, low, high, true)
	if values.all(accepts):
		values[spots[-1]] = NumberRule.pick(rule, rng, low, high, false)
	return values


## ¿La esfera va al cáliz?
func accepts(value: int) -> bool:
	return NumberRule.accepts(rule, value)


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
