## PATRÓN STATE — El Códice abierto: se escribe y se ejecuta código. El jugador no se mueve,
## el mouse queda libre y el reloj de 15 minutos sigue corriendo.
## Si la sesión es de una máquina (CodeMachine), la cámara la encuadra, el Códice se abre al
## costado y, al ejecutar, se repliega para ver a la máquina hacer lo que ordenó el programa.
## Si la máquina rechaza el código (por el motivo que sea, también un error de escritura),
## se publica MACHINE_FAILED: en las salas eso despierta a los guardianes.
class_name CodexState
extends GameState

var _session: CodexSession
var _sandbox := ScriptSandbox.new()
var _watching := false     # la máquina está mostrando el programa (el Códice está replegado)


func enter(params: Dictionary = {}) -> void:
	_session = params.get("session")
	_watching = false
	var machine := _session.machine
	if machine:
		game.rig.frame(machine.view_center(), machine.view_zoom, 0.6)
	game.codex.open(_session, game.data.message("codex_keys", game.key_names()), machine != null)
	if not game.codex.run_requested.is_connected(run):
		game.codex.run_requested.connect(run)


func exit() -> void:
	_session.code = game.codex.close()
	if _session.machine:
		_session.machine.show_code(_session.code)


func timer_runs() -> bool:
	return true


func handle_input(actions: Array) -> void:
	if _watching:
		return
	if "cancel" in actions or "pause" in actions:
		game.bus.publish(GameEvents.MENU_CONFIRM)
		game.machine.change("play")
	elif "run_code" in actions:
		run()


## Ejecuta el programa del editor con los objetos de la sala.
func run() -> void:
	if _watching:
		return
	var source: String = game.codex.editor.text
	_session.code = source
	var used := CodexSession.count_lines(source)
	if _session.max_lines > 0 and used > _session.max_lines:
		var too_long: String = game.data.message("codex_too_long", {"n": used, "max": _session.max_lines})
		game.codex.log_line(too_long, "ff5a4e")
		game.bus.publish(GameEvents.CODE_FAILED)
		_machine_failed(too_long)
		return
	game.codex.log_line("> ejecutar %s" % _session.file_name, "8d97a8")
	if _session.machine:
		_run_on_machine(source)
		return
	var api: Dictionary = _session.api_factory.call() if _session.api_factory.is_valid() else {}
	var result := _sandbox.run(source, api, _session.max_steps)
	for line in result.output:
		game.codex.log_line(line)
	if not result.ok:
		game.codex.log_line(result.error_text(), "ff5a4e")
		game.bus.publish(GameEvents.CODE_FAILED, {"error": result.error})
	else:
		game.bus.publish(GameEvents.CODE_RAN)
	if _session.on_result.is_valid():
		var message: String = _session.on_result.call(result)
		if message != "":
			game.codex.log_line(message, "6be38b" if result.ok else "ff9a6b")
	if result.ok and _session.close_after_run:
		game.machine.change("play")


## La máquina corre el programa con todos sus casos y, si no hay errores de Python, lo
## muestra pieza por pieza con el Códice replegado. Si falló, el Códice vuelve con el motivo.
func _run_on_machine(source: String) -> void:
	var machine := _session.machine
	var report := machine.evaluate(source, _sandbox)
	for line in report.output:
		game.codex.log_line(line)
	if not report.ok:
		game.codex.log_line(report.error, "ff5a4e")
		game.bus.publish(GameEvents.CODE_FAILED, {"error": report.error})
		_machine_failed(report.error)
		return
	game.bus.publish(GameEvents.CODE_RAN)
	machine.show_code(source)
	_watching = true
	game.codex.fold(true)
	await machine.perform(report)
	_watching = false
	if game.machine.current != self:
		return
	game.codex.fold(false)
	if report.message != "":
		game.codex.log_line(report.message, "6be38b" if report.success else "ff9a6b")
	if report.success:
		game.machine.change("play")
		game.dialog.say([report.message])
	else:
		_machine_failed(report.message)


func _machine_failed(message: String) -> void:
	if _session.machine:
		game.bus.publish(GameEvents.MACHINE_FAILED, {"machine": _session.machine, "message": message})


func draw(ui: UIKit) -> void:
	if game.timer.active:
		Hud.new().draw_timer(ui, game.timer)
	if _watching and _session.machine:
		var s := ui.size()
		ui.text_centered(_session.machine.status_text(), s.y - 70, 22, UIKit.CYAN)
