@tool
## Puerta de la montaña: se abre con puerta.abrir().
class_name GateMachine
extends CodeMachine

var gate_open := false

var _open_fn: Callable
var _close_fn: Callable
var _text: Callable


func setup(data: Dictionary, text: Callable, open_fn: Callable, close_fn: Callable, open_codex: Callable) -> void:
	_open_fn = open_fn
	_close_fn = close_fn
	_text = text
	view_focus = Vector2(-28, -24)
	session.title = String(data.get("gate_title", "La Puerta"))
	session.file_name = "puerta.py"
	session.code = String(data.get("gate_code", ""))
	session.help = data.get("gate_help", [])
	session.machine = self
	connect_console(open_codex)


func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var wanted := [gate_open]
	var api := {"puerta": DoorAdapter.new(func(): wanted[0] = true, func(): return wanted[0], func(): wanted[0] = false)}
	var result := sandbox.run(source, api, session.max_steps)
	report.output = result.output
	report.ok = result.ok
	report.error = result.error_text() if not result.ok else ""
	report.success = result.ok and wanted[0]
	report.commands = [wanted[0]]
	report.message = _text.call("gate_opened_log" if report.success else "gate_not_opened_log", {})
	return report


func perform(report: CodeMachine.Report) -> void:
	var want: bool = report.commands[0]
	if want and not gate_open:
		gate_open = true
		await _open_fn.call()
		mark_solved()
	elif not want and gate_open:
		gate_open = false
		await _close_fn.call()
