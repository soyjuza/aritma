## Patrón State: gastar puntos de habilidad (desde la pausa).
class_name SkillsState
extends GameState

var _menu := MenuList.new([])


func enter(_params: Dictionary = {}) -> void:
	_menu.index = 0
	_refresh()


func freezes_world() -> bool:
	return true


func touch_buttons() -> Array:
	return ["cancel"]


func _refresh() -> void:
	var skills: SkillTree = game.skills
	var options: Array = []
	for s in skills.list:
		options.append(game.data.message("skills_row", {"name": s.name, "n": skills.level(s.id), "max": int(s.max)}))
	options.append(game.data.message("skills_back"))
	_menu.options = options


func handle_mouse(event: InputEventMouse) -> bool:
	if _menu.clicked(event, (game.overlay as Control).make_input_local(event).position):
		handle_input(["accept"])
		return true
	return false


func handle_input(actions: Array) -> void:
	var skills: SkillTree = game.skills
	if _menu.move(actions):
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "pause" in actions or "cancel" in actions:
		game.machine.change("pause", {"reset_cursor": false})
	elif "accept" in actions:
		if _menu.index >= skills.list.size():
			game.machine.change("pause", {"reset_cursor": false})
		elif skills.raise(skills.list[_menu.index].id):
			game.bus.publish(GameEvents.MENU_CONFIRM)
			game.apply_skills()
			_refresh()


func draw(ui: UIKit) -> void:
	var skills: SkillTree = game.skills
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.025, 0.04, 0.8))
	ui.text(game.data.message("skills_kicker"), Vector2(72, 64), 14, UIKit.CYAN, "bold")
	ui.text(game.data.message("skills_title"), Vector2(70, 86), 54, UIKit.GOLD, "title")
	var points: String = game.data.message("skills_points", {"n": skills.free_points()})
	ui.text(points, Vector2(72, 150), 20, UIKit.GOOD if skills.free_points() > 0 else UIKit.MUTED, "bold")
	_menu.draw(ui, Vector2(56, 200), 520)
	# Qué hace la habilidad elegida
	var r := Rect2(s.x - 620, 200, 560, 230)
	ui.panel(r)
	if _menu.index >= skills.list.size():
		ui.text(game.data.message("skills_back_help"), r.position + Vector2(26, 26), 18, UIKit.MUTED)
		return
	var skill: Dictionary = skills.list[_menu.index]
	var id := String(skill.id)
	ui.text(String(skill.name), r.position + Vector2(26, 22), 26, UIKit.GOLD, "title")
	var lines := ui.wrap(String(skill.desc), 500, 18)
	for i in lines.size():
		ui.text(lines[i], r.position + Vector2(26, 70 + i * 26), 18)
	for i in skills.max_level(id):
		var box := Rect2(r.position.x + 26 + i * 34, r.position.y + 140, 24, 24)
		if i < skills.level(id):
			ui.rect(box, UIKit.GOOD)
		else:
			ui.frame(box, UIKit.GOLD, 2.0)
	var key := "skills_full" if skills.level(id) >= skills.max_level(id) else ("skills_can" if skills.can_raise(id) else "skills_no_points")
	ui.text(game.data.message(key), r.position + Vector2(26, 186), 16, UIKit.MUTED)
