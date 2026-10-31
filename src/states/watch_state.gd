## Patrón State: el jugador ya terminó (ganó o perdió) y mira a los demás en vivo.
class_name WatchState
extends GameState

var view: WatchView


func _init(context) -> void:
	super(context)
	view = WatchView.new(context)


func enter(_params: Dictionary = {}) -> void:
	game.player.controls_enabled = false
	game.show_town()
	if _can_watch():
		view.cycle(1, game.online.my_id)


func exit() -> void:
	view.stop()


func freezes_world() -> bool:
	return true


func _can_watch() -> bool:
	return bool(game.online.config.get("spectate", true))


func handle_input(actions: Array) -> void:
	if "cancel" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.online.leave()
		game.machine.change("title")
	elif _can_watch() and ("ui_up" in actions or "ui_down" in actions):
		game.bus.publish(GameEvents.MENU_MOVE)
		view.cycle(-1 if "ui_up" in actions else 1, game.online.my_id)


func update(delta: float) -> void:
	if not _can_watch():
		return
	# Si quien miraba ya no está, se busca a otro
	if game.online.watching == "" or view.target().is_empty():
		view.cycle(1, game.online.my_id)
	view.update(delta)


func draw(ui: UIKit) -> void:
	if _can_watch():
		ui.vignette(0.4)
		view.draw(ui, "watch_keys_player")
		_draw_footer(ui)
		return
	var s := ui.size()
	ui.dim(0.6)
	var w := minf(900.0, s.x - 80.0)
	var r := Rect2((s.x - w) / 2.0, 60, w, s.y - 150)
	ui.panel(r)
	ui.text(game.data.message("watch_ranking"), r.position + Vector2(24, 18), 30, UIKit.GOLD, "title")
	ui.text(game.data.message("watch_no_spectate"), r.position + Vector2(24, 60), 18, UIKit.MUTED)
	NetBoard.draw(ui, Rect2(r.position + Vector2(16, 100), r.size - Vector2(32, 110)), game.online.players, game.data, game.online.my_id)
	ui.text(game.data.message("watch_keys_player", game.key_names()), Vector2(24, s.y - 40), 16, UIKit.MUTED)


func _draw_footer(ui: UIKit) -> void:
	if game.online.phase == "ended":
		var s := ui.size()
		ui.text_centered(game.data.message("watch_match_over"), s.y - 80, 22, UIKit.GOLD, "bold")
