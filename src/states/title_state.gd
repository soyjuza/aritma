## Patrón State: título.
class_name TitleState
extends GameState


func enter(_params: Dictionary = {}) -> void:
	game.play_music("title")
	game.show_title_shot()


func handle_input(actions: Array) -> void:
	if "accept" in actions or "jump" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change("menu")


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.vignette(0.85)
	ui.rect(Rect2(0, s.y * 0.16, s.x, 220), Color(0, 0, 0, 0.32))
	ui.text_centered(String(game.data.setting("title", "")), s.y * 0.16 + 26, 96, UIKit.GOLD, "title")
	ui.text_centered(game.data.message("subtitle"), s.y * 0.16 + 146, 32, UIKit.CYAN, "title_light")
	if ui.blink(1.4):
		ui.text_centered(game.data.message("press_start", game.key_names()), s.y * 0.82, 26, UIKit.TEXT, "bold")
