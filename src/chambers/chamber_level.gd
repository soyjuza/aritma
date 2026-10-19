## Base de las salas de desafío: guardan su número, si ya se resolvieron y la salida. Al
## resolver la sala se levantan sus rejas (nodos Grate); al cruzar la salida (ExitZone) se pasa
## a la siguiente sala (o, si todavía no existe, termina la versión de prueba).
## Cada sala tiene su Director de Alarma: los errores en la máquina despiertan guardianes.
class_name ChamberLevel
extends Level

var index := 0
var solved := false
var alarm: AlarmDirector


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
	_game.health.heal(int(_game.combat("heal_on_solve", 0)))    # 0: resolver no cura
	_game.bus.publish(GameEvents.CHAMBER_CLEARED, {"index": index})
	_game.rig.shake(3.0)
	for grate in nodes_of(Grate):
		grate.open()


## Mientras haya guardianes despiertos la máquina no acepta código (avisa y devuelve true).
func machine_blocked() -> bool:
	if alarm and alarm.fighting():
		_game.notify([_game.data.message("alarm_machine_locked")], 3.0)
		return true
	return false


func lock_machines(on: bool) -> void:
	for m in nodes_of(CodeMachine):
		m.set_locked(on)


## Dónde vuelve Tala tras quedarse sin corazones: la entrada de la sala (no el pasillo).
func room_entrance() -> Vector2:
	if has_node("Zonas/EntradaSala/Punto"):
		return (get_node("Zonas/EntradaSala/Punto") as Marker2D).global_position
	return spawn


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
