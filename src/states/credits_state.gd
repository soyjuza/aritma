## PATRÓN STATE — Créditos.
class_name CreditsState
extends GameState


func handle_input(actions: Array) -> void:
	if "accept" in actions or "cancel" in actions:
		game.bus.publish(GameEvents.MENU_MOVE)
		game.machine.change("menu")


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.025, 0.04, 0.7))
	var w := minf(860.0, s.x - 80.0)
	var lines: Array = game.data.texts.get("credits", [])
	var r := Rect2((s.x - w) / 2.0, 50, w, 120 + lines.size() * 34)
	ui.panel(r)
	ui.text_centered(String(game.data.setting("title", "")), r.position.y + 26, 40, UIKit.GOLD, "title")
	for i in lines.size():
		ui.text_centered(String(lines[i]).format({"author": game.data.setting("author", "")}), r.position.y + 96 + i * 34, 22)
