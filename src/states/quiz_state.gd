## Patrón State: problema del jefe. Se responde con 1 a 4 o clic.
class_name QuizState
extends GameState

const RESULT_TIME := 1.4
const KEYS := [KEY_1, KEY_2, KEY_3, KEY_4]
const KEYPAD := [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4]
const CODE_LINE := 38.0

var quiz: Dictionary = {}
var seconds := 15.0
var on_done: Callable

var _left := 0.0
var _chosen := -1    # -1: ninguna
var _finished := false
var _result_t := 0.0
var _mouse := Vector2.ZERO


func enter(params: Dictionary = {}) -> void:
	quiz = params.get("quiz", {})
	seconds = float(params.get("seconds", 15.0))
	on_done = params.get("on_done", Callable())
	_left = seconds
	_chosen = -1
	_finished = false
	_result_t = 0.0
	game.player.controls_enabled = false


func freezes_world() -> bool:
	return true


func handle_key(event: InputEventKey) -> bool:
	var code := event.keycode
	var i: int = KEYS.find(code) if code in KEYS else KEYPAD.find(code)
	if i >= 0 and i < quiz.get("options", []).size():
		choose(i)
		return true
	return false


func handle_mouse(event: InputEventMouse) -> bool:
	_mouse = game.overlay.make_input_local(event).position
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		for i in quiz.get("options", []).size():
			if _option_rect(game.ui, i).has_point(_mouse):
				choose(i)
	return true


## Elige una opción.
func choose(i: int) -> void:
	if _finished:
		return
	_chosen = i
	_finish()


func right() -> bool:
	return _chosen == int(quiz.get("answer", -1))


func _finish() -> void:
	_finished = true
	game.bus.publish(GameEvents.KEYS_WON if right() else GameEvents.KEYS_LOST)


func update(delta: float) -> void:
	if not _finished:
		_left -= delta
		if _left <= 0.0:
			_left = 0.0
			_finish()
		return
	_result_t += delta
	if _result_t >= RESULT_TIME:
		var ok := right()
		game.machine.change("play")
		if on_done.is_valid():
			on_done.call(ok)


# ------------------------------------------------------------------ dibujo

const CELL_H := 26.0
const CELL_SIZE := 20
const CODE_SIZE := 24


func _panel(ui: UIKit) -> Rect2:
	var s := ui.size()
	var h := 236.0 + _tables_height() + _code_height() + _options_height()
	return Rect2((s.x - 900) / 2.0, maxf(10.0, (s.y - h) / 2.0), 900, h)


## Alto de las tablas (0 si el problema no trae tablas).
func _tables_height() -> float:
	var most := 0
	for t: Dictionary in quiz.get("tables", []):
		most = maxi(most, (t.rows as Array).size())
	return 0.0 if most == 0 else (most + 2) * CELL_H + 14.0


## Alto del bloque de código (0 si el problema no trae código).
func _code_height() -> float:
	var code: Array = quiz.get("code", [])
	return 0.0 if code.is_empty() else code.size() * CODE_LINE * 0.8 + 18.0


## Opciones largas («Luna, Tom»): dos filas de dos.
func _wide() -> bool:
	return quiz.get("options", []).any(func(o): return String(o).length() > 7)


func _options_height() -> float:
	return 2 * 58.0 + 12.0 if _wide() else 84.0


func _option_rect(ui: UIKit, i: int) -> Rect2:
	var p := _panel(ui)
	var top := p.position.y + 150 + _tables_height() + _code_height()
	if _wide():
		var w := 400.0
		var left := p.get_center().x - w - 10
		return Rect2(left + (i % 2) * (w + 20), top + (i / 2) * 70.0, w, 58)
	var count: int = quiz.get("options", []).size()
	var w := 150.0
	var gap := 24.0
	var left := p.get_center().x - (count * w + (count - 1) * gap) / 2.0
	return Rect2(left + i * (w + gap), top, w, 84)


## Las tablas del problema, una al lado de otra, con sus celdas.
func _draw_tables(ui: UIKit, top: float, center_x: float) -> void:
	var tables: Array = quiz.get("tables", [])
	var widths: Array = []
	var total := 0.0
	for t: Dictionary in tables:
		var cols: Array = []
		for c in (t.columns as Array).size():
			var w := ui.measure(String(t.columns[c]), CELL_SIZE, "bold")
			for r: Array in t.rows:
				w = maxf(w, ui.measure(SqlEngine.show(r[c]), CELL_SIZE, "bold"))
			cols.append(w + 24)
		widths.append(cols)
		for w in cols:
			total += w
	total += 30.0 * (tables.size() - 1)
	var x := center_x - total / 2.0
	for i in tables.size():
		var t: Dictionary = tables[i]
		var cols: Array = widths[i]
		var w := 0.0
		for c in cols:
			w += c
		ui.text_centered(String(t.name), top, CELL_SIZE, UIKit.GOLD, "bold", x + w / 2.0)
		var y := top + CELL_H
		var grid := Rect2(x, y, w, ((t.rows as Array).size() + 1) * CELL_H)
		ui.rect(grid, Color(0.02, 0.03, 0.05, 0.95))
		ui.rect(Rect2(x, y, w, CELL_H), Color(0.08, 0.2, 0.25, 0.95))
		var cx := x
		for c in cols.size():
			ui.text(String(t.columns[c]), Vector2(cx + 12, y + 1), CELL_SIZE, UIKit.CYAN, "bold")
			for r in (t.rows as Array).size():
				ui.text(SqlEngine.show(t.rows[r][c]), Vector2(cx + 12, y + 1 + (r + 1) * CELL_H), CELL_SIZE, UIKit.TEXT, "bold")
			cx += cols[c]
			if c < cols.size() - 1:
				ui.line(Vector2(cx, y), Vector2(cx, grid.end.y), Color("3a4556"), 1.0)
		for r in (t.rows as Array).size() + 1:
			ui.line(Vector2(x, y + (r + 1) * CELL_H), Vector2(x + w, y + (r + 1) * CELL_H), Color("3a4556"), 1.0)
		ui.frame(grid, Color("3a4556"), 2.0)
		x += w + 30.0


func draw(ui: UIKit) -> void:
	ui.dim(0.5)
	# Las misiones van sin el rojo del jefe
	var calm := bool(quiz.get("calm", false))
	if not calm:
		ui.vignette(0.5, Color(0.6, 0.05, 0.05))
	var hud := Hud.new()
	hud.draw_hearts(ui, game.health, 0.0)
	var p := _panel(ui)
	ui.panel(p)
	ui.text_centered(String(quiz.get("header", game.data.message("quiz_title"))), p.position.y + 18, 30, UIKit.GOLD if calm else UIKit.ALERT, "title")
	ui.text_centered(game.data.message("quiz_subtitle", {"sala": quiz.get("title", "")}), p.position.y + 60, 19, UIKit.MUTED)
	ui.text_centered(String(quiz.get("question", "")), p.position.y + 96, 28, UIKit.TEXT, "bold")
	var y := p.position.y + 142
	if _tables_height() > 0.0:
		_draw_tables(ui, y, p.get_center().x)
		y += _tables_height()
	var code: Array = quiz.get("code", [])
	if not code.is_empty():
		var line := CODE_LINE * 0.8
		var widest := 0.0
		for c in code:
			widest = maxf(widest, ui.measure(String(c), CODE_SIZE, "bold"))
		var box_w := clampf(widest + 56, 360, 840)
		var box := Rect2(p.get_center().x - box_w / 2.0, y, box_w, code.size() * line + 10)
		ui.rect(box, Color(0.02, 0.03, 0.05, 0.95))
		ui.frame(box, Color("3a4556"), 2.0)
		for i in code.size():
			ui.text(String(code[i]), box.position + Vector2(28, 4 + i * line), CODE_SIZE, UIKit.CYAN, "bold")
	var options: Array = quiz.get("options", [])
	for i in options.size():
		var r := _option_rect(ui, i)
		var fill := Color(0.08, 0.1, 0.14, 0.95)
		var border := Color("3a4556")
		if _finished and i == int(quiz.get("answer", -1)):
			fill = Color(0.1, 0.35, 0.18, 0.95)
			border = UIKit.GOOD
		elif _finished and i == _chosen:
			fill = Color(0.4, 0.06, 0.05, 0.95)
			border = UIKit.ALERT
		elif not _finished and r.has_point(_mouse):
			border = UIKit.GOLD
		ui.rect(r, fill)
		ui.frame(r, border, 3.0)
		ui.text(str(i + 1), r.position + Vector2(10, 6), 18, UIKit.GOLD, "bold")
		var size := 34
		while size > 18 and ui.measure(String(options[i]), size, "title") > r.size.x - 40:
			size -= 2
		ui.text_centered(String(options[i]), r.position.y + (r.size.y - size) / 2.0 - 4, size, UIKit.TEXT, "title", r.get_center().x)
	# Barra de tiempo
	var bar := Rect2(p.position.x + 60, p.end.y - 62, p.size.x - 120, 12)
	var frac := clampf(_left / seconds, 0.0, 1.0)
	ui.rect(bar, Color(1, 1, 1, 0.08))
	ui.rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), UIKit.GOLD if frac > 0.33 else UIKit.ALERT)
	if _finished:
		var key := "quiz_right" if right() else ("quiz_timeout" if _chosen < 0 else "quiz_wrong")
		if calm:
			key = key.replace("quiz_", "quest_quiz_")
		ui.text_centered(game.data.message(key), p.end.y - 44, 24, UIKit.GOOD if right() else UIKit.ALERT, "bold")
	else:
		ui.text_centered(game.data.message("quiz_hint", {"s": ceili(_left), "keys": _keys_text()}), p.end.y - 44, 19, UIKit.MUTED)


## "1 y 2" o "1, 2, 3 y 4".
func _keys_text() -> String:
	var keys: Array = []
	for i in quiz.get("options", []).size():
		keys.append(str(i + 1))
	if keys.size() < 2:
		return ", ".join(keys)
	return ", ".join(keys.slice(0, -1)) + " y " + str(keys[-1])
