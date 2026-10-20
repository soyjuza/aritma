@tool
## El tablero del Vórtice (Sala 3): un buscaminas de baldosas de piedra en el piso de la sala.
## Al limpiarlo, las minas quedan desactivadas (en verde) y el borde brilla.
## Todas las baldosas se ven iguales y se puede caminar sobre ellas sin que pase nada; la que
## pisa Tala se marca con un recuadro brillante. E la destapa y Q le pone o quita la bandera.
## Las minas se reparten DESPUÉS del primer destape (la primera nunca es mina) y solo si el
## tablero se puede terminar con lógica, sin adivinar (MinefieldGenerator). Cada tablero nuevo
## tiene un patrón distinto del anterior. Está apagado hasta que el Faro lo enciende.
class_name MineBoard
extends Node2D

signal exploded(cell: Vector2i)
signal cleared

enum Result { NOTHING, SAFE, MINE }

const CELL := 16
const OUTLINE := Color("101418")
const SLAB := Color("3b3550")
const SLAB_LIGHT := Color("5a5276")
const SLAB_DARK := Color("27223a")
const OPEN := Color("8d8578")
const OPEN_DARK := Color("6d665c")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const RED := Color("ff5a4e")
const GREEN := Color("6be38b")
## Colores de los números, como en el buscaminas clásico.
const NUMBER_COLORS := [Color.WHITE, Color("2f5cff"), Color("1f8a2e"), Color("e0302a"), Color("1a237e"), Color("8b1a1a"), Color("00838f"), Color("222222"), Color("707070")]

@export var cols := 8:
	set(value):
		cols = value
		queue_redraw()
@export var rows := 8:
	set(value):
		rows = value
		queue_redraw()
@export var mine_count := 10

var powered := false
var mines: Dictionary = {}       # {Vector2i: true}; vacío hasta el primer destape
var revealed: Dictionary = {}    # {Vector2i: número de minas alrededor}
var flags: Dictionary = {}       # {Vector2i: true}
var boom_cell := Vector2i(-1, -1)
var highlight := Vector2i(-1, -1)
var defused := false              # tablero limpio: las minas quedan apagadas (en verde)

var _generator := MinefieldGenerator.new("king")
var _previous: Dictionary = {}   # el patrón del tablero anterior (el nuevo debe ser distinto)
var _time := 0.0
var _power := 0.0                # 0..1: cuánto se encendió (animación)
var _font: Font = load(UIKit.PIXEL_FONT)


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows:
		for x in cols:
			out.append(Vector2i(x, y))
	return out


func in_board(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


## La baldosa bajo un punto del mundo (o (-1, -1) si está fuera del tablero).
func cell_at(world: Vector2) -> Vector2i:
	var local := to_local(world)
	var c := Vector2i(floori(local.x / CELL), floori(local.y / CELL))
	return c if in_board(c) else Vector2i(-1, -1)


func cell_center(c: Vector2i) -> Vector2:
	return to_global(Vector2(c) * CELL + Vector2(CELL, CELL) / 2.0)


func power_on() -> void:
	powered = true


## Destapa una baldosa. La primera de cada tablero reparte las minas lejos de ella.
func reveal(c: Vector2i) -> Result:
	if not powered or not in_board(c) or revealed.has(c) or flags.has(c):
		return Result.NOTHING
	if mines.is_empty():
		_place_mines(c)
	if mines.has(c):
		boom_cell = c
		exploded.emit(c)
		return Result.MINE
	_flood(c)
	if is_cleared():
		defused = true
		cleared.emit()
	return Result.SAFE


func toggle_flag(c: Vector2i) -> bool:
	if not powered or not in_board(c) or revealed.has(c):
		return false
	if flags.has(c):
		flags.erase(c)
	else:
		flags[c] = true
	return true


## Todas las baldosas sin mina están destapadas.
func is_cleared() -> bool:
	return not mines.is_empty() and revealed.size() == cols * rows - mines.size()


## Tablero nuevo: todo tapado y sin minas (se repartirán al primer destape, distintas a las
## de este tablero).
func reset() -> void:
	if not mines.is_empty():
		_previous = mines.duplicate()
	mines.clear()
	revealed.clear()
	flags.clear()
	boom_cell = Vector2i(-1, -1)
	defused = false


## El tablero ya resuelto (al cargar una partida): minas con bandera y todo lo demás destapado.
func show_solved() -> void:
	powered = true
	if mines.is_empty():
		_place_mines(Vector2i(0, 0))
	for c in cells():
		if not mines.has(c):
			revealed[c] = count_around(c)
	defused = true


func neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var n := c + Vector2i(dx, dy)
			if n != c and in_board(n):
				out.append(n)
	return out


func count_around(c: Vector2i) -> int:
	return neighbors(c).filter(func(n): return mines.has(n)).size()


func _place_mines(first: Vector2i) -> void:
	for attempt in 50:
		mines = _generator.generate(cells(), mine_count, first)
		if mines != _previous:
			return


func _flood(start: Vector2i) -> void:
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		if revealed.has(c) or mines.has(c):
			continue
		flags.erase(c)
		var n := count_around(c)
		revealed[c] = n
		if n == 0:
			stack.append_array(neighbors(c))


# ------------------------------------------------------------------ dibujo

func _process(delta: float) -> void:
	_time += delta
	_power = move_toward(_power, 1.0 if powered else 0.0, delta * 1.5)
	if not Engine.is_editor_hint():
		var player: Node2D = get_tree().get_first_node_in_group("player")
		highlight = cell_at(player.global_position) if player else Vector2i(-1, -1)
	queue_redraw()


func _draw() -> void:
	var size := Vector2(cols, rows) * CELL
	draw_rect(Rect2(Vector2(-3, -3), size + Vector2(6, 6)), OUTLINE)
	draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), CYAN.lerp(SLAB_DARK, 1.0 - _power * 0.6), false, 1.0)
	if defused:
		var glow := 0.55 + 0.45 * sin(_time * 4.0)
		draw_rect(Rect2(Vector2(-4, -4), size + Vector2(8, 8)), Color(GREEN, glow), false, 2.0)
		draw_rect(Rect2(Vector2(-7, -7), size + Vector2(14, 14)), Color(GREEN, glow * 0.35), false, 2.0)
	for c in cells():
		_draw_cell(c)
	if powered and highlight != Vector2i(-1, -1):
		var r := Rect2(Vector2(highlight) * CELL, Vector2(CELL, CELL))
		var pulse := 0.6 + 0.4 * sin(_time * 7.0)
		draw_rect(r.grow(1), Color(GOLD, pulse), false, 2.0)


func _draw_cell(c: Vector2i) -> void:
	var r := Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))
	if revealed.has(c):
		draw_rect(r, OPEN_DARK)
		draw_rect(r.grow(-1), OPEN)
		var n: int = revealed[c]
		if n > 0:
			_draw_text(str(n), r.get_center(), NUMBER_COLORS[n])
		return
	if defused and mines.has(c):
		# Mina desactivada: losa verde con la mina apagada y una marca de "seguro"
		draw_rect(r, OUTLINE)
		draw_rect(r.grow(-1), GREEN.darkened(0.45))
		draw_circle(r.get_center(), 4.0, GREEN.darkened(0.7))
		draw_rect(Rect2(r.get_center() - Vector2(3, 0.5), Vector2(6, 1)), GREEN)
		draw_rect(r.grow(-1), Color(GREEN, 0.15 + 0.15 * sin(_time * 4.0 + c.x + c.y)))
		return
	if c == boom_cell:
		draw_rect(r, RED.darkened(0.3))
		draw_circle(r.get_center(), 4.0, OUTLINE)
		draw_circle(r.get_center() + Vector2(-1, -1), 1.2, Color.WHITE)
		return
	# Losa tapada: más oscura apagada; encendida, una runa cian tenue en el centro
	draw_rect(r, OUTLINE)
	draw_rect(r.grow(-1), SLAB.lerp(SLAB_DARK, 1.0 - _power))
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(CELL - 2, 2)), SLAB_LIGHT.lerp(SLAB_DARK, 1.0 - _power))
	if _power > 0.0:
		var glow := Color(CYAN, 0.18 * _power + 0.06 * sin(_time * 2.0 + c.x + c.y) * _power)
		draw_rect(Rect2(r.get_center() - Vector2(2, 2), Vector2(4, 4)), glow)
	if flags.has(c):
		var base := r.get_center() + Vector2(-2, 5)
		draw_line(base, base + Vector2(0, -10), Color("d9d2c0"), 1.0)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -10), base + Vector2(6, -7.5), base + Vector2(0, -5)]), RED)


## Texto al doble y a media escala (nítido en pixel art).
func _draw_text(text: String, center: Vector2, color: Color) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_set_transform(center, 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 4, Color(1, 1, 1, 0.85))
	draw_string(_font, Vector2(-w / 2.0, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)
	draw_set_transform(Vector2.ZERO)
