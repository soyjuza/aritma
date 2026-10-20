@tool
## El sendero de la Singularidad (Sala 5): sobre el abismo flota una cuadrícula de losas con un
## número grabado cada una. Solo aguantan las que cumplen la regla de la sala («múltiplos de 3»,
## por ejemplo); las demás se desmoronan al pisarlas. Siempre hay un camino de losas buenas
## desde el borde de abajo hasta la losa dorada del núcleo, arriba. Las losas rotas quedan como
## hueco. Fuera de la cuadrícula y en los huecos, se cae.
class_name NumberPath
extends Node2D

const OUTLINE := Color("101418")
const STONE := Color("8a83a0")
const STONE_LIGHT := Color("b3abc8")
const STONE_DARK := Color("514b63")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
## Cuánto perdona el borde entre una losa buena y una mala (px): pisar la orilla no rompe nada.
const EDGE_GRACE := 4.0

## La zona del abismo (en coordenadas de este nodo): fuera de ella el piso es firme.
@export var void_rect := Rect2(24, 56, 448, 180):
	set(value):
		void_rect = value
		queue_redraw()
@export var cols := 9:
	set(value):
		cols = value
		queue_redraw()
@export var rows := 5:
	set(value):
		rows = value
		queue_redraw()
@export var cell := 36.0:
	set(value):
		cell = value
		queue_redraw()

var multiple := 3                   # la regla: solo aguantan los múltiplos de este número
var numbers: Dictionary = {}        # {Vector2i: número grabado}
var path: Array[Vector2i] = []      # el camino bueno, de abajo hacia el núcleo
var broken: Dictionary = {}         # {Vector2i: segundos desde que se rompió}
var goal := Vector2i(-1, -1)        # la losa dorada del núcleo (fila de arriba)
var core_taken := false
var standing := Vector2i(-1, -1)    # la losa que pisa Tala (se marca)

var _time := 0.0
var _font: Font = load(UIKit.PIXEL_FONT)


## Arma un sendero nuevo: el camino bueno, unas losas buenas sueltas y el resto, números que
## no cumplen la regla.
func generate(rng: RandomNumberGenerator, p_multiple: int, extra_safe := 3, top := 60) -> void:
	multiple = p_multiple
	numbers.clear()
	broken.clear()
	path = _random_path(rng)
	goal = path[-1]
	var safe := {}
	for c in path:
		safe[c] = true
	# Losas buenas sueltas junto al camino: callejones sin salida que obligan a seguir pensando
	var spots: Array[Vector2i] = []
	for c in path:
		for n in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.DOWN]:
			if in_grid(n) and not safe.has(n) and n.y > 0 and not n in spots:
				spots.append(n)
	for i in mini(extra_safe, spots.size()):
		var k := rng.randi_range(i, spots.size() - 1)
		var tmp := spots[i]
		spots[i] = spots[k]
		spots[k] = tmp
		safe[spots[i]] = true
	for y in rows:
		for x in cols:
			var c := Vector2i(x, y)
			numbers[c] = _good_number(rng, top) if safe.has(c) else _bad_number(rng, top)


## Un camino al azar por losas vecinas (sin diagonales), de la fila de abajo a la de arriba.
func _random_path(rng: RandomNumberGenerator) -> Array[Vector2i]:
	var c := Vector2i(rng.randi_range(1, cols - 2), rows - 1)
	var out: Array[Vector2i] = [c]
	var side := 0          # paso de costado en curso (−1, 0 o 1)
	var run := 0           # cuántos pasos lleva de costado
	while c.y > 0:
		var moves: Array[Vector2i] = []
		if run < 3:
			for dx in ([side] if side != 0 else [-1, 1]):
				var n := c + Vector2i(dx, 0)
				if in_grid(n) and not n in out:
					moves.append(n)
		# Subir es lo más común, pero de costado al menos una vez cada dos filas
		if moves.is_empty() or rng.randf() < 0.45:
			moves = [c + Vector2i.UP]
		var next: Vector2i = moves[rng.randi_range(0, moves.size() - 1)]
		if next.y == c.y:
			run += 1
			side = next.x - c.x
		else:
			run = 0
			side = 0
		c = next
		out.append(c)
	return out


func _good_number(rng: RandomNumberGenerator, top: int) -> int:
	return multiple * rng.randi_range(1, top / multiple)


func _bad_number(rng: RandomNumberGenerator, top: int) -> int:
	var n := multiple
	while n % multiple == 0:
		n = rng.randi_range(2, top)
	return n


func in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func is_safe(c: Vector2i) -> bool:
	return numbers.has(c) and int(numbers[c]) % multiple == 0


func origin() -> Vector2:
	return Vector2(void_rect.get_center().x - cols * cell / 2.0, void_rect.end.y - rows * cell)


func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(origin() + Vector2(c) * cell, Vector2(cell, cell))


func cell_center_global(c: Vector2i) -> Vector2:
	return to_global(cell_rect(c).get_center())


## La losa bajo un punto del mundo (o (-1, -1) fuera de la cuadrícula). En la orilla entre una
## losa mala y una buena cuenta la buena.
func cell_at(world: Vector2) -> Vector2i:
	var p := to_local(world) - origin()
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	if not in_grid(c):
		return Vector2i(-1, -1)
	if is_safe(c) or broken.has(c):
		return c
	for n in [c + Vector2i.LEFT, c + Vector2i.RIGHT, c + Vector2i.UP, c + Vector2i.DOWN]:
		if in_grid(n) and is_safe(n) and not broken.has(n) and cell_rect(n).grow(EDGE_GRACE).has_point(to_local(world)):
			return n
	return c


## ¿El punto (del mundo) está sobre el abismo? (fuera de él el piso es firme)
func over_void(world: Vector2) -> bool:
	return void_rect.has_point(to_local(world))


func crumble(c: Vector2i) -> void:
	broken[c] = 0.0


func _process(delta: float) -> void:
	_time += delta
	for c in broken:
		broken[c] += delta
	if not Engine.is_editor_hint():
		var player: Node2D = get_tree().get_first_node_in_group("player")
		standing = cell_at(player.global_position) if player else Vector2i(-1, -1)
	queue_redraw()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	_draw_void()
	if Engine.is_editor_hint() and numbers.is_empty():
		_preview()
	for y in rows:
		for x in cols:
			_draw_stone(Vector2i(x, y))


## En el editor todavía no hay números: una cuadrícula de muestra para ver el tamaño.
func _preview() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	generate(rng, 3)


func _draw_void() -> void:
	draw_rect(void_rect.grow(2), OUTLINE)
	draw_rect(void_rect, Color("07060d"))
	# Remolino del vórtice y polvo de estrellas
	var c := void_rect.get_center()
	for k in 5:
		var r := 30.0 + k * 34.0
		draw_arc(c, r, _time * (0.3 + k * 0.07), _time * (0.3 + k * 0.07) + PI * 1.2, 40, Color(0.45, 0.3, 0.9, 0.10), 2.0)
	for k in 40:
		var x := fmod(k * 97.3 + _time * (4.0 + k % 5), void_rect.size.x)
		var y := fmod(k * 53.7 + k * k * 1.3, void_rect.size.y)
		var a := 0.25 + 0.25 * sin(_time * 2.0 + k)
		draw_rect(Rect2(void_rect.position + Vector2(x, y), Vector2(1, 1)), Color(0.8, 0.85, 1.0, a))


func _draw_stone(c: Vector2i) -> void:
	var r := cell_rect(c).grow(-1.5)
	if broken.has(c):
		# Se desmorona: los pedazos caen al vacío y se apagan
		var t: float = broken[c]
		if t < 0.6:
			var k := t / 0.6
			for i in 4:
				var piece := Rect2(r.position + Vector2(i % 2, i / 2) * r.size / 2.0, r.size / 2.0)
				piece = Rect2(piece.get_center() - piece.size * (1.0 - k) / 2.0, piece.size * (1.0 - k)).grow(-1)
				draw_rect(piece, Color(STONE_DARK, 1.0 - k))
		return
	var golden := c == goal
	draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.5))
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, Color("b58a3c") if golden else STONE)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color("f0c870") if golden else STONE_LIGHT)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), Color("7a5a22") if golden else STONE_DARK)
	if c == standing and not golden:
		draw_rect(r.grow(0.5), Color(CYAN, 0.55 + 0.25 * sin(_time * 6.0)), false, 1.0)
	if golden:
		if not core_taken:
			var pulse := 0.5 + 0.5 * sin(_time * 3.0)
			draw_circle(r.get_center() + Vector2(0, -2), 8.0 + pulse, Color(GOLD, 0.3))
			draw_circle(r.get_center() + Vector2(0, -2), 5.0, Color("fff2c0"))
			draw_circle(r.get_center() + Vector2(-1.5, -3.5), 1.8, Color.WHITE)
		return
	_text_center(str(numbers.get(c, "")), r.get_center() + Vector2(0, 5), 12, Color.WHITE)


func _text_center(text: String, at: Vector2, size: int, color: Color) -> void:
	var big := size * 2
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 5, OUTLINE)
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	draw_set_transform(Vector2.ZERO)
