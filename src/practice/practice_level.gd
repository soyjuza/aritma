## Base de las salas de práctica: pasos guiados y el reloj quieto.
## Patrón Template Method: cada práctica dice cuándo se cumple cada paso.
class_name PracticeLevel
extends Level

var key := ""    # nombre en chambers.json "practices"
var next_chamber := 0
var step := 0
var finished := false

var _arrow := GuideArrow.new()
var _panel_end := 0.0


func _wire_common() -> void:
	super()
	objective_key = "objective_practice"
	fx.add_child(_arrow)
	for exit in nodes_of(ExitZone):
		exit.crossed.connect(_on_exit_crossed)
	_game.dialog.say(data.get("intro", []))
	_show_step.call_deferred()


func steps() -> Array:
	return data.get("steps", [])


func step_id() -> String:
	return String(steps()[step].get("id", "")) if step < steps().size() else ""


## Marca un paso como hecho si es el actual.
func complete(id: String) -> void:
	if finished or id != step_id():
		return
	step += 1
	set_checkpoint(_game.player.global_position)
	_game.bus.publish(GameEvents.MACHINE_ROUND)
	if step >= steps().size():
		_finish()
		return
	_game.notify([_game.data.message("practice_step_done")], 2.0, true)
	_show_step()


## Vuelve a un paso anterior (por ejemplo, si explota una mina).
func back_to(id: String) -> void:
	for i in steps().size():
		if steps()[i].get("id", "") == id:
			step = i
			_show_step()
			return


func _show_step() -> void:
	on_step(step_id())
	_arrow.target = guide_point(step_id())


## Cada práctica prepara su paso.
func on_step(_id: String) -> void:
	pass


## Dónde apunta la flecha en este paso (Vector2.INF = ninguna).
func guide_point(id: String) -> Vector2:
	var marker := get_node_or_null("Marcas/" + id) as Node2D
	return marker.global_position if marker else Vector2.INF


func _finish() -> void:
	finished = true
	_arrow.target = Vector2.INF
	for grate in nodes_of(Grate):
		grate.open()
		_arrow.target = grate.global_position + Vector2(16, 0)
	_game.notify([_game.data.message("practice_done_banner")], 5.0, true)
	_game.dialog.say.call_deferred(data.get("done", []))


func _on_exit_crossed() -> void:
	if finished:
		_game.leave_practice()


func _on_player_fell() -> void:
	_game.bus.publish(GameEvents.PLAYER_FELL)
	_game.notify([_game.data.message("practice_fell")], 3.0)
	await get_tree().create_timer(0.7).timeout
	respawn_player()


## Texto del paso con las teclas de los ajustes.
func step_text() -> String:
	if finished:
		return _game.data.message("practice_go_on")
	var info: Dictionary = steps()[step]
	var text := String(info.get("touch_text", info.text) if _game.data.touch else info.get("text", ""))
	return text.format(_game.key_names())


## Cuadro de la práctica arriba a la derecha.
func draw_hud(ui: UIKit) -> void:
	var s := ui.size()
	var width := 430.0
	var lines := ui.wrap(step_text(), width - 40, 20)
	var r := Rect2(s.x - width - 24, 20, width, 92 + lines.size() * 26)
	ui.panel(r)
	_panel_end = r.end.y
	ui.text(_game.data.message("practice_kicker", {"title": title}), r.position + Vector2(20, 14), 15, UIKit.CYAN, "bold")
	var count: String = _game.data.message("practice_count", {"n": mini(step + 1, steps().size()), "of": steps().size()})
	ui.text_right(count, r.end.x - 20, r.position.y + 14, 15, UIKit.MUTED, "bold")
	for i in lines.size():
		ui.text(lines[i], r.position + Vector2(20, 42 + i * 26), 20, UIKit.GOOD if finished else UIKit.TEXT)


## El aviso va debajo del cuadro para no taparlo.
func notice_top() -> float:
	return maxf(104.0, _panel_end + 14.0)
