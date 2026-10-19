## Genera campos de trampas con una garantía: el campo siempre se puede resolver a partir de
## la primera baldosa usando solo las dos reglas básicas del buscaminas, sin adivinar.
## La vecindad es configurable: "king" (las 8 casillas de alrededor, el buscaminas clásico)
## o "knight" (las 8 casillas a un salto de caballo de ajedrez).
class_name MinefieldGenerator
extends RefCounted

const MAX_ATTEMPTS := 3000
const NEIGHBORHOODS := {
	"king": [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
	"knight": [Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)],
}

var offsets: Array
var _rng := RandomNumberGenerator.new()


func _init(neighborhood := "king") -> void:
	offsets = NEIGHBORHOODS.get(neighborhood, NEIGHBORHOODS.king)
	_rng.randomize()


## cells: baldosas del campo. first: la primera baldosa descubierta (ella y sus vecinas quedan libres).
## Devuelve un Dictionary usado como conjunto: {celda_con_trampa: true}
func generate(cells: Array[Vector2i], mine_count: int, first: Vector2i) -> Dictionary:
	var field := {}
	for c in cells:
		field[c] = true
	var safe := {first: true}
	for n in neighbors(field, first):
		safe[n] = true
	var candidates: Array[Vector2i] = []
	for c in cells:
		if not safe.has(c):
			candidates.append(c)
	var count := mini(mine_count, candidates.size())
	var mines := {}
	for attempt in MAX_ATTEMPTS:
		_shuffle(candidates)
		mines = {}
		for i in count:
			mines[candidates[i]] = true
		if is_solvable(field, mines, first):
			return mines
	return mines


func _shuffle(list: Array[Vector2i]) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := list[i]
		list[i] = list[j]
		list[j] = tmp


## Simula a un jugador que solo usa lógica:
##   1) si un número ya tiene todas sus trampas marcadas, sus otras vecinas son seguras;
##   2) si un número tiene tantas vecinas tapadas como su valor, todas son trampas.
## Si llega a descubrir todo el campo, el campo se resuelve sin adivinar.
func is_solvable(field: Dictionary, mines: Dictionary, first: Vector2i) -> bool:
	var revealed := {}
	var flagged := {}
	_flood(field, mines, revealed, first)
	var changed := true
	while changed:
		changed = false
		for c in revealed.keys():
			var unknown := {}
			var known_mines := 0
			for n in neighbors(field, c):
				if flagged.has(n):
					known_mines += 1
				elif not revealed.has(n):
					unknown[n] = true
			if unknown.is_empty():
				continue
			var left := count_mines(field, mines, c) - known_mines
			if left == 0:
				for n in unknown.keys():
					_flood(field, mines, revealed, n)
				changed = true
			elif left == unknown.size():
				for n in unknown.keys():
					flagged[n] = true
				changed = true
	return revealed.size() == field.size() - mines.size()


func neighbors(field: Dictionary, cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in offsets:
		var n: Vector2i = cell + offset
		if field.has(n):
			out.append(n)
	return out


func count_mines(field: Dictionary, mines: Dictionary, cell: Vector2i) -> int:
	var count := 0
	for n in neighbors(field, cell):
		if mines.has(n):
			count += 1
	return count


func _flood(field: Dictionary, mines: Dictionary, revealed: Dictionary, start: Vector2i) -> void:
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if revealed.has(c) or mines.has(c) or not field.has(c):
			continue
		revealed[c] = true
		if count_mines(field, mines, c) == 0:
			stack.append_array(neighbors(field, c))
