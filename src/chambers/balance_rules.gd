## Reglas de la Balanza de los Aritmanos (Sala 4), sin nada visible.
## Cada juego de pesas se puede repartir en dos grupos que suman lo mismo (se arma así a
## propósito). El programa del jugador pone cada pesa (por su número de posición) en el plato
## izquierdo o en el derecho; al final la balanza debe quedar nivelada y sin pesas sueltas.
class_name BalanceRules
extends RefCounted

enum Verdict { LEVEL, UNEQUAL, LEFT_OUT, ERROR }

const LEFT := 0
const RIGHT := 1

var weights: Array = []          # [7, 3, 12, ...]
var placed: Array = []           # por pesa: -1 (sin poner), LEFT o RIGHT
var order: Array = []            # [[índice, lado], ...] en el orden en que se pusieron


func _init(p_weights: Array) -> void:
	weights = p_weights.duplicate()
	placed.resize(weights.size())
	placed.fill(-1)


## Un juego de "count" pesas (entre lo y hi) que SIEMPRE se puede nivelar: se arman dos
## grupos y la última pesa de un grupo se calcula para que las sumas den igual. Con greedy,
## además se nivela poniendo cada pesa, en orden, en el plato más liviano (la versión fácil).
static func make_set(count: int, rng: RandomNumberGenerator, lo := 2, hi := 19, greedy := false) -> Array:
	for attempt in 5000:
		var left_count := rng.randi_range(2, count - 2)
		var left: Array = []
		var right: Array = []
		for i in left_count:
			left.append(rng.randi_range(lo, hi))
		for i in count - left_count - 1:
			right.append(rng.randi_range(lo, hi))
		var last: int = _sum(left) - _sum(right)
		if last < lo or last > hi + 6:
			continue
		right.append(last)
		var all := left + right
		for i in range(all.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = all[i]
			all[i] = all[j]
			all[j] = tmp
		if greedy and not lighter_plate_works(all):
			continue
		return all
	return [6, 6, 5, 5, 3, 3, 2, 2].slice(0, count) if count % 2 == 0 else [8, 4, 4, 3, 3, 2, 2].slice(0, count)


## ¿Se nivela poniendo cada pesa, en orden, en el plato más liviano (si empatan, el izquierdo)?
static func lighter_plate_works(list: Array) -> bool:
	var left := 0
	var right := 0
	for w in list:
		if left <= right:
			left += int(w)
		else:
			right += int(w)
	return left == right


static func _sum(list: Array) -> int:
	var s := 0
	for v in list:
		s += int(v)
	return s


## Pone la pesa "index" en un plato. Devuelve "" o la clave del error.
func put(index, side: int) -> String:
	if typeof(index) != TYPE_INT or index < 0 or index >= weights.size():
		return "bad_index"
	if placed[index] != -1:
		return "twice"
	placed[index] = side
	order.append([index, side])
	return ""


func total(side: int) -> int:
	var s := 0
	for i in weights.size():
		if placed[i] == side:
			s += int(weights[i])
	return s


func left_out() -> Array:
	var out: Array = []
	for i in weights.size():
		if placed[i] == -1:
			out.append(i)
	return out


func verdict() -> Verdict:
	if not left_out().is_empty():
		return Verdict.LEFT_OUT
	return Verdict.LEVEL if total(LEFT) == total(RIGHT) else Verdict.UNEQUAL


## ¿Existe un reparto que nivele? (para las pruebas: siempre debe existir).
static func has_solution(list: Array) -> bool:
	var total_sum := _sum(list)
	if total_sum % 2 != 0:
		return false
	var reachable := {0: true}
	for w in list:
		var next := reachable.duplicate()
		for s in reachable.keys():
			next[s + int(w)] = true
		reachable = next
	return reachable.has(total_sum / 2)
