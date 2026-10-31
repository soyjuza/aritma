## Patrón State: sala de espera del jugador hasta que el admin inicie la partida.
class_name LobbyState
extends GameState


func enter(_params: Dictionary = {}) -> void:
	game.show_town()
	game.play_music("title")


func handle_input(actions: Array) -> void:
	if "cancel" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.online.leave()
		game.machine.change("online")


func draw(ui: UIKit) -> void:
	var s := ui.size()
	var online: OnlineSession = game.online
	ui.vignette(0.85)
	ui.dim(0.45)
	ui.text(game.data.message("net_lobby_title", {"code": online.code}), Vector2(70, 44), 52, UIKit.GOLD, "title")
	ui.text(game.data.message("net_lobby_you", {"name": online.my_name}), Vector2(74, 108), 22, UIKit.CYAN, "title_light")
	var w := minf(980.0, s.x - 120.0)
	var rules := Rect2(60, 156, w, 110)
	ui.panel(rules)
	for i in config_lines(game.data, online.config).size():
		ui.text(config_lines(game.data, online.config)[i], rules.position + Vector2(24, 18 + i * 28), 20)
	var list := Rect2(60, rules.end.y + 18, w, s.y - rules.end.y - 110)
	ui.panel(list)
	ui.text(game.data.message("admin_players", {"n": online.players.size()}), list.position + Vector2(24, 16), 18, UIKit.MUTED, "bold")
	NetBoard.draw(ui, Rect2(list.position + Vector2(16, 48), list.size - Vector2(32, 60)), online.players, game.data, online.my_id, false)
	var wait_key := "net_lost" if online.reconnecting else "net_lobby_wait"
	if ui.blink(1.2) or online.reconnecting:
		ui.text_centered(game.data.message(wait_key), s.y - 76, 22, UIKit.ALERT if online.reconnecting else UIKit.GOLD, "bold")
	ui.text(game.data.message("net_lobby_keys", game.key_names()), Vector2(70, s.y - 40), 16, UIKit.MUTED)


## Resumen de la configuración del admin (también lo usa el panel).
static func config_lines(data: DataRepository, config: Dictionary) -> Array:
	if config.is_empty():
		return []
	var lines := [data.message("net_config_line", {
		"time": int(config.get("time_min", 15)),
		"hearts": int(config.get("hearts", 5)),
		"fall": int(config.get("fall_penalty", 7)),
		"death": int(config.get("death_penalty", 60)),
	})]
	var flags: Array = [data.message("net_flag_same" if bool(config.get("same_exercises", false)) else "net_flag_diff")]
	if bool(config.get("skip_town", false)):
		flags.append(data.message("net_flag_skip"))
	if bool(config.get("spectate", true)):
		flags.append(data.message("net_flag_spectate"))
	lines.append("  ·  ".join(flags))
	return lines
