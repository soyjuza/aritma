## Reglas de la red de la Singularidad (Sala 5), sin nada visible.
## Plataformas numeradas (0, 1, 2...) unidas por conexiones de luz. El programa del jugador
## busca un camino de red.inicio a red.salida y lo pasa a puentes.levantar(camino). Con
## require_shortest la red solo tiene energía para el camino MÁS CORTO (hay que buscar en
## anchura); sin él sirve cualquier camino que llegue (la versión fácil, la del juego).
class_name NetworkRules
extends RefCounted

var positions: Array = []        # [Vector2] (solo para medir distancias al armar la red)
var edges: Array = []            # [[a, b], ...] con a < b
var start := 0
var goal := 0
var path: Array = []             # lo que pasó el programa a puentes.levantar()
var raised := false
var require_shortest := false   # true: solo vale el camino más corto

var _adjacent: Dictionary = {}   # {id: [vecinos]}


func _init(p_positions: Array, p_edges: Array, p_start: int, p_goal: int) -> void:
	positions = p_positions
	start = p_start
	goal = p_goal
	edges = p_edges
	for i in positions.size():
		_adjacent[i] = []
	for e in edges:
		_adjacent[e[0]].append(e[1])
		_adjacent[e[1]].append(e[0])
	for i in _adjacent.keys():
		_adjacent[i].sort()


## Una red al azar sobre esas plataformas: los números de las plataformas se reparten al azar
## (cambian en cada red), se conectan las que están cerca (sin que el puente pase por encima de
## otra plataforma) y se acepta si el camino más corto tiene entre min_len y max_len puentes Y
## (solo con shortest) si una búsqueda en profundidad, en cualquiera de los dos órdenes de los
## vecinos, encuentra un camino más largo: así solo la búsqueda en anchura sirve.
static func make(p_positions: Array, p_start: int, p_goal: int, rng: RandomNumberGenerator, reach := 112.0, keep := 0.55, min_len := 4, max_len := 6, shortest := false) -> NetworkRules:
	for attempt in 600:
		# Números nuevos: la plataforma de la posición p_positions[k] pasa a llamarse order.find(k)
		var order: Array = range(p_positions.size())
		for i in range(order.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = order[i]
			order[i] = order[j]
			order[j] = tmp
		var shuffled: Array = order.map(func(k): return p_positions[k])
		var candidates: Array = []
		for a in shuffled.size():
			for b in range(a + 1, shuffled.size()):
				if shuffled[a].distance_to(shuffled[b]) <= reach and _clear_line(shuffled, a, b):
					candidates.append([a, b])
		var chosen: Array = candidates.filter(func(_e): return rng.randf() < keep)
		var net := NetworkRules.new(shuffled, chosen, order.find(p_start), order.find(p_goal))
		net.require_shortest = shortest
		var length := net.shortest_path().size() - 1
		if length < min_len or length > max_len:
			continue
		if not shortest or (net.depth_first_path(false).size() - 1 > length and net.depth_first_path(true).size() - 1 > length):
			return net
	var all: Array = []
	for a in p_positions.size():
		for b in range(a + 1, p_positions.size()):
			if p_positions[a].distance_to(p_positions[b]) <= reach and _clear_line(p_positions, a, b):
				all.append([a, b])
	var fallback := NetworkRules.new(p_positions, all, p_start, p_goal)
	fallback.require_shortest = shortest
	return fallback


## El puente de a a b no pasa por encima de otra plataforma.
static func _clear_line(p_positions: Array, a: int, b: int) -> bool:
	var pa: Vector2 = p_positions[a]
	var pb: Vector2 = p_positions[b]
	for i in p_positions.size():
		if i == a or i == b:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(p_positions[i], pa, pb)
		if closest.distance_to(p_positions[i]) < 20.0:
			return false
	return true


func count() -> int:
	return positions.size()


func neighbors(id: int) -> Array:
	return _adjacent.get(id, []).duplicate()


func connected(a: int, b: int) -> bool:
	return b in _adjacent.get(a, [])


## Camino más corto (búsqueda en anchura). [] si no hay.
func shortest_path() -> Array:
	var prev := {start: -1}
	var queue: Array = [start]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == goal:
			break
		for n in _adjacent[current]:
			if not prev.has(n):
				prev[n] = current
				queue.append(n)
	if not prev.has(goal):
		return []
	var out: Array = []
	var x := goal
	while x != -1:
		out.push_front(x)
		x = prev[x]
	return out


## Cuántos puentes separan la plataforma id del núcleo (-1 si no hay camino). Es lo que
## devuelve red.distancia(id) en el Códice.
func distance_to_goal(id: int) -> int:
	var dist := {goal: 0}
	var queue: Array = [goal]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == id:
			return dist[current]
		for n in _adjacent[current]:
			if not dist.has(n):
				dist[n] = dist[current] + 1
				queue.append(n)
	return -1


## El vecino de id que está más cerca del núcleo (red.mas_cercano(id) en el Códice). Si id ya
## es el núcleo o no tiene vecinos, devuelve el mismo id.
func closest_neighbor(id: int) -> int:
	var best := id
	var best_distance := distance_to_goal(id)
	for n in _adjacent.get(id, []):
		var d := distance_to_goal(n)
		if d >= 0 and (best_distance < 0 or d < best_distance):
			best = n
			best_distance = d
	return best


## El primer camino que encuentra una búsqueda en profundidad (la "solución ingenua"), tomando
## los vecinos en orden creciente o, con reverse, en orden decreciente.
func depth_first_path(reverse: bool) -> Array:
	var visited := {start: true}
	var stack: Array = [[start]]
	while not stack.is_empty():
		var current: Array = stack.pop_back()
		var last: int = current[-1]
		if last == goal:
			return current
		var next: Array = _adjacent[last].duplicate()
		if not reverse:
			next.reverse()
		for n in next:
			if not visited.has(n):
				visited[n] = true
				stack.append(current + [n])
	return []


## Revisa el camino. Devuelve "" si sirve o la clave del problema.
func check(candidate) -> String:
	if typeof(candidate) != TYPE_ARRAY or candidate.is_empty():
		return "not_a_path"
	for id in candidate:
		if typeof(id) != TYPE_INT or id < 0 or id >= count():
			return "bad_platform"
	if candidate[0] != start:
		return "wrong_start"
	if candidate[-1] != goal:
		return "wrong_end"
	for i in range(1, candidate.size()):
		if not connected(candidate[i - 1], candidate[i]):
			return "not_connected"
	if require_shortest and candidate.size() > shortest_path().size():
		return "too_long"
	return ""
