## Tablero para armar el programa ordenando piezas (bloques) con el ratón.
## Arriba el programa, abajo las piezas. La sangría sale de dónde se suelta la pieza.
class_name BlockBoard
extends Control

signal changed

const INDENT := 34.0
const PAD := 12.0
const HEADER := 30.0
const MAX_INDENT := 3
const KEYWORDS := ["while", "if", "elif", "else", "for", "def", "return"]

const BG := Color("090d12")
const LINE := Color("1f4b57")
const TEXT := Color("ece4d0")
const KEYWORD := Color("ff9a6b")
const ACTION := Color("4fe3ff")
const GOLD := Color("e2b44f")
const MUTED := Color("8d97a8")

var session: CodexSession
var texts := {}    # títulos y avisos, los pone el Códice
var hint: Callable    # ayuda de una pieza

var _mono: Font = _plain_mono()
var _body: Font = load(UIKit.PIXEL_FONT)
var _drag := -1    # pieza que se arrastra
var _drag_back := []    # [fila, sangría] de donde salió
var _grab := Vector2.ZERO
var _press := Vector2.ZERO
var _mouse := Vector2(-999, -999)
var _selected := -1
var _time := 0.0


## Sin ligaduras: "==" se ve como dos signos.
static func _plain_mono() -> Font:
	var font := FontVariation.new()
	font.base_font = load("res://assets/fonts/JetBrainsMono.ttf")
	var ts := TextServerManager.get_primary_interface()
	font.opentype_features = {ts.name_to_tag("liga"): 0, ts.name_to_tag("calt"): 0}
	return font


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


# ------------------------------------------------------------------ medidas

func font_size() -> int:
	return 17 if size.x > 500 else 15


func program_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x, size.y * _split()))


func tray_rect() -> Rect2:
	var top := size.y * (_split() + 0.02)
	return Rect2(Vector2(0, top), Vector2(size.x, size.y - top))


## Parte del alto para el programa: si las piezas no caben en dos filas, la bandeja crece.
func _split() -> float:
	if session == null or size.y <= 0.0:
		return 0.6
	var rows := 1
	var x := PAD
	for line in session.blocks:
		var w: float = _mono.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size()).x + 22
		if x + w > size.x - PAD and x > PAD:
			rows += 1
			x = PAD
		x += w + 8
	return clampf(1.0 - (HEADER + rows * 36.0 + 28.0) / size.y, 0.4, 0.6)


func row_height() -> float:
	var rows := maxi(session.blocks.size(), 1) if session else 1
	return clampf((program_rect().size.y - HEADER - 8) / rows, 22.0, 32.0)


func piece_size(piece: int) -> Vector2:
	var w := _mono.get_string_size(session.blocks[piece], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size()).x
	return Vector2(w + 22, row_height() - 4)


func row_rect(row: int) -> Rect2:
	var p: Array = session.placed[row]
	var at := Vector2(PAD + p[1] * INDENT, HEADER + row * row_height())
	return Rect2(at, piece_size(p[0]))


## Dónde va cada pieza de la bandeja.
func tray_layout() -> Dictionary:
	var out := {}
	var area := tray_rect()
	var at := area.position + Vector2(PAD, HEADER)
	for piece in session.free_pieces():
		var s := piece_size(piece)
		if at.x + s.x > area.end.x - PAD and at.x > area.position.x + PAD:
			at = Vector2(area.position.x + PAD, at.y + s.y + 8)
		out[piece] = Rect2(at, s)
		at.x += s.x + 8
	return out


func row_at(point: Vector2) -> int:
	for row in session.placed.size():
		if row_rect(row).has_point(point):
			return row
	return -1


func tray_piece_at(point: Vector2) -> int:
	var layout := tray_layout()
	for piece in layout:
		if (layout[piece] as Rect2).has_point(point):
			return piece
	return -1


## Fila y sangría donde caería la pieza arrastrada.
func drop_target() -> Vector2i:
	var rh := row_height()
	var row := clampi(roundi((_mouse.y - _grab.y - HEADER) / rh), 0, session.placed.size())
	var left := _mouse.x - _grab.x
	return Vector2i(row, clampi(roundi((left - PAD) / INDENT), 0, max_indent(row)))


## Sangría máxima en una fila: una más que la de arriba.
func max_indent(row: int) -> int:
	if row == 0 or session.placed.is_empty():
		return 0
	return mini(int(session.placed[row - 1][1]) + 1, MAX_INDENT)


# ------------------------------------------------------------------ acciones

## Pone una pieza en el programa.
func place(piece: int, row: int, indent: int) -> void:
	row = clampi(row, 0, session.placed.size())
	session.placed.insert(row, [piece, clampi(indent, 0, max_indent(row))])
	_selected = row
	changed.emit()


## Devuelve una fila a la bandeja.
func take_back(row: int) -> void:
	session.placed.remove_at(row)
	_selected = -1
	changed.emit()


func shift(row: int, delta: int) -> void:
	if row < 0 or row >= session.placed.size():
		return
	session.placed[row][1] = clampi(int(session.placed[row][1]) + delta, 0, max_indent(row))
	changed.emit()


func move(row: int, delta: int) -> void:
	var to := row + delta
	if row < 0 or to < 0 or to >= session.placed.size():
		return
	var p: Array = session.placed[row]
	session.placed.remove_at(row)
	session.placed.insert(to, p)
	_selected = to
	shift(to, 0)


## Sangría que sigue a la fila de arriba (después de ":" va una más).
func suggested_indent(row: int) -> int:
	if row == 0:
		return 0
	var above: Array = session.placed[row - 1]
	return int(above[1]) + (1 if session.blocks[above[0]].ends_with(":") else 0)


# ------------------------------------------------------------------ ratón y teclas

func _gui_input(event: InputEvent) -> void:
	if session == null:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		_mouse = event.position
		_pick(event.position)
		accept_event()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _drag >= 0:
		_mouse = event.position
		_drop()
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var row := row_at(event.position)
		if row >= 0:
			take_back(row)
		accept_event()
	elif event is InputEventKey and event.pressed and _selected >= 0:
		_key(event)


func _key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_LEFT:
			shift(_selected, -1)
		KEY_RIGHT, KEY_TAB:
			shift(_selected, 1)
		KEY_UP:
			move(_selected, -1)
		KEY_DOWN:
			move(_selected, 1)
		KEY_DELETE, KEY_BACKSPACE:
			take_back(_selected)
		_:
			return
	accept_event()


func _pick(point: Vector2) -> void:
	_press = point
	var row := row_at(point)
	if row >= 0:
		var r := row_rect(row)
		_drag = session.placed[row][0]
		_drag_back = [row, session.placed[row][1]]
		_grab = point - r.position
		session.placed.remove_at(row)
		_selected = -1
		return
	var piece := tray_piece_at(point)
	if piece >= 0:
		_drag = piece
		_drag_back = []
		_grab = point - (tray_layout()[piece] as Rect2).position
		return
	_selected = -1


func _drop() -> void:
	var piece := _drag
	_drag = -1
	var clicked := _mouse.distance_to(_press) < 12.0
	if clicked and not _drag_back.is_empty():
		place(piece, _drag_back[0], _drag_back[1])
	elif clicked:
		# Clic en la bandeja: va al final
		place(piece, session.placed.size(), suggested_indent(session.placed.size()))
	elif program_rect().grow(16).has_point(_mouse):
		var target := drop_target()
		place(piece, target.x, target.y)
	else:
		changed.emit()


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	if session == null:
		return
	var program := program_rect()
	var tray := tray_rect()
	_box(program)
	_box(tray)
	_label(texts.get("program", ""), program.position + Vector2(PAD, 6), GOLD)
	_label(texts.get("tray", ""), tray.position + Vector2(PAD, 6), GOLD)
	var rh := row_height()
	for k in range(1, MAX_INDENT + 1):
		var x := PAD + k * INDENT - 6
		draw_line(Vector2(x, HEADER), Vector2(x, program.end.y - 6), Color(LINE, 0.55), 1.0)
	if session.placed.is_empty() and _drag < 0:
		var pulse := 0.8 + 0.2 * sin(_time * 3.0)
		var slot := Rect2(Vector2(PAD, HEADER), Vector2(program.size.x - PAD * 2, rh * 1.6))
		draw_rect(slot, Color(GOLD, 0.25 * pulse), false, 2.0)
		_label(texts.get("empty", ""), slot.position + Vector2(12, slot.size.y / 2 - 10), Color(GOLD, pulse))
	for row in session.placed.size():
		_piece(session.placed[row][0], row_rect(row), row == _selected, 1.0)
	var layout := tray_layout()
	for piece in layout:
		_piece(piece, layout[piece], false, 1.0)
	if session.free_pieces().is_empty() and _drag < 0:
		_label(texts.get("tray_empty", ""), tray.position + Vector2(PAD, HEADER + 4), MUTED)
	if _drag >= 0:
		_draw_drag(program)
	_draw_hint(tray, layout)


func _draw_drag(program: Rect2) -> void:
	if program.grow(16).has_point(_mouse):
		var target := drop_target()
		var y := HEADER + target.x * row_height() - 3
		var x := PAD + target.y * INDENT
		draw_line(Vector2(x, y), Vector2(program.end.x - PAD, y), GOLD, 3.0)
		draw_circle(Vector2(x, y), 4.0, GOLD)
		var ghost := Rect2(Vector2(x, y + 3), piece_size(_drag))
		draw_rect(ghost, Color(GOLD, 0.25), false, 2.0)
	_piece(_drag, Rect2(_mouse - _grab, piece_size(_drag)), true, 0.92)


func _draw_hint(tray: Rect2, layout: Dictionary) -> void:
	var text := String(texts.get("keys", ""))
	var piece := _drag
	if piece < 0:
		var row := row_at(_mouse)
		piece = session.placed[row][0] if row >= 0 else tray_piece_at(_mouse)
	if piece >= 0 and hint.is_valid():
		var help := String(hint.call(session.blocks[piece]))
		if help != "":
			text = help
	draw_string(_body, Vector2(PAD, tray.end.y - 10), text, HORIZONTAL_ALIGNMENT_LEFT, tray.size.x - PAD * 2, 17, MUTED)


func _box(r: Rect2) -> void:
	draw_rect(r, BG)
	draw_rect(r, LINE, false, 1.0)


func _label(text: String, at: Vector2, color: Color) -> void:
	draw_string(_body, at + Vector2(0, 17), text, HORIZONTAL_ALIGNMENT_LEFT, size.x - at.x - PAD, 20, color)


## Una pieza: borde naranja si es while/if/def, cian si es una orden.
func _piece(piece: int, r: Rect2, lit: bool, alpha: float) -> void:
	var line: String = session.blocks[piece]
	var first: String = line.split(" ")[0].trim_suffix(":")
	var control: bool = first in KEYWORDS
	var edge := KEYWORD if control else ACTION
	draw_rect(r, Color(Color("141c26").lerp(edge, 0.12), alpha))
	draw_rect(Rect2(r.position, Vector2(4, r.size.y)), Color(edge, alpha))
	draw_rect(r, Color(GOLD if lit else edge.darkened(0.35), alpha), false, 2.0 if lit else 1.0)
	var fs := font_size()
	var base := r.position + Vector2(11, (r.size.y + _mono.get_ascent(fs) - _mono.get_descent(fs)) / 2.0)
	if control:
		draw_string(_mono, base, first, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(KEYWORD, alpha))
		base.x += _mono.get_string_size(first, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		line = line.substr(first.length())
	draw_string(_mono, base, line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(TEXT, alpha))
