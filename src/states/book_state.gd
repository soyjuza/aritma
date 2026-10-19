## PATRÓN STATE — El libro de reglas (TAB o desde la pausa): una página por cada cámara a la
## que ya se llegó, con las inscripciones tal como están en las paredes. El mundo se congela
## (los guardianes no atacan mientras se lee); el reloj sigue, salvo si se abrió desde la pausa.
class_name BookState
extends GameState

var _pages: Array = []    # [{title, lines}]
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
	_page = _pages.size() - 1
	game.bus.publish(GameEvents.MENU_CONFIRM)


func timer_runs() -> bool:
	return _return_to != "pause"


func freezes_world() -> bool:
	return true


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
	var w := minf(980.0, s.x - 60.0)
	var r := Rect2((s.x - w) / 2.0, 40, w, s.y - 80)
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
