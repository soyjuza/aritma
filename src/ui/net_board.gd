## Tablero de la partida en línea: puesto, nombre, estado, sala, corazones y tiempo.
class_name NetBoard
extends RefCounted

const ROW_H := 40.0

const STATUS_COLORS := {
	"lobby": UIKit.MUTED,
	"playing": UIKit.CYAN,
	"won": UIKit.GOOD,
	"lost": UIKit.ALERT,
	"left": UIKit.MUTED,
}


## Dibuja las filas que caben en r. selected: id resaltado.
static func draw(ui: UIKit, r: Rect2, players: Array, data: DataRepository, selected := "", show_live := true) -> void:
	var y := r.position.y
	var cols := _columns(r)
	ui.text("#", Vector2(cols[0], y), 15, UIKit.MUTED, "bold")
	ui.text(data.message("net_col_name"), Vector2(cols[1], y), 15, UIKit.MUTED, "bold")
	ui.text(data.message("net_col_status"), Vector2(cols[2], y), 15, UIKit.MUTED, "bold")
	if show_live:
		ui.text(data.message("net_col_room"), Vector2(cols[3], y), 15, UIKit.MUTED, "bold")
		ui.text(data.message("net_col_time"), Vector2(cols[4], y), 15, UIKit.MUTED, "bold")
	y += 28
	if players.is_empty():
		ui.text(data.message("net_no_players"), Vector2(cols[1], y + 6), 20, UIKit.MUTED)
		return
	var fits := int((r.end.y - y) / ROW_H)
	var first := 0
	for i in players.size():
		if String(players[i].get("id", "")) == selected:
			first = clampi(i - fits + 1, 0, maxi(0, players.size() - fits))
	for i in range(first, mini(players.size(), first + fits)):
		var p: Dictionary = players[i]
		var row := Rect2(r.position.x, y, r.size.x, ROW_H - 4)
		var is_selected := String(p.get("id", "")) == selected and selected != ""
		ui.rect(row, Color(UIKit.GOLD, 0.14) if is_selected else Color(1, 1, 1, 0.03))
		if is_selected:
			ui.rect(Rect2(row.position, Vector2(4, row.size.y)), UIKit.CYAN)
		var status := String(p.get("status", "lobby"))
		var ty := y + 6
		ui.text(str(i + 1), Vector2(cols[0], ty), 20, UIKit.GOLD, "title")
		var name := String(p.get("name", ""))
		if not bool(p.get("online", true)):
			name += " " + data.message("net_offline_mark")
		ui.text(name, Vector2(cols[1], ty), 20, UIKit.GOLD if is_selected else UIKit.TEXT, "bold")
		ui.text(data.message("net_status_" + status), Vector2(cols[2], ty), 18, STATUS_COLORS.get(status, UIKit.TEXT), "bold")
		if show_live and status != "lobby":
			ui.text(room_name(data, int(p.get("chamber", -1))), Vector2(cols[3], ty), 18)
			var time_text := CountdownTimer.format(float(p.get("used", 0))) if status == "won" else CountdownTimer.format(float(p.get("time_left", 0)))
			ui.text(time_text, Vector2(cols[4], ty), 18, UIKit.GOOD if status == "won" else UIKit.TEXT)
			var halves := int(p.get("hearts", 0))
			if status == "playing" and int(p.get("max_hearts", 0)) > 0:
				ui.diamond(Vector2(cols[5] + 6, ty + 11), 6, UIKit.ALERT)
				ui.text(_hearts_text(halves), Vector2(cols[5] + 18, ty), 18, UIKit.ALERT)
		y += ROW_H


static func room_name(data: DataRepository, chamber: int) -> String:
	if chamber < 0:
		return data.message("net_room_town")
	return data.message("net_room_n", {"n": chamber + 1, "total": data.chamber_count()})


static func _hearts_text(halves: int) -> String:
	return str(halves / 2) + (",5" if halves % 2 == 1 else "")


static func _columns(r: Rect2) -> Array:
	var x := r.position.x
	var w := r.size.x
	return [x + 12, x + 44, x + w * 0.40, x + w * 0.60, x + w * 0.76, x + w * 0.88]
