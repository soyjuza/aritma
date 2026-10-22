## Patrón State: pausa. Se detiene el reloj y el mundo.
class_name PauseState
extends GameState

var _menu: MenuList
var _help: Array


func _init(context) -> void:
	super(context)
	_menu = MenuList.new(game.data.texts.get("pause_options", []))
	_help = game.data.texts.get("pause_help", [])


func enter(params: Dictionary = {}) -> void:
	if params.get("reset_cursor", true):
		_menu.index = 0
	# En una práctica se puede saltar
	var options: Array = game.data.texts.get("pause_options", []).duplicate()
	if game.skills.free_points() > 0:
		options[1] = game.data.message("pause_skills_points", {"n": game.skills.free_points()})
	if game.level is PracticeLevel:
		options.append(game.data.message("pause_skip_practice"))
	_menu.options = options


func freezes_world() -> bool:
	return true


func handle_mouse(event: InputEventMouse) -> bool:
	if _menu.clicked(event, (game.overlay as Control).make_input_local(event).position):
		handle_input(["accept"])
		return true
	return false


func handle_input(actions: Array) -> void:
	if _menu.move(actions):
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "pause" in actions or "cancel" in actions:
		game.machine.change("play")
	elif "accept" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		match _menu.index:
			0:
				game.machine.change("play")
			1:
				game.machine.change("skills")
			2:
				game.machine.change("book", {"return_to": "pause"})
			3:
				game.machine.change("settings", {"return_to": "pause"})
			4:
				game.save_game()
				game.machine.change("play")
				game.dialog.say([game.data.message("saved")])
			5:
				game.machine.change("title")
			6:
				game.machine.change("play")
				game.skip_practice()


func update(delta: float) -> void:
	game.dialog.update(delta, game.text_speed())


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.025, 0.04, 0.62))
	# Menú
	ui.rect(Rect2(0, 0, 470, s.y), Color(0.04, 0.05, 0.07, 0.9))
	ui.text(game.data.message("pause_kicker"), Vector2(72, 64), 14, UIKit.CYAN, "bold")
	ui.text(game.data.message("pause_title"), Vector2(70, 86), 54, UIKit.GOLD, "title")
	_menu.draw(ui, Vector2(56, 180), 360)
	var help: String = String(_help[_menu.index]) if _menu.index < _help.size() else game.data.message("pause_skip_help")
	for i in ui.wrap(help, 330, 17).size():
		ui.text(ui.wrap(help, 330, 17)[i], Vector2(72, 180 + _menu.height() + 24 + i * 24), 17, UIKit.MUTED)
	ui.text(game.data.message("pause_keys", game.key_names()), Vector2(72, s.y - 52), 15, UIKit.MUTED)
	# Núcleo, progreso y objetivo
	var x := s.x - 620
	var progress := Rect2(x, 64, 560, 190)
	ui.panel(progress)
	var total: int = maxi(1, game.data.chamber_count())
	var current: int = game.chamber_index + 1
	ui.text(game.data.message("pause_progress", {"n": maxi(0, current), "total": total}), progress.position + Vector2(26, 22), 14, UIKit.MUTED, "bold")
	var seg := (progress.size.x - 52 - (total - 1) * 8) / total
	for i in total:
		var color := UIKit.GOOD if i < game.chamber_index else (UIKit.CYAN if i == game.chamber_index else Color("26303c"))
		ui.rect(Rect2(progress.position.x + 26 + i * (seg + 8), progress.position.y + 52, seg, 8), color)
	ui.text(game.place_title(), progress.position + Vector2(26, 78), 26, UIKit.GOLD, "title")
	var objective: String = game.data.message(game.level.objective_key) if game.level.objective_key != "" else ""
	var lines := ui.wrap(objective, 500, 18)
	for i in lines.size():
		ui.text(lines[i], progress.position + Vector2(26, 124 + i * 26), 18)
	_draw_quests(ui, Rect2(x, 274, 560, 0))
	game.dialog.draw(ui)


## Misiones: la principal y las secundarias aceptadas.
func _draw_quests(ui: UIKit, r: Rect2) -> void:
	var quests: QuestLog = game.quests
	var chapter: Dictionary = game.data.chapter_data(maxi(game.data.chapter, 0))
	var main_title: String = game.data.message("pause_quest_main", {"chapter": chapter.get("name", "")})
	var rows: Array = [[main_title, String(chapter.get("goal", quests.main.get("goal", ""))), "main"]]
	for q in quests.list:
		var state: String = quests.state(q.id)
		if state == "":
			continue
		var goal := String(q.goal)
		if q.kind == "collect" and state != "done":
			goal += " (%d de %d)" % [quests.found_count(q.id), int(q.count)]
		rows.append([String(q.title), goal, state])
	r.size.y = 60 + rows.size() * 52 + (30 if rows.size() == 1 else 0)
	ui.panel(r)
	ui.text(game.data.message("pause_quests"), r.position + Vector2(26, 20), 14, UIKit.MUTED, "bold")
	for i in rows.size():
		var y := r.position.y + 52 + i * 52
		var box := Rect2(r.position.x + 26, y + 5, 14, 14)
		if rows[i][2] == "done":
			ui.rect(box, UIKit.GOOD)
		else:
			ui.frame(box, UIKit.GOLD, 2.0)
		ui.text(rows[i][0], Vector2(r.position.x + 52, y), 18, UIKit.GOLD if rows[i][2] == "main" else UIKit.TEXT, "bold")
		ui.text(rows[i][1], Vector2(r.position.x + 52, y + 24), 15, UIKit.MUTED)
	if rows.size() == 1:
		ui.text(game.data.message("pause_quests_empty"), r.position + Vector2(26, 108), 15, UIKit.MUTED)
