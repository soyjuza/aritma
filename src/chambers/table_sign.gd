## Dibujo de una tablilla de piedra con una tabla (nombre, columnas y filas) sobre una máquina.
class_name TableSign
extends RefCounted

const OUTLINE := Color("14181c")
const STONE := Color("2b3238")
const STONE_DARK := Color("1b2226")
const BRONZE := Color("b48a4e")
const GOLD := Color("ffd27a")
const CYAN := Color("3fe0ff")
const TEXT := Color("e9f7ff")
const MUTED := Color("8d97a8")


## Tamaño que ocupa la tabla dibujada con letra size.
static func measure(font: Font, columns: Array, rows: Array, size := 7, title := "") -> Vector2:
	var widths := _widths(font, columns, rows, size)
	var w := 4.0
	for x in widths:
		w += x
	if title != "":
		w = maxf(w, _width(font, title, size) + 8)
	return Vector2(w, (rows.size() + 1 + (1 if title != "" else 0)) * (size + 4) + 4)


## Dibuja la tabla con su esquina de arriba a la izquierda en at.
## marks: {fila: color} pinta esas filas. Devuelve el rectángulo que ocupó.
static func draw(ci: CanvasItem, font: Font, columns: Array, rows: Array, at: Vector2, size := 7, title := "", marks: Dictionary = {}) -> Rect2:
	var widths := _widths(font, columns, rows, size)
	var box := Rect2(at, measure(font, columns, rows, size, title))
	var row_h := size + 4.0
	ci.draw_rect(box.grow(2), OUTLINE)
	ci.draw_rect(box.grow(1), BRONZE)
	ci.draw_rect(box, STONE)
	var y := at.y + 2
	if title != "":
		text(ci, font, title, Vector2(box.get_center().x, y + size), size, GOLD, true)
		y += row_h
	# Encabezado
	ci.draw_rect(Rect2(at.x + 2, y, box.size.x - 4, row_h), STONE_DARK)
	var x := at.x + 2
	for i in columns.size():
		text(ci, font, String(columns[i]), Vector2(x + 3, y + size), size, CYAN)
		x += widths[i]
	y += row_h
	for r in rows.size():
		if marks.has(r):
			ci.draw_rect(Rect2(at.x + 2, y, box.size.x - 4, row_h), Color(marks[r], 0.35))
		x = at.x + 2
		for i in columns.size():
			var value: String = SqlEngine.show(rows[r][i]) if i < rows[r].size() else ""
			text(ci, font, value, Vector2(x + 3, y + size), size, TEXT)
			x += widths[i]
		y += row_h
	return box


## Texto nítido: se dibuja al doble y se achica a la mitad.
static func text(ci: CanvasItem, font: Font, s: String, at: Vector2, size: int, color: Color, centered := false) -> void:
	if font == null:
		return
	var big := size * 2
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	var origin := Vector2(-w / 2.0 if centered else 0.0, 0)
	ci.draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	ci.draw_string_outline(font, origin, s, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 4, OUTLINE)
	ci.draw_string(font, origin, s, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	ci.draw_set_transform(Vector2.ZERO)


static func _width(font: Font, s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size * 2).x / 2.0 if font else s.length() * size * 0.5


static func _widths(font: Font, columns: Array, rows: Array, size: int) -> Array:
	var out: Array = []
	for i in columns.size():
		var w := _width(font, String(columns[i]), size)
		for r in rows:
			if i < r.size():
				w = maxf(w, _width(font, SqlEngine.show(r[i]), size))
		out.append(w + 7)
	return out
