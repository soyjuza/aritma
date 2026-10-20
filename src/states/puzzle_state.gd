## PATRÓN STATE — La Mesa de las Figuras abierta (Sala 4). A la izquierda, la figura grande;
## a la derecha, las piezas. Se arrastran con el ratón, R o clic derecho las gira y, al
## soltarlas sobre la figura, encajan en la cuadrícula si caben. Una pieza puesta se puede volver
## a levantar. El mundo queda quieto, pero el reloj de 15 minutos sigue corriendo.
## Al llenar la figura pasa a la siguiente; con la última, la mesa queda resuelta.
class_name PuzzleState
extends GameState

const CELL := 48.0
const SLOT := 3.4                     # cada hueco de la bandeja mide 3,4 × 3,4 casillas
const COLORS := [Color("e2b44f"), Color("4fe3ff"), Color("6be38b"), Color("ff7a5c"), Color("b78bff"), Color("ff9fd0")]
const SOLVED_PAUSE := 1.4

var table: FigureTable

var _held := -1                       # la pieza que se arrastra (-1: ninguna)
var _grab := Vector2.ZERO             # dónde se tomó, respecto de la esquina de la pieza
var _order: Array = []                # orden de las piezas en la bandeja
var _solved_at := -1.0                # ui.time en que se llenó la figura (-1: todavía no)
var _mouse := Vector2.ZERO            # el ratón, en coordenadas de la pantalla de la interfaz
var _rotated := false                 # ya giró alguna pieza: el aviso de girar deja de latir


func enter(params: Dictionary = {}) -> void:
	table = params.get("table")
	_held = -1
	_solved_at = -1.0
	_mouse = game.overlay.get_local_mouse_position()
	_shuffle_tray()
	game.player.controls_enabled = false


func exit() -> void:
	_held = -1


func timer_runs() -> bool:
	return true


func freezes_world() -> bool:
	return true


func _puzzle() -> FigurePuzzle:
	return table.puzzle()


## Las piezas se reparten en la bandeja en un orden al azar (no en el de la solución).
func _shuffle_tray() -> void:
	_order = range(_puzzle().pieces.size())
	_order.shuffle()


# ------------------------------------------------------------------ medidas en pantalla

func _panel(ui: UIKit) -> Rect2:
	var s := ui.size()
	return Rect2((s.x - 1180) / 2.0, (s.y - 600) / 2.0 + 10, 1180, 600)


func _board_origin(ui: UIKit) -> Vector2:
	var p := _panel(ui)
	var center := Vector2(p.position.x + 280, p.position.y + 290)
	return (center - Vector2(_puzzle().size) * CELL / 2.0).round()


func _slot_rect(ui: UIKit, slot: int) -> Rect2:
	var p := _panel(ui)
	var size := Vector2(SLOT, SLOT) * CELL
	var col := slot % 3
	var row := slot / 3
	var left := p.position.x + 560 + (p.size.x - 580 - (size.x * 3 + 28)) / 2.0
	return Rect2(Vector2(left + col * (size.x + 14), p.position.y + 112 + row * (size.y + 14)), size)


## La esquina de arriba a la izquierda de la pieza, en pantalla.
func _piece_origin(ui: UIKit, i: int) -> Vector2:
	var puzzle := _puzzle()
	if i == _held:
		return _mouse - _grab
	if puzzle.is_placed(i):
		return _board_origin(ui) + Vector2(puzzle.pieces[i].at) * CELL
	var slot := _slot_rect(ui, _order.find(i))
	return (slot.get_center() - Vector2(FigurePuzzle.extent(puzzle.cells_of(i))) * CELL / 2.0).round()


## La pieza bajo el ratón (la de arriba si hay varias) o -1.
func _piece_at(ui: UIKit, point: Vector2) -> int:
	var puzzle := _puzzle()
	for i in range(puzzle.pieces.size() - 1, -1, -1):
		var origin := _piece_origin(ui, i)
		for c in puzzle.cells_of(i):
			if Rect2(origin + Vector2(c) * CELL, Vector2(CELL, CELL)).has_point(point):
				return i
	return -1


# ------------------------------------------------------------------ entrada

func handle_mouse(event: InputEventMouse) -> bool:
	_mouse = game.overlay.make_input_local(event).position
	if _solved_at >= 0.0 or not event is InputEventMouseButton:
		return true
	var button := event as InputEventMouseButton
	if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		_pick(game.ui, _mouse)
	elif button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		_drop(game.ui)
	elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		_rotate(game.ui, _held if _held >= 0 else _piece_at(game.ui, _mouse))
	return true


func handle_input(actions: Array) -> void:
	if _solved_at >= 0.0:
		return
	if "cancel" in actions or "pause" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change("play")
	elif "rotate" in actions:
		_rotate(game.ui, _held if _held >= 0 else _piece_at(game.ui, _mouse))


func _pick(ui: UIKit, mouse: Vector2) -> void:
	var i := _piece_at(ui, mouse)
	if i < 0:
		return
	_grab = mouse - _piece_origin(ui, i)
	_puzzle().lift(i)
	_held = i
	game.bus.publish(GameEvents.PIECE_PICKED)


## Suelta la pieza: si cae sobre la figura y cabe, encaja en la casilla más cercana; si no,
## vuelve a la bandeja.
func _drop(ui: UIKit) -> void:
	if _held < 0:
		return
	var i := _held
	var corner := (_piece_origin(ui, i) - _board_origin(ui)) / CELL
	_held = -1
	if _puzzle().place(i, Vector2i(roundi(corner.x), roundi(corner.y))):
		game.bus.publish(GameEvents.PIECE_PLACED)
		check_solved(ui)


## Si la figura quedó llena, la celebra un momento y después pasa a la siguiente.
func check_solved(ui: UIKit) -> void:
	if _solved_at < 0.0 and _puzzle().is_solved():
		_solved_at = ui.time
		game.bus.publish(GameEvents.PUZZLE_SOLVED)


## Gira una pieza. Si es la que se arrastra, queda centrada en el ratón.
func _rotate(_ui: UIKit, i: int) -> void:
	if i < 0:
		return
	_rotated = true
	var puzzle := _puzzle()
	if puzzle.is_placed(i):
		puzzle.lift(i)
	puzzle.rotate(i)
	if i == _held:
		_grab = Vector2(FigurePuzzle.extent(puzzle.cells_of(i))) * CELL / 2.0
	game.bus.publish(GameEvents.PIECE_ROTATED)


func update(_delta: float) -> void:
	if _solved_at < 0.0 or game.ui.time - _solved_at < SOLVED_PAUSE:
		return
	_solved_at = -1.0
	if table.advance():
		game.machine.change("play")
		game.dialog.say([game.data.message("figures_solved")])
	else:
		_shuffle_tray()
		game.notify([game.data.message("figures_next", {"title": _puzzle().title})], 3.0)


# ------------------------------------------------------------------ dibujo

func draw(ui: UIKit) -> void:
	ui.dim(0.55)
	Hud.new().draw_timer(ui, game.timer)
	var p := _panel(ui)
	var puzzle := _puzzle()
	ui.panel(p)
	ui.text_centered(game.data.message("figures_title", {"title": puzzle.title, "n": table.current + 1, "of": table.puzzles.size()}), p.position.y + 22, 30, UIKit.GOLD, "title")
	ui.text_centered(game.data.message("figures_hint"), p.position.y + 62, 18, UIKit.MUTED)
	if _solved_at < 0.0:
		_draw_rotate_hint(ui, p)
	# La figura: casillas vacías con borde dorado
	var origin := _board_origin(ui)
	for c in puzzle.target:
		var r := Rect2(origin + Vector2(c) * CELL, Vector2(CELL, CELL))
		ui.rect(r, Color(0.05, 0.06, 0.09, 0.95))
		ui.frame(r.grow(-1), Color(UIKit.GOLD, 0.35), 1.0)
	ui.text_centered(game.data.message("figures_board"), origin.y + puzzle.size.y * CELL + 18, 18, UIKit.MUTED, "body", origin.x + puzzle.size.x * CELL / 2.0)
	# La bandeja
	for slot in _order.size():
		var r := _slot_rect(ui, slot)
		ui.rect(r, Color(1, 1, 1, 0.03))
		ui.frame(r, Color(UIKit.CYAN, 0.18), 1.0)
	# Las piezas (la que se arrastra, encima de todas)
	for i in puzzle.pieces.size():
		if i != _held:
			_draw_piece(ui, i)
	if _held >= 0:
		_draw_shadow(ui, _held)
		_draw_piece(ui, _held)
	if _solved_at >= 0.0:
		var pulse := 0.5 + 0.5 * sin(ui.time * 8.0)
		ui.frame(Rect2(origin, Vector2(puzzle.size) * CELL).grow(6), Color(UIKit.GOOD, 0.5 + 0.5 * pulse), 4.0)
		ui.text_centered(game.data.message("figures_full"), p.end.y - 54, 26, UIKit.GOOD, "bold")
	else:
		ui.key_hint("ESC", game.data.message("figures_close"), Vector2(p.position.x + 24, p.end.y - 40))


func _draw_piece(ui: UIKit, i: int) -> void:
	var origin := _piece_origin(ui, i)
	var color: Color = COLORS[i % COLORS.size()]
	for c in _puzzle().cells_of(i):
		var r := Rect2(origin + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-2)
		ui.rect(r, color.darkened(0.45))
		ui.rect(r.grow(-3), color)
		ui.rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 4)), color.lightened(0.35))


## Dónde caería la pieza que se arrastra: verde si cabe ahí.
func _draw_shadow(ui: UIKit, i: int) -> void:
	var puzzle := _puzzle()
	var corner := (_piece_origin(ui, i) - _board_origin(ui)) / CELL
	var at := Vector2i(roundi(corner.x), roundi(corner.y))
	if not puzzle.can_place(i, at):
		return
	for c in puzzle.cells_of(i):
		var r := Rect2(_board_origin(ui) + Vector2(c + at) * CELL, Vector2(CELL, CELL)).grow(-2)
		ui.rect(r, Color(UIKit.GOOD, 0.25))
		ui.frame(r, Color(UIKit.GOOD, 0.8), 2.0)


## "R o clic derecho = GIRAR" en grande bajo las piezas; late hasta que se gira una pieza.
func _draw_rotate_hint(ui: UIKit, p: Rect2) -> void:
	var text: String = game.data.message("figures_rotate")
	var w := ui.measure("R", 24, "bold") + 18 + ui.measure(text, 24, "bold") + 40
	var r := Rect2(p.position.x + 860 - w / 2.0, p.end.y - 98, w, 44)    # bajo la bandeja
	var pulse := 1.0 if _rotated else 0.6 + 0.4 * sin(ui.time * 6.0)
	ui.rect(r, Color(0.08, 0.06, 0.02, 0.92))
	ui.frame(r, Color(UIKit.GOLD, pulse), 2.0 if _rotated else 3.0)
	var kw := ui.measure("R", 24, "bold") + 18
	ui.rect(Rect2(r.position + Vector2(10, 8), Vector2(kw, 28)), UIKit.GOLD)
	ui.text("R", r.position + Vector2(19, 9), 24, Color("0b0f14"), "bold", false)
	ui.text(text, r.position + Vector2(kw + 22, 9), 24, UIKit.GOLD, "bold")
