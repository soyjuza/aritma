## Patrón State: menú principal.
class_name MenuState
extends GameState

var _menu: MenuList
var _snapshot: Dictionary = {}


func _init(context) -> void:
	super(context)
	_menu = MenuList.new(game.data.texts.get("menu", []), func(i): return i != 0 or game.saves.exists())


func enter(_params: Dictionary = {}) -> void:
	game.play_music("title")
	game.show_title_shot()
	_snapshot = game.saves.load_snapshot()
	_menu.first_enabled()


func handle_input(actions: Array) -> void:
	if _menu.move(actions):
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "cancel" in actions:
		game.machine.change("title")
	elif "accept" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		match _menu.index:
			0:
				game.machine.change("play", {"mode": "load"})
			1:
				game.machine.change("intro")
			2:
				game.machine.change("settings", {"return_to": "menu"})
			3:
				game.machine.change("credits")
			4:
				game.get_tree().quit()


func draw(ui: UIKit) -> void:
	ui.vignette(0.85)
	ui.text(String(game.data.setting("title", "")), Vector2(70, 50), 56, UIKit.GOLD, "title")
	ui.text(game.data.message("subtitle"), Vector2(74, 120), 24, UIKit.CYAN, "title_light")
	var r := Rect2(60, 180, 460, _menu.height() + 40)
	ui.panel(r)
	_menu.draw(ui, r.position + Vector2(16, 20), r.size.x - 32)
	var info := Rect2(60, r.end.y + 20, 460, 110)
	ui.panel(info)
	if _snapshot.is_empty():
		var blurb: Array = game.data.messages("menu_blurb")
		for i in blurb.size():
			ui.text(String(blurb[i]), info.position + Vector2(24, 24 + i * 34), 22)
		return
	ui.text(game.data.message("saved_game"), info.position + Vector2(24, 16), 20, UIKit.GOLD, "title")
	ui.text(game.data.message("saved_time", {"time": CountdownTimer.format(float(_snapshot.get("time_left", 0)))}), info.position + Vector2(24, 58), 22)
