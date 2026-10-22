## Patrón State: la historia antes de jugar.
class_name IntroState
extends GameState

const FADE_TIME := 0.6

var _page := 0
var _t := 0.0


func enter(_params: Dictionary = {}) -> void:
	_page = 0
	_t = 0.0


func touch_tap() -> String:
	return "accept"


func touch_buttons() -> Array:
	return ["cancel:skip"]


func handle_input(actions: Array) -> void:
	if "cancel" in actions:
		_begin()
	elif "accept" in actions or "jump" in actions:
		game.bus.publish(GameEvents.MENU_MOVE)
		_page += 1
		_t = 0.0
		if _page >= _pages().size():
			_begin()


func update(delta: float) -> void:
	_t += delta


func _pages() -> Array:
	return game.data.texts.get("lore_intro", [])


func _begin() -> void:
	game.bus.publish(GameEvents.MENU_CONFIRM)
	game.data.use_chapter(0)
	game.machine.change("play", {"mode": "new"})


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.0, 0.0, 0.02, 0.84))
	ui.vignette(0.9)
	var pages := _pages()
	if _page >= pages.size():
		return
	var page: Dictionary = pages[_page]
	var alpha := minf(1.0, _t / FADE_TIME)
	ui.text_centered(String(page.title), s.y * 0.24, 42, Color(UIKit.GOLD, alpha), "title")
	var lines := ui.wrap(String(page.text), minf(920.0, s.x - 120.0), 28)
	for i in lines.size():
		ui.text_centered(lines[i], s.y * 0.24 + 92 + i * 44, 28, Color(UIKit.TEXT, alpha))
	ui.text_centered("%d / %d" % [_page + 1, pages.size()], s.y - 110, 18, UIKit.MUTED)
	ui.text_centered(game.data.message("intro_keys", game.key_names()), s.y - 76, 20, UIKit.MUTED)
