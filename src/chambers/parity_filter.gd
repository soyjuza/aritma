## Reglas de la Criba (Sala 1, El Filtro de la Dualidad), sin nada de 3D.
## Cada ronda trae esferas numeradas: el programa las suelta una por una a la compuerta y
## decide a dónde va cada una. Las pares van al cáliz y las impares al crisol. Mientras el
## programa corre, cada paso queda anotado como una orden (FilterCommand) para que la
## máquina 3D lo repita después con su animación.
class_name ParityFilter
extends RefCounted

enum Fault { NONE, WRONG_SIDE, LEFT_OVER }

var rounds: Array = []        # Array de Array[int]: los números de cada ronda, en orden
var round_index := 0
var commands: Array = []      # FilterCommand, en el orden en que el programa los dio
var fault := Fault.NONE
var fault_value := 0          # la esfera que falló (o cuántas quedaron sin clasificar)

var _queue: Array = []
var _held: Variant = null     # el número de la esfera que está en la compuerta


## rules: la lista "rounds" de chambers.json, por ejemplo
##   [{"count": [8, 10], "min": 1, "max": 20}, {"count": [5, 7], "min": 10, "max": 99, "zero": true}]
func _init(rules: Array, rng: RandomNumberGenerator) -> void:
	for r: Dictionary in rules:
		rounds.append(make_round(r, rng))


static func make_round(rule: Dictionary, rng: RandomNumberGenerator) -> Array:
	var counts: Array = rule.get("count", [8, 8])
	var count := rng.randi_range(int(counts[0]), int(counts[-1]))
	var values: Array = []
	for i in count:
		values.append(rng.randi_range(int(rule.get("min", 1)), int(rule.get("max", 20))))
	if bool(rule.get("zero", false)) and not 0 in values:
		values[rng.randi_range(0, count - 1)] = 0
	# Siempre hay al menos una par y una impar: así ningún atajo ("todo al cáliz") pasa
	if not values.any(func(v): return v % 2 == 0):
		values[0] = values[0] + 1
	if not values.any(func(v): return v % 2 != 0):
		values[-1] = values[-1] + 1
	return values


static func is_even(value: int) -> bool:
	return posmod(value, 2) == 0


## Empieza la ronda "index": la tolva se llena con sus esferas.
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


## Suelta la siguiente esfera a la compuerta. Devuelve un texto de error si no se puede.
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


## Manda la esfera de la compuerta al cáliz (to_chalice = true) o al crisol.
func send(to_chalice: bool) -> String:
	if failed():
		return ""
	if _held == null:
		return "send_empty"
	var value: int = _held
	_held = null
	var right := is_even(value) == to_chalice
	commands.append(FilterCommand.Send.new(value, to_chalice, right))
	if not right:
		fault = Fault.WRONG_SIDE
		fault_value = value
	return ""


## El programa terminó esta ronda: no pueden quedar esferas sin clasificar.
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
