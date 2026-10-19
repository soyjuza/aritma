## PATRÓN STATE — Jugando. El teclado mueve a Tala (ella resuelve su propia máquina de
## estados de movimiento) y E usa lo que tiene delante.
class_name PlayState
extends GameState

var _hud := Hud.new()
var _focused: Interactable = null


func enter(params: Dictionary = {}) -> void:
	match params.get("mode", "resume"):
		"new":
			game.start_new_game()
			game.dialog.say(game.data.messages("town_arrival"))
		"load":
			game.load_game()
	game.follow_player()


func exit() -> void:
	game.player.controls_enabled = false


func timer_runs() -> bool:
	return true


func handle_input(actions: Array) -> void:
	if game.dialog.is_open():
		if "accept" in actions or "interact" in actions or "cancel" in actions:
			game.dialog.advance()
		return
	if "pause" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change("pause")
	elif "book" in actions:
		game.machine.change("book", {"return_to": "play"})
	elif ("interact" in actions or "flag" in actions) and not _focused and game.level.handle_action(actions):
		pass
	elif "interact" in actions and _focused:
		game.bus.publish(GameEvents.INTERACT)
		_focused.interact()


func update(delta: float) -> void:
	game.dialog.update(delta, game.text_speed())
	game.player.controls_enabled = not game.dialog.is_open()
	_focused = game.player.focused_interactable() if not game.dialog.is_open() else null


func draw(ui: UIKit) -> void:
	ui.vignette(0.35)
	var keys: Dictionary = game.key_names()
	var info := {
		"title": game.place_title(),
		"objective": game.data.message(game.level.objective_key) if game.level.objective_key != "" else "",
		"timer_active": game.timer.active,
		"timer": game.timer,
		"stamina": game.player.stamina / game.player.stamina_max,
		"stamina_label": game.data.message("hud_stamina"),
		"keys": game.data.message("hud_keys", keys),
		"fps": game.data.message("fps", {"fps": Engine.get_frames_per_second()}) if game.show_fps else "",
		"health": game.health,
		"hurt": game.player.invulnerable - (float(game.combat("invulnerable_sec", 1.0)) - 0.25),
		"penalty": game.penalty_text,
		"penalty_left": game.penalty_left,
	}
	var room := game.level as ChamberLevel
	if room and room.alarm and room.alarm.fighting():
		info.alarm = room.alarm.level
		info.guardians = room.alarm.alive_count()
		info.alarm_label = game.data.message("hud_alarm", {"n": room.alarm.level, "k": _guardian_summary(room.alarm.alive_by_kind())})
	if _focused:
		info.prompt = game.data.message(_focused.prompt_key)
		info.prompt_key = keys.get("interact", "E")
	else:
		var own: Dictionary = game.level.action_prompt()
		if not own.is_empty():
			info.prompt = own.text
			info.prompt_key = own.key
	info.extra = game.level.hud_line()
	_hud.draw(ui, info)
	_hud.draw_notice(ui, game.notice, game.notice_left)
	game.dialog.draw(ui)


## "2 caballeros · 1 hechicero" (los nombres vienen de texts.json).
func _guardian_summary(counts: Dictionary) -> String:
	var names: Dictionary = game.data.texts.get("guardian_names", {})
	var parts: Array = []
	for kind in ["caballero", "hechicero", "rúnico"]:
		var n := int(counts.get(kind, 0))
		if n > 0:
			var forms: Array = names.get(kind, [kind, kind])
			parts.append("%d %s" % [n, forms[0] if n == 1 else forms[1]])
	return "  ·  ".join(parts) if not parts.is_empty() else "..."
