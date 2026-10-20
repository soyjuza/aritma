## Patrón State: problema del jefe. Se responde con 1 a 4 o clic.
class_name QuizState
extends GameState

const RESULT_TIME := 1.4
const KEYS := [KEY_1, KEY_2, KEY_3, KEY_4]
const KEYPAD := [KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4]

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


func timer_runs() -> bool:
	return true


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

func _panel(ui: UIKit) -> Rect2:
	var s := ui.size()
	return Rect2((s.x - 820) / 2.0, s.y * 0.2, 820, 400)


func _option_rect(ui: UIKit, i: int) -> Rect2:
	var p := _panel(ui)
	var count: int = quiz.get("options", []).size()
	var w := 150.0
	var gap := 24.0
	var left := p.get_center().x - (count * w + (count - 1) * gap) / 2.0
	return Rect2(left + i * (w + gap), p.position.y + 196, w, 84)


func draw(ui: UIKit) -> void:
	ui.dim(0.5)
	ui.vignette(0.5, Color(0.6, 0.05, 0.05))
	var hud := Hud.new()
	hud.draw_timer(ui, game.timer)
	hud.draw_hearts(ui, game.health, 0.0)
	var p := _panel(ui)
	ui.panel(p)
	ui.text_centered(game.data.message("quiz_title"), p.position.y + 22, 30, UIKit.ALERT, "title")
	ui.text_centered(game.data.message("quiz_subtitle", {"sala": quiz.get("title", "")}), p.position.y + 70, 19, UIKit.MUTED)
	ui.text_centered(String(quiz.get("question", "")), p.position.y + 118, 32, UIKit.TEXT, "bold")
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
		ui.text_centered(String(options[i]), r.position.y + 22, 34, UIKit.TEXT, "title", r.get_center().x)
	# Barra de tiempo
	var bar := Rect2(p.position.x + 60, p.end.y - 66, p.size.x - 120, 12)
	var frac := clampf(_left / seconds, 0.0, 1.0)
	ui.rect(bar, Color(1, 1, 1, 0.08))
	ui.rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), UIKit.GOLD if frac > 0.33 else UIKit.ALERT)
	if _finished:
		var key := "quiz_right" if right() else ("quiz_timeout" if _chosen < 0 else "quiz_wrong")
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
