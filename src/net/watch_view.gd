## Vista del espectador: carga la sala de quien se mira (con sus ejercicios) y mueve su fantasma.
## La usan el panel del admin y los jugadores que ya terminaron.
class_name WatchView
extends RefCounted

var game
var ghost: SpectatorGhost

var _loaded := ""    # "sala:semilla" cargada


func _init(context) -> void:
	game = context


## Elige a quién mirar ("" para nadie).
func look_at(id: String) -> void:
	if id != game.online.watching:
		game.online.watch(id)


func target() -> Dictionary:
	return game.online.player(game.online.watching)


func has_signal_from_target() -> bool:
	return game.online.snaps.has(game.online.watching)


func update(_delta: float) -> void:
	var s: Dictionary = game.online.snaps.get(game.online.watching, {})
	if s.is_empty():
		return
	var key := "%d:%d" % [int(s.get("c", -1)), int(s.get("sd", 0))]
	if key != _loaded or not is_instance_valid(ghost):
		_loaded = key
		game.load_watch_level(int(s.get("c", -1)), int(s.get("sd", 0)))
		ghost = SpectatorGhost.new()
		ghost.build(game.player)
		game.level.actors.add_child(ghost)
		ghost.apply(s, game.level.dark)
		game.rig.follow(ghost)
	var room := game.level as ChamberLevel
	if room and bool(s.get("ok", false)) and not room.solved:
		room.resume_from_save({"solved": true})
	ghost.apply(s, game.level.dark)


## Deja de mirar y vuelve el pueblo de fondo.
func stop() -> void:
	look_at("")
	if _loaded != "":
		game.show_town()
	_loaded = ""
	ghost = null


## Dónde está el fantasma en la pantalla (para escribir su nombre).
func ghost_on_screen() -> Vector2:
	if not is_instance_valid(ghost) or not ghost.is_inside_tree():
		return Vector2(-1, -1)
	return ghost.get_global_transform_with_canvas().origin


## Panel con quien se mira y la lista para cambiar.
func draw(ui: UIKit, keys_key: String) -> void:
	var s := ui.size()
	var data: DataRepository = game.data
	var p := target()
	var at := ghost_on_screen()
	if at.x >= 0 and not p.is_empty():
		var name := String(p.get("name", ""))
		var w := ui.measure(name, 18, "bold") + 20
		ui.rect(Rect2(at.x - w / 2.0, at.y - 76, w, 28), Color(0.03, 0.04, 0.06, 0.85))
		ui.text(name, Vector2(at.x - w / 2.0 + 10, at.y - 72), 18, UIKit.GOLD, "bold", false)
	var top := Rect2(24, 20, 520, 104)
	ui.panel(top)
	ui.text(data.message("watch_title"), top.position + Vector2(20, 14), 14, UIKit.ALERT, "bold")
	if p.is_empty():
		ui.text(data.message("watch_none"), top.position + Vector2(20, 42), 22)
	else:
		ui.text(String(p.get("name", "")), top.position + Vector2(20, 34), 32, UIKit.GOLD, "title")
		var line := "%s  ·  %s  ·  %s" % [
			data.message("net_status_" + String(p.get("status", ""))),
			NetBoard.room_name(data, int(p.get("chamber", -1))),
			CountdownTimer.format(float(p.get("time_left", 0))),
		]
		ui.text(line, top.position + Vector2(20, 72), 18, UIKit.CYAN)
		if not has_signal_from_target():
			ui.text(data.message("watch_waiting", {"name": p.get("name", "")}), Vector2(24, top.end.y + 12), 18, UIKit.MUTED)
	var list := Rect2(s.x - 470, 20, 446, minf(s.y - 90, 60 + game.online.players.size() * NetBoard.ROW_H + 40))
	ui.panel(list, Color(0.035, 0.045, 0.065, 0.78))
	ui.text(data.message("watch_ranking"), list.position + Vector2(18, 14), 14, UIKit.MUTED, "bold")
	NetBoard.draw(ui, Rect2(list.position + Vector2(10, 40), list.size - Vector2(20, 50)), game.online.players, data, game.online.watching, true)
	ui.text(data.message(keys_key, game.key_names()), Vector2(24, s.y - 40), 16, UIKit.MUTED)


## El siguiente (o anterior) que se pueda mirar.
func cycle(step: int, skip_id := "") -> void:
	var options: Array = game.online.players.filter(func(p): return String(p.get("status", "")) != "lobby" and String(p.get("id", "")) != skip_id)
	if options.is_empty():
		return
	var index := -1
	for i in options.size():
		if String(options[i].id) == game.online.watching:
			index = i
	index = posmod(index + step, options.size()) if index >= 0 else 0
	look_at(String(options[index].id))
