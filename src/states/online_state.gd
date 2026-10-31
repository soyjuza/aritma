## Patrón State: menú EN LÍNEA. Nombre, código de sala y servidor; unirse o crear sala.
class_name OnlineState
extends GameState

enum Row { NAME, CODE, JOIN, CREATE, SERVER, BACK }

const ROW_H := 56.0

var _row := Row.NAME
var _name := TextField.new("", 16)
var _code := TextField.new("", 5, true)
var _server := TextField.new("", 120)
var _error := ""


func _init(context) -> void:
	super(context)
	game.online.failed.connect(func(key): _error = game.data.message(key))


func enter(_params: Dictionary = {}) -> void:
	game.show_title_shot()
	_name.text = game.online.my_name
	_server.text = game.online.url
	_error = ""
	_row = Row.NAME if _name.text == "" else Row.CODE


func _field() -> TextField:
	match _row:
		Row.NAME:
			return _name
		Row.CODE:
			return _code
		Row.SERVER:
			return _server
	return null


func handle_key(event: InputEventKey) -> bool:
	var field := _field()
	if field == null or game.online.connecting():
		return false
	return field.feed(event)


func handle_input(actions: Array) -> void:
	if game.online.connecting():
		if "cancel" in actions:
			game.online.leave()
		return
	if "ui_up" in actions or "ui_down" in actions or "book" in actions:
		_row = posmod(_row + (-1 if "ui_up" in actions else 1), Row.size()) as Row
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "cancel" in actions:
		game.machine.change("menu")
	elif "accept" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		_error = ""
		match _row:
			Row.NAME, Row.CODE, Row.SERVER:
				_row = (_row + 1) as Row
			Row.JOIN:
				if _name.text.strip_edges() == "":
					_error = game.data.message("net_need_name")
					_row = Row.NAME
				elif _code.text.length() < 5:
					_error = game.data.message("net_need_code")
					_row = Row.CODE
				else:
					_remember()
					game.online.join_room(_server.text, _code.text, _name.text.strip_edges())
			Row.CREATE:
				_remember()
				game.online.create_room(_server.text)
			Row.BACK:
				game.machine.change("menu")


func _remember() -> void:
	game.online.my_name = _name.text.strip_edges()
	game.online.url = _server.text.strip_edges()
	game.online.save_prefs()


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.vignette(0.85)
	ui.dim(0.45)
	ui.text(game.data.message("net_title"), Vector2(70, 44), 56, UIKit.GOLD, "title")
	ui.text(game.data.message("net_subtitle"), Vector2(74, 112), 22, UIKit.CYAN, "title_light")
	var w := minf(760.0, s.x - 120.0)
	var r := Rect2(60, 160, w, Row.size() * ROW_H + 40)
	ui.panel(r)
	var labels := ["net_name", "net_code", "net_join", "net_create", "net_server", "net_back"]
	var hints := {Row.NAME: "net_name_hint", Row.CODE: "net_code_hint", Row.SERVER: "net_server_hint"}
	for i in Row.size():
		var y := r.position.y + 20 + i * ROW_H
		var focused := i == _row
		if focused:
			ui.rect(Rect2(r.position.x + 16, y, w - 32, ROW_H - 8), Color(UIKit.GOLD, 0.12))
			ui.rect(Rect2(r.position.x + 16, y, 4, ROW_H - 8), UIKit.CYAN)
			ui.cursor(Vector2(r.position.x + 30, y + 14))
		var label: String = game.data.message(labels[i])
		var color := UIKit.GOLD if focused else UIKit.TEXT
		if hints.has(i):
			ui.text(label, Vector2(r.position.x + 56, y + 12), 20, color, "title")
			var field: TextField = [_name, _code, null, null, _server][i]
			field.draw(ui, Rect2(r.position.x + 260, y + 4, w - 290, ROW_H - 16), focused, game.data.message(hints[i]))
		else:
			ui.text(label, Vector2(r.position.x + 56, y + 10), 26, color, "title")
	var info := Rect2(60, r.end.y + 14, w, 92)
	ui.panel(info)
	var note := _error
	var note_color := UIKit.ALERT
	if game.online.connecting():
		note = game.data.message("net_connecting")
		note_color = UIKit.CYAN
	elif note == "":
		note = game.data.message("net_help_" + ["name", "code", "join", "create", "server", "back"][_row])
		note_color = UIKit.MUTED
	var lines := ui.wrap(note, w - 48, 20)
	for i in mini(lines.size(), 3):
		ui.text(lines[i], info.position + Vector2(24, 16 + i * 26), 20, note_color)
	ui.text(game.data.message("net_keys", game.key_names()), Vector2(70, s.y - 44), 16, UIKit.MUTED)
