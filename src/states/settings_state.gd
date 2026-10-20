## Patrón State: ajustes. Las filas vienen de texts.json.
class_name SettingsState
extends GameState

const ROW_H := 48.0

var _rows: Array
var _row := 0
var _return_to := "menu"


func _init(context) -> void:
	super(context)
	_rows = game.data.texts.get("settings_rows", [])


func enter(params: Dictionary = {}) -> void:
	_return_to = params.get("return_to", _return_to)
	_row = 0


## Desde la pausa todo sigue quieto.
func timer_runs() -> bool:
	return false


func freezes_world() -> bool:
	return _return_to == "pause"


func handle_input(actions: Array) -> void:
	if "ui_up" in actions or "ui_down" in actions:
		_row = posmod(_row + (1 if "ui_down" in actions else -1), _rows.size())
		game.bus.publish(GameEvents.MENU_MOVE)
		return
	var row: Dictionary = _rows[_row]
	if "cancel" in actions or ("accept" in actions and row.type == "back"):
		game.settings.save()
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change(_return_to, {"reset_cursor": false})
		return
	var delta := -1 if "ui_left" in actions else (1 if ("ui_right" in actions or "accept" in actions) else 0)
	if delta == 0 or row.type == "back":
		return
	var settings: SettingsRepository = game.settings
	match row.type:
		"bar":
			settings.set_value(row.key, clampi(settings.get_int(row.key) + delta, 0, int(row.get("max", 10))))
		"step":
			settings.set_value(row.key, clampi(settings.get_int(row.key) + delta * int(row.step), int(row.min), int(row.max)))
		"choice":
			settings.set_value(row.key, posmod(settings.get_int(row.key) + delta, row.options.size()))
		"toggle":
			settings.set_value(row.key, not settings.get_bool(row.key))
	game.bus.publish(GameEvents.MENU_MOVE)


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.025, 0.04, 0.7))
	var w := minf(980.0, s.x - 80.0)
	var r := Rect2((s.x - w) / 2.0, 44, w, 120 + _rows.size() * ROW_H)
	ui.panel(r)
	ui.text(game.data.message("settings_title"), r.position + Vector2(36, 22), 34, UIKit.GOLD, "title")
	var settings: SettingsRepository = game.settings
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var y := r.position.y + 84 + i * ROW_H
		if i == _row:
			ui.rect(Rect2(r.position.x + 16, y - 6, w - 32, ROW_H - 6), Color(UIKit.GOLD, 0.12))
			ui.cursor(Vector2(r.position.x + 30, y + 6))
		ui.text(String(row.label), Vector2(r.position.x + 60, y), 22, UIKit.GOLD if i == _row else UIKit.TEXT, "title")
		var vx := r.position.x + w * 0.56
		match row.type:
			"bar":
				ui.bar(Vector2(vx, y + 4), settings.get_int(row.key), int(row.get("max", 10)))
			"step":
				ui.text("<   %d   >" % settings.get_int(row.key), Vector2(vx, y), 22, UIKit.TEXT, "bold")
			"choice", "toggle":
				var value_index := settings.get_int(row.key) if row.type == "choice" else int(settings.get_bool(row.key))
				var value := String(row.options[clampi(value_index, 0, row.options.size() - 1)])
				ui.text("<", Vector2(vx, y), 22, UIKit.CYAN, "bold")
				ui.text(value, Vector2(vx + 36, y), 22, UIKit.TEXT, "bold")
				ui.text(">", Vector2(vx + 300, y), 22, UIKit.CYAN, "bold")
	var help_lines := ui.wrap(String(_rows[_row].help), w - 80, 18)
	for i in help_lines.size():
		ui.text(help_lines[i], Vector2(r.position.x + 36, r.end.y - 30 + i * 24), 18, UIKit.MUTED)
	ui.text_centered(game.data.message("settings_keys", game.key_names()), s.y - 40, 15, UIKit.MUTED)
	if game.show_fps:
		ui.text_right(game.data.message("fps", {"fps": Engine.get_frames_per_second()}), s.x - 24, 20, 16, UIKit.MUTED)
