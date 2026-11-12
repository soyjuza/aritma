## Patrón State: la clasificación final de la partida en línea.
## El orden lo arma el servidor (ranking() en server/server.js):
## 1. ganar (y entre ganadores, menos tiempo), 2. la sala a la que llegó,
## 3. menos golpes recibidos, 4. menos errores, 5. más guardianes vencidos,
## 6. más tiempo en el reloj.
class_name RankingState
extends GameState

const ROW_H := 46.0
# Oro, plata y bronce para los 3 primeros
const PODIUM := [UIKit.GOLD, Color("c9d2e0"), Color("d08a4a")]

var _first := 0    # primera fila que se ve (con muchos jugadores la lista se desplaza)


func enter(_params: Dictionary = {}) -> void:
	_first = 0
	game.player.controls_enabled = false
	game.show_town()
	game.play_music("title")
	game.bus.publish(GameEvents.MENU_CONFIRM)


func handle_input(actions: Array) -> void:
	if "ui_up" in actions or "ui_down" in actions:
		_first = maxi(0, _first + (1 if "ui_down" in actions else -1))
		game.bus.publish(GameEvents.MENU_MOVE)
	elif "cancel" in actions or ("accept" in actions and game.online.is_admin()):
		game.bus.publish(GameEvents.MENU_CONFIRM)
		if game.online.is_admin():
			game.machine.change("admin")
		else:
			game.online.leave()
			game.machine.change("title")


func draw(ui: UIKit) -> void:
	var s := ui.size()
	ui.vignette(0.85)
	ui.dim(0.55)
	ui.text_centered(game.data.message("rank_title"), 34, 52, UIKit.GOLD, "title")
	var w := minf(1100.0, s.x - 100.0)
	var x := (s.x - w) / 2.0
	var y := 104.0
	var help := ui.wrap(game.data.message("rank_order_help"), w, 17)
	for i in mini(help.size(), 2):
		ui.text_centered(help[i], y, 17, UIKit.MUTED)
		y += 22
	var r := Rect2(x, y + 10, w, s.y - y - 76)
	ui.panel(r)
	_draw_rows(ui, Rect2(r.position + Vector2(20, 16), r.size - Vector2(40, 32)))
	var keys := "rank_keys_admin" if game.online.is_admin() else "rank_keys_player"
	ui.text(game.data.message(keys, game.key_names()), Vector2(x, s.y - 42), 16, UIKit.MUTED)


func _draw_rows(ui: UIKit, r: Rect2) -> void:
	var players: Array = game.online.players
	var cols := _columns(r)
	var y := r.position.y
	ui.text("#", Vector2(cols[0], y), 15, UIKit.MUTED, "bold")
	ui.text(game.data.message("net_col_name"), Vector2(cols[1], y), 15, UIKit.MUTED, "bold")
	ui.text(game.data.message("rank_col_reached"), Vector2(cols[2], y), 15, UIKit.MUTED, "bold")
	ui.text(game.data.message("rank_col_hits"), Vector2(cols[3], y), 15, UIKit.MUTED, "bold")
	ui.text(game.data.message("rank_col_errors"), Vector2(cols[4], y), 15, UIKit.MUTED, "bold")
	ui.text(game.data.message("rank_col_kills"), Vector2(cols[5], y), 15, UIKit.MUTED, "bold")
	y += 30
	if players.is_empty():
		ui.text(game.data.message("net_no_players"), Vector2(cols[1], y + 6), 20, UIKit.MUTED)
		return
	var fits := maxi(1, int((r.end.y - y) / ROW_H))
	_first = clampi(_first, 0, maxi(0, players.size() - fits))
	for i in range(_first, mini(players.size(), _first + fits)):
		_draw_row(ui, r, cols, y, i, players[i])
		y += ROW_H


func _draw_row(ui: UIKit, r: Rect2, cols: Array, y: float, i: int, p: Dictionary) -> void:
	var mine: bool = String(p.get("id", "")) == game.online.my_id and game.online.my_id != ""
	var medal: Color = PODIUM[i] if i < PODIUM.size() else UIKit.MUTED
	if i < PODIUM.size():
		ui.rect(Rect2(r.position.x - 8, y - 4, r.size.x + 16, ROW_H - 6), Color(medal, 0.1))
	elif mine:
		ui.rect(Rect2(r.position.x - 8, y - 4, r.size.x + 16, ROW_H - 6), Color(1, 1, 1, 0.04))
	if mine:
		ui.rect(Rect2(r.position.x - 8, y - 4, 4, ROW_H - 6), UIKit.CYAN)
	var ty := y + 6
	if i < PODIUM.size():
		ui.diamond(Vector2(cols[0] + 8, ty + 11), 7, medal)
		ui.text(str(i + 1), Vector2(cols[0] + 22, ty), 22, medal, "title")
	else:
		ui.text(str(i + 1), Vector2(cols[0] + 22, ty), 20, UIKit.MUTED, "title")
	var name := String(p.get("name", ""))
	if not bool(p.get("online", true)):
		name += " " + game.data.message("net_offline_mark")
	ui.text(name, Vector2(cols[1], ty), 20, medal if i < PODIUM.size() else UIKit.TEXT, "bold")
	var outs := int(p.get("outs", 0))
	if outs > 0:
		ui.text(game.data.message("net_out_mark", {"n": outs}), Vector2(cols[1] + ui.measure(name, 20, "bold") + 12, ty + 2), 15, UIKit.ALERT, "bold")
	ui.text(_reached_text(p), Vector2(cols[2], ty), 18, _reached_color(p))
	ui.text(str(int(p.get("hits", 0))), Vector2(cols[3], ty), 18)
	ui.text(str(int(p.get("errors", 0))), Vector2(cols[4], ty), 18)
	ui.text(str(int(p.get("kills", 0))), Vector2(cols[5], ty), 18, UIKit.GOOD)


## Hasta dónde llegó: GANÓ (con su tiempo), la sala o el pueblo.
func _reached_text(p: Dictionary) -> String:
	if String(p.get("status", "")) == "won":
		return game.data.message("rank_won_time", {"time": CountdownTimer.format(float(p.get("used", 0)))})
	return NetBoard.room_name(game.data, int(p.get("chamber", -1)))


func _reached_color(p: Dictionary) -> Color:
	match String(p.get("status", "")):
		"won":
			return UIKit.GOOD
		"left", "lobby":
			return UIKit.MUTED
	return UIKit.TEXT


func _columns(r: Rect2) -> Array:
	var x := r.position.x
	var w := r.size.x
	return [x + 4, x + 70, x + w * 0.42, x + w * 0.64, x + w * 0.76, x + w * 0.89]
