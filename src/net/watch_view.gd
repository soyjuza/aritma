## Vista del espectador: carga la sala de quien se mira (con sus ejercicios) y mueve su fantasma.
## La usan el panel del admin y los jugadores que ya terminaron.
class_name WatchView
extends RefCounted

var game
var ghost: SpectatorGhost

var _loaded := ""    # "sala:semilla" cargada
var _replaying := false    # una máquina está repitiendo el programa del jugador
var _sandbox := ScriptSandbox.new()


func _init(context) -> void:
	game = context
	game.online.snap_received.connect(_on_snap)
	game.online.event_received.connect(_on_event)


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
		_replaying = false
		game.load_watch_level(int(s.get("c", -1)), int(s.get("sd", 0)))
		ghost = SpectatorGhost.new()
		ghost.build(game.player)
		ghost.world = WorldSync.new(game.level)
		game.level.actors.add_child(ghost)
		ghost.set_lamp(game.level.dark)
		ghost.push(s)
		game.rig.follow(ghost)
	# Si ya estaba resuelta (o se empezó a mirar tarde) se deja como la tiene el jugador
	if not bool(s.get("ok", false)) or _replaying:
		return
	var room := game.level as ChamberLevel
	if room and not room.solved:
		room.resume_from_save({"solved": true})
	var town := game.level as TownLevel
	if town and not town.gate.is_solved:
		town.gate.mark_solved()
		town.seal.open()


func _on_snap(id: String, s: Dictionary) -> void:
	if id == game.online.watching and is_instance_valid(ghost) and _loaded == "%d:%d" % [int(s.get("c", -1)), int(s.get("sd", 0))]:
		ghost.push(s)


## El jugador corrió su programa en una máquina: la copia del espectador lo repite
## (mismos ejercicios, misma semilla) y se ven las mismas animaciones.
func _on_event(id: String, ev: Dictionary) -> void:
	if id != game.online.watching or _loaded == "" or String(ev.get("k", "")) != "run":
		return
	var machine := game.level.get_node_or_null(NodePath(String(ev.get("m", "")))) as CodeMachine
	if machine == null or machine.is_solved or _replaying:
		return
	var source := String(ev.get("src", ""))
	var report := machine.evaluate(source, _sandbox)
	if not report.ok:
		return
	var level: Level = game.level
	_replaying = true
	machine.show_code(source)
	await machine.perform(report)
	if game.level == level:
		_replaying = false


## Deja de mirar y vuelve el pueblo de fondo.
func stop() -> void:
	look_at("")
	_replaying = false
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
		else:
			_draw_activity(ui, top)
	var list := Rect2(s.x - 470, 20, 446, minf(s.y - 90, 60 + game.online.players.size() * NetBoard.ROW_H + 40))
	ui.panel(list, Color(0.035, 0.045, 0.065, 0.78))
	ui.text(data.message("watch_ranking"), list.position + Vector2(18, 14), 14, UIKit.MUTED, "bold")
	NetBoard.draw(ui, Rect2(list.position + Vector2(10, 40), list.size - Vector2(20, 50)), game.online.players, data, game.online.watching, true)
	ui.text(data.message(keys_key, game.key_names()), Vector2(24, s.y - 40), 16, UIKit.MUTED)


## Qué está haciendo (y, si escribe en el Códice, su código en vivo).
func _draw_activity(ui: UIKit, top: Rect2) -> void:
	var s: Dictionary = game.online.snaps.get(game.online.watching, {})
	if _target_status() != "playing":
		return
	var mode := String(s.get("m", "play"))
	var key := "watch_doing_" + mode
	var doing: String = game.data.message(key)
	if doing != key:
		var w := ui.measure(doing, 16, "bold") + 28
		var at := Vector2(top.position.x, top.end.y + 10)
		ui.pill(Rect2(at, Vector2(w, 28)), Color(UIKit.CYAN, 0.18), UIKit.CYAN)
		ui.text(doing, at + Vector2(14, 4), 16, UIKit.CYAN, "bold", false)
	var code: Dictionary = game.online.codes.get(game.online.watching, {})
	if mode == "codex" and not code.is_empty():
		_draw_code(ui, code, Rect2(top.position.x, top.end.y + 48, minf(640.0, ui.size().x * 0.5), ui.size().y - top.end.y - 110))


func _target_status() -> String:
	return String(target().get("status", ""))


## El Códice de quien se mira: su programa (con el cursor) y lo último de la consola.
func _draw_code(ui: UIKit, code: Dictionary, r: Rect2) -> void:
	var src_lines := String(code.get("src", "")).split("\n")
	var log: Array = code.get("log", [])
	var size := 15
	var step := ui.line_height(size, "mono")
	var console_h := 16.0 + log.size() * step
	# Del alto del programa, sin pasarse de la pantalla
	r.size.y = minf(r.size.y, 64 + maxi(3, src_lines.size()) * step + console_h)
	ui.panel(r, Color(0.02, 0.03, 0.045, 0.92))
	ui.text(String(code.get("title", "")), r.position + Vector2(18, 12), 16, UIKit.GOLD, "bold")
	var room := int((r.size.y - 54 - console_h) / step)
	if room < 1:
		return
	# Si no cabe, se sigue la línea donde está el cursor
	var row := clampi(int(code.get("row", 0)), 0, src_lines.size() - 1)
	var first := clampi(row - room + 2, 0, maxi(0, src_lines.size() - room))
	var y := r.position.y + 42
	for i in range(first, mini(src_lines.size(), first + room)):
		var color := UIKit.TEXT if i != row else UIKit.GOLD
		ui.text("%2d" % (i + 1), Vector2(r.position.x + 14, y), size, UIKit.MUTED, "mono", false)
		var text := String(src_lines[i]).replace("\t", "    ")
		while text.length() > 1 and ui.measure(text, size, "mono") > r.size.x - 70:
			text = text.left(-1)
		ui.text(text, Vector2(r.position.x + 50, y), size, color, "mono", false)
		y += step
	var c := Rect2(r.position.x + 10, r.end.y - console_h - 10, r.size.x - 20, console_h)
	ui.rect(c, Color(0, 0, 0, 0.35))
	for i in log.size():
		var text := String(log[i])
		while text.length() > 1 and ui.measure(text, 14, "mono") > c.size.x - 20:
			text = text.left(-1)
		ui.text(text, c.position + Vector2(10, 8 + i * step), 14, UIKit.CYAN, "mono", false)


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
