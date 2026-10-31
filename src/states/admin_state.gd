## Patrón State: panel del admin. Configura la sala, inicia la partida, la controla
## y mira en vivo a cualquier jugador. El admin no juega.
class_name AdminState
extends GameState

const ROW_H := 38.0

var view: WatchView

var _rows: Array            # filas de configuración (texts.json, "admin_rows")
var _row := 0
var _on_players := false    # TAB: el foco pasa a la lista de jugadores
var _selected := ""
var _watching := false


func _init(context) -> void:
	super(context)
	view = WatchView.new(context)
	_rows = game.data.texts.get("admin_rows", [])


func enter(_params: Dictionary = {}) -> void:
	game.show_town()
	game.play_music("title")
	_row = 0
	_on_players = false
	_watching = false


func exit() -> void:
	if _watching:
		view.stop()
	_watching = false


func freezes_world() -> bool:
	return true


## Filas del panel según la fase: configuración + acciones.
func _menu() -> Array:
	match game.online.phase:
		"running":
			return [{"type": "action", "id": "resume" if game.online.paused else "pause"}, {"type": "action", "id": "add_time"}, {"type": "action", "id": "end"}]
		"ended":
			return [{"type": "action", "id": "again"}, {"type": "action", "id": "close"}]
	return _rows + [{"type": "action", "id": "start"}, {"type": "action", "id": "close"}]


func handle_key(event: InputEventKey) -> bool:
	if _on_players and not _watching and event.keycode in [KEY_DELETE, KEY_X] and _selected != "":
		game.online.kick(_selected)
		_selected = ""
		return true
	return false


func handle_input(actions: Array) -> void:
	if _watching:
		_watch_input(actions)
		return
	if "book" in actions:
		_on_players = not _on_players and not game.online.players.is_empty()
		game.bus.publish(GameEvents.MENU_MOVE)
		return
	if _on_players:
		_players_input(actions)
		return
	var menu := _menu()
	_row = clampi(_row, 0, menu.size() - 1)
	if "ui_up" in actions or "ui_down" in actions:
		_row = posmod(_row + (1 if "ui_down" in actions else -1), menu.size())
		game.bus.publish(GameEvents.MENU_MOVE)
		return
	var row: Dictionary = menu[_row]
	if row.type == "action":
		if "accept" in actions:
			game.bus.publish(GameEvents.MENU_CONFIRM)
			_do(String(row.id))
		elif "cancel" in actions and game.online.phase != "running":
			_do("close")
		return
	var delta := -1 if "ui_left" in actions else (1 if ("ui_right" in actions or "accept" in actions) else 0)
	if delta == 0:
		return
	var config: Dictionary = game.online.config.duplicate()
	match row.type:
		"step":
			config[row.key] = clampi(int(config.get(row.key, row.min)) + delta * int(row.step), int(row.min), int(row.max))
		"toggle":
			config[row.key] = not bool(config.get(row.key, false))
	game.online.send_config(config)
	game.bus.publish(GameEvents.MENU_MOVE)


func _do(id: String) -> void:
	var online: OnlineSession = game.online
	match id:
		"start":
			online.start_match()
		"pause":
			online.set_paused(true)
		"resume":
			online.set_paused(false)
		"add_time":
			online.add_time(60)
			game.notify([game.data.message("admin_time_sent")], 2.5, true)
		"end":
			online.end_match()
		"again":
			online.reset_room()
			_row = 0
		"close":
			online.close_room()
			game.machine.change("title")


func _players_input(actions: Array) -> void:
	var players: Array = game.online.players
	if players.is_empty():
		_on_players = false
		return
	var index := 0
	for i in players.size():
		if String(players[i].id) == _selected:
			index = i
	if "ui_up" in actions or "ui_down" in actions:
		index = posmod(index + (1 if "ui_down" in actions else -1), players.size())
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "cancel" in actions:
		_on_players = false
	elif "accept" in actions and String(players[index].get("status", "lobby")) != "lobby":
		game.bus.publish(GameEvents.MENU_CONFIRM)
		_watching = true
		view.look_at(String(players[index].id))
	_selected = String(players[index].id)


func _watch_input(actions: Array) -> void:
	if "cancel" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		_selected = game.online.watching
		view.stop()
		_watching = false
	elif "ui_up" in actions or "ui_down" in actions:
		game.bus.publish(GameEvents.MENU_MOVE)
		view.cycle(-1 if "ui_up" in actions else 1)
	elif "pause" in actions and game.online.phase == "running":
		game.online.set_paused(not game.online.paused)


func update(delta: float) -> void:
	if _watching:
		view.update(delta)
	if _on_players and _selected == "" and not game.online.players.is_empty():
		_selected = String(game.online.players[0].id)


func draw(ui: UIKit) -> void:
	if _watching:
		ui.vignette(0.4)
		view.draw(ui, "admin_keys_watch")
		_draw_paused_badge(ui, Vector2(24, 136))
		_draw_notice(ui)
		return
	var s := ui.size()
	var online: OnlineSession = game.online
	ui.vignette(0.85)
	ui.dim(0.55)
	ui.text(game.data.message("admin_title"), Vector2(48, 28), 46, UIKit.GOLD, "title")
	ui.text(game.data.message("admin_phase_" + (online.phase if online.phase != "" else "lobby")), Vector2(52, 84), 20, UIKit.CYAN, "title_light")
	_draw_paused_badge(ui, Vector2(300, 84))
	# Código de la sala
	var code_box := Rect2(s.x - 400, 24, 360, 104)
	ui.panel(code_box)
	ui.text(game.data.message("admin_code"), code_box.position + Vector2(20, 12), 14, UIKit.MUTED, "bold")
	ui.text(online.code, code_box.position + Vector2(20, 30), 50, UIKit.GOLD, "title")
	ui.text(game.data.message("admin_code_hint"), code_box.position + Vector2(20, 80), 14, UIKit.MUTED)
	# Panel izquierdo: configuración o controles
	var menu := _menu()
	var left_w := minf(560.0, s.x * 0.42)
	var left := Rect2(40, 140, left_w, 30 + menu.size() * ROW_H + 72)
	ui.panel(left)
	var config := online.config
	for i in menu.size():
		var row: Dictionary = menu[i]
		var y := left.position.y + 22 + i * ROW_H
		var focused := i == _row and not _on_players
		if focused:
			ui.rect(Rect2(left.position.x + 14, y - 4, left_w - 28, ROW_H - 6), Color(UIKit.GOLD, 0.12))
			ui.cursor(Vector2(left.position.x + 26, y + 6))
		var color := UIKit.GOLD if focused else UIKit.TEXT
		if row.type == "action":
			ui.text(game.data.message("admin_" + String(row.id)), Vector2(left.position.x + 54, y), 21, UIKit.CYAN if not focused else color, "title")
			continue
		ui.text(String(row.label), Vector2(left.position.x + 54, y), 20, color, "title")
		var value := ""
		if row.type == "step":
			value = "<  %d%s  >" % [int(config.get(row.key, row.min)), String(row.get("unit", ""))]
		else:
			value = "<  %s  >" % String(row.options[int(bool(config.get(row.key, false)))])
		ui.text(value, Vector2(left.position.x + left_w * 0.62, y), 20, UIKit.TEXT, "bold")
	var help := ""
	if not _on_players and _row < menu.size():
		var row: Dictionary = menu[_row]
		help = String(row.get("help", "")) if row.type != "action" else game.data.message("admin_help_" + String(row.id))
	var help_lines := ui.wrap(help, left_w - 48, 17)
	for i in mini(help_lines.size(), 3):
		ui.text(help_lines[i], Vector2(left.position.x + 24, left.end.y - 64 + i * 21), 17, UIKit.MUTED)
	if online.phase == "running":
		for i in LobbyState.config_lines(game.data, config).size():
			ui.text(LobbyState.config_lines(game.data, config)[i], Vector2(44, left.end.y + 16 + i * 24), 16, UIKit.MUTED)
	# Panel derecho: jugadores
	var right := Rect2(left.end.x + 24, 140, s.x - left.end.x - 64, s.y - 210)
	ui.panel(right, Color(0.035, 0.045, 0.065, 0.9))
	ui.text(game.data.message("admin_players", {"n": online.players.size()}), right.position + Vector2(20, 14), 16, UIKit.GOLD if _on_players else UIKit.MUTED, "bold")
	NetBoard.draw(ui, Rect2(right.position + Vector2(12, 44), right.size - Vector2(24, 56)), online.players, game.data, _selected if _on_players else "", online.phase != "lobby")
	var keys := "admin_keys_players" if _on_players else "admin_keys_menu"
	ui.text(game.data.message(keys, game.key_names()), Vector2(44, s.y - 44), 16, UIKit.MUTED)
	_draw_notice(ui)


func _draw_paused_badge(ui: UIKit, at: Vector2) -> void:
	if game.online.paused:
		var text: String = game.data.message("admin_paused")
		ui.pill(Rect2(at, Vector2(ui.measure(text, 16, "bold") + 28, 28)), Color(UIKit.ALERT, 0.25), UIKit.ALERT)
		ui.text(text, at + Vector2(14, 4), 16, UIKit.ALERT, "bold", false)


func _draw_notice(ui: UIKit) -> void:
	var hud := Hud.new()
	hud.draw_notice(ui, game.notices.text, game.notices.left, game.notices.good)
