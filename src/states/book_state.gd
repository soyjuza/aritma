## Patrón State: libro de reglas de las salas visitadas.
class_name BookState
extends GameState

var _pages: Array = []
var _page := 0
var _return_to := "play"


func enter(params: Dictionary = {}) -> void:
	_return_to = String(params.get("return_to", "play"))
	_pages = [{"title": game.data.message("book_town_title"), "lines": game.data.messages("book_town")}]
	for i in range(0, game.chamber_index + 1):
		var chamber: Dictionary = game.data.chamber_data(i)
		var lines: Array = chamber.get("intro", []).duplicate()
		lines += chamber.get("tunnel_intro", [])
		_pages.append({"title": game.data.message("chamber_banner", {"n": i + 1, "name": chamber.get("name", "")}), "lines": lines})
	_pages = _split_long_pages(_pages, game.ui)
	_page = _pages.size() - 1
	game.bus.publish(GameEvents.MENU_CONFIRM)


## Parte en dos (o más) las páginas que no caben en el panel.
func _split_long_pages(pages: Array, ui: UIKit) -> Array:
	var r := _panel_rect(ui.size())
	var room := r.end.y - 60 - (r.position.y + 124)
	var out: Array = []
	for page in pages:
		var chunk: Array = []
		var used := 0.0
		for line in page.lines:
			var h := _line_height(ui, String(line), r.size.x)
			if not chunk.is_empty() and used + h > room:
				out.append({"title": page.title, "lines": chunk})
				chunk = []
				used = 0.0
			chunk.append(line)
			used += h
		out.append({"title": page.title, "lines": chunk})
	return out


func _line_height(ui: UIKit, line: String, w: float) -> float:
	var rows := ui.wrap(line.format(game.key_names()), w - 90, 21).size()
	return rows * (ui.line_height(21) + 1) + 12


func _panel_rect(s: Vector2) -> Rect2:
	var w := minf(980.0, s.x - 60.0)
	return Rect2((s.x - w) / 2.0, 40, w, s.y - 80)


func freezes_world() -> bool:
	return true


func touch_buttons() -> Array:
	return ["ui_left", "ui_right", "cancel:close"]


func handle_input(actions: Array) -> void:
	if "book" in actions or "cancel" in actions or "pause" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change(_return_to)
	elif ("ui_left" in actions or "move_left" in actions) and _page > 0:
		_page -= 1
		game.bus.publish(GameEvents.MENU_MOVE)
	elif ("ui_right" in actions or "move_right" in actions) and _page < _pages.size() - 1:
		_page += 1
		game.bus.publish(GameEvents.MENU_MOVE)


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.dim(0.7)
	var r := _panel_rect(s)
	var w := r.size.x
	ui.panel(r)
	var page: Dictionary = _pages[_page]
	ui.text(game.data.message("book_title"), r.position + Vector2(36, 24), 16, UIKit.CYAN)
	ui.text_right("%d / %d" % [_page + 1, _pages.size()], r.end.x - 36, r.position.y + 24, 16, UIKit.MUTED)
	ui.text(String(page.title), r.position + Vector2(36, 56), 34, UIKit.GOLD, "title")
	var y := r.position.y + 124
	for line in page.lines:
		line = String(line).format(game.key_names())
		ui.diamond(Vector2(r.position.x + 38, y + ui.line_height(21) * 0.45), 4, UIKit.GOLD)
		for row in ui.wrap(line, w - 90, 21):
			ui.text(row, Vector2(r.position.x + 52, y), 21)
			y += ui.line_height(21) + 1
		y += 12
	ui.text_centered(game.data.message("book_hint", game.key_names()), r.end.y - 40, 17, UIKit.MUTED)
