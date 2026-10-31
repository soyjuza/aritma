## Patrón State: pausa. Se detiene el reloj y el mundo.
class_name PauseState
extends GameState

var _menu: MenuList
var _help: Array


func _init(context) -> void:
	super(context)
	# En línea no se guarda
	_menu = MenuList.new(game.data.texts.get("pause_options", []), func(i): return i != 3 or not game.in_online_match)
	_help = game.data.texts.get("pause_help", [])


func enter(params: Dictionary = {}) -> void:
	if params.get("reset_cursor", true):
		_menu.index = 0


## En línea el reloj sigue: si no, pausar sería hacer trampa.
func timer_runs() -> bool:
	return game.in_online_match


func freezes_world() -> bool:
	return true


func handle_input(actions: Array) -> void:
	if _menu.move(actions):
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "pause" in actions or "cancel" in actions:
		game.machine.change("play")
	elif "accept" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		match _menu.index:
			0:
				game.machine.change("play")
			1:
				game.machine.change("book", {"return_to": "pause"})
			2:
				game.machine.change("settings", {"return_to": "pause"})
			3:
				game.save_game()
				game.machine.change("play")
				game.dialog.say([game.data.message("saved")])
			4:
				if game.in_online_match:
					game.leave_online_match()
				game.machine.change("title")


func update(delta: float) -> void:
	game.dialog.update(delta, game.text_speed())


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.025, 0.04, 0.62))
	# Menú
	ui.rect(Rect2(0, 0, 470, s.y), Color(0.04, 0.05, 0.07, 0.9))
	ui.text(game.data.message("pause_kicker"), Vector2(72, 64), 14, UIKit.CYAN, "bold")
	ui.text(game.data.message("pause_title"), Vector2(70, 86), 54, UIKit.GOLD, "title")
	_menu.draw(ui, Vector2(56, 180), 360)
	var help := String(_help[_menu.index]) if _menu.index < _help.size() else ""
	for i in ui.wrap(help, 330, 17).size():
		ui.text(ui.wrap(help, 330, 17)[i], Vector2(72, 180 + _menu.height() + 24 + i * 24), 17, UIKit.MUTED)
	ui.text(game.data.message("pause_keys", game.key_names()), Vector2(72, s.y - 52), 15, UIKit.MUTED)
	# Núcleo, progreso y objetivo
	var x := s.x - 620
	var energy := Rect2(x, 64, 560, 150)
	ui.panel(energy)
	var center := energy.position + Vector2(80, 75)
	var frac: float = game.timer.remaining / maxf(1.0, game.timer.limit)
	ui.arc(center, 48, 0, TAU, Color("1f2730"), 10)
	ui.arc(center, 48, -PI / 2, -PI / 2 + TAU * frac, UIKit.CYAN, 10)
	ui.diamond(center, 18, UIKit.CYAN if game.timer.active else UIKit.MUTED)
	ui.text(game.data.message("pause_energy"), energy.position + Vector2(160, 24), 14, UIKit.MUTED, "bold")
	ui.text(CountdownTimer.format(game.timer.remaining), energy.position + Vector2(158, 44), 54, UIKit.TEXT, "title")
	var note: String = game.data.message(("pause_time_online" if game.in_online_match else "pause_time_note") if game.timer.active else "pause_dormant")
	ui.text(note, energy.position + Vector2(160, 112), 16, Color("ff9a6b") if game.timer.active else UIKit.MUTED)
	var progress := Rect2(x, 234, 560, 190)
	ui.panel(progress)
	var total: int = maxi(1, game.data.chamber_count())
	var current: int = game.chamber_index + 1
	ui.text(game.data.message("pause_progress", {"n": maxi(0, current), "total": total}), progress.position + Vector2(26, 22), 14, UIKit.MUTED, "bold")
	var seg := (progress.size.x - 52 - (total - 1) * 8) / total
	for i in total:
		var color := UIKit.GOOD if i < game.chamber_index else (UIKit.CYAN if i == game.chamber_index else Color("26303c"))
		ui.rect(Rect2(progress.position.x + 26 + i * (seg + 8), progress.position.y + 52, seg, 8), color)
	ui.text(game.place_title(), progress.position + Vector2(26, 78), 26, UIKit.GOLD, "title")
	var objective: String = game.data.message(game.level.objective_key) if game.level.objective_key != "" else ""
	var lines := ui.wrap(objective, 500, 18)
	for i in lines.size():
		ui.text(lines[i], progress.position + Vector2(26, 124 + i * 26), 18)
	game.dialog.draw(ui)
