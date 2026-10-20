## Base de las salas: resolver, rejas, salida y alarma.
class_name ChamberLevel
extends Level

var index := 0
var solved := false
var alarm: AlarmDirector

var _restoring := false    # cargando partida: sin temblor ni sonido


func _wire_common() -> void:
	super()
	for exit in nodes_of(ExitZone):
		exit.crossed.connect(_on_exit_crossed)
	alarm = AlarmDirector.new()
	alarm.name = "Alarma"
	add_child(alarm)
	alarm.setup(_game, self)


## Llamar al resolver la sala.
func open_exit() -> void:
	if solved:
		return
	solved = true
	alarm.calm()
	if not _restoring:
		_game.health.heal(int(_game.combat("heal_on_solve", 0)))
		_game.bus.publish(GameEvents.CHAMBER_CLEARED, {"index": index})
		_game.rig.shake(3.0)
	for grate in nodes_of(Grate):
		grate.open()


## Con guardianes despiertos la máquina no acepta código.
func machine_blocked() -> bool:
	if alarm and alarm.fighting():
		_game.notify([_game.data.message("alarm_machine_locked")], 3.0)
		return true
	return false


func lock_machines(on: bool) -> void:
	for m in nodes_of(CodeMachine):
		m.set_locked(on)


## Tala vuelve a la entrada de la sala.
func room_entrance() -> Vector2:
	if has_node("Zonas/EntradaSala/Punto"):
		return (get_node("Zonas/EntradaSala/Punto") as Marker2D).global_position
	return spawn


## Lo que se guarda de la sala.
func save_state() -> Dictionary:
	var out := {"solved": solved}
	var machines := nodes_of(CodeMachine)
	if not machines.is_empty():
		out["code"] = machines[0].session.code
		out["machine_solved"] = machines[0].is_solved
	return out


## Al cargar partida: Tala en la entrada, con su código y la sala como estaba.
func resume_from_save(state: Dictionary) -> void:
	for machine in nodes_of(CodeMachine):
		machine.session.code = String(state.get("code", machine.session.code))
		machine.show_code(machine.session.code)
	var zone := get_node_or_null("Zonas/EntradaSala") as TriggerZone
	if zone:
		zone.mark_fired()
	checkpoint = room_entrance()
	_game.player.place(checkpoint, Vector2.UP)
	if bool(state.get("solved", false)):
		if "_in_hall" in self:
			set("_in_hall", true)
		_restoring = true
		restore_solved()
		_restoring = false
		return
	if has_method("_on_hall_entered"):
		call("_on_hall_entered")
	if bool(state.get("machine_solved", false)):
		for machine in nodes_of(CodeMachine):
			machine.mark_solved()


## Deja la sala resuelta. Las salas sin máquina la cambian.
func restore_solved() -> void:
	for machine in nodes_of(CodeMachine):
		machine.mark_solved()
	open_exit()


func restart_after_death() -> void:
	alarm.reset_after_death()
	checkpoint = room_entrance()
	_game.player.place(checkpoint, Vector2.UP)


func _on_exit_crossed() -> void:
	if not solved:
		return
	if _game.data.chamber_count() > index + 1:
		_game.enter_chamber(index + 1)
	else:
		_game.finish(true, "ending_trial")
