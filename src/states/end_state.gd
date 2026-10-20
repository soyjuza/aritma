## Patrón State: pantalla final.
class_name EndState
extends GameState

var _won := false
var _key := ""
var _time_used := 0.0
var _shown := 0.0


func enter(params: Dictionary = {}) -> void:
	_won = bool(params.get("won", false))
	_key = String(params.get("ending", ""))
	if _key == "":
		_key = "ending_won" if _won else "ending_lost"
	_time_used = game.timer.elapsed()
	_shown = 0.0
	game.player.controls_enabled = false
	game.bus.publish(GameEvents.MENU_CONFIRM)


func handle_input(actions: Array) -> void:
	if _shown > 1.5 and ("accept" in actions or "cancel" in actions or "interact" in actions):
		game.bus.publish(GameEvents.MENU_MOVE)
		game.machine.change("title")


func update(delta: float) -> void:
	_shown += delta


func draw(ui: UIKit) -> void:
	var s := ui.size()
	var fade := clampf(_shown / 1.2, 0.0, 1.0)
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.01, 0.015, 0.025, 0.86 * fade))
	if fade < 0.4:
		return
	var key := _key
	var lines: Array = game.data.messages(key)
	var w := minf(900.0, s.x - 80.0)
	var x := (s.x - w) / 2.0
	var y := s.y * 0.18
	ui.text_centered(game.data.message(key + "_title"), y, 46, UIKit.GOLD if _won else UIKit.ALERT, "title")
	y += 64
	if _won:
		ui.text_centered(game.data.message("ending_time", {"time": CountdownTimer.format(_time_used)}), y, 24, UIKit.CYAN)
		y += 50
	for line in lines:
		for row in ui.wrap(String(line), w, 22):
			ui.text(row, Vector2(x, y), 22)
			y += ui.line_height(22) + 2
		y += 12
	if _shown > 1.5:
		ui.text_centered(game.data.message("ending_continue"), s.y - 60, 20, UIKit.MUTED)
