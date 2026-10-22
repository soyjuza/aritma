## Atril de la práctica de bloques: enciende los braseros con antorchas.encender().
class_name TorchMachine
extends CodeMachine

var braziers: Array = []
var goal := 1
var lit := 0

var _text: Callable


func setup(text: Callable, p_braziers: Array, open_codex: Callable) -> void:
	_text = text
	braziers = p_braziers
	view_focus = Vector2(0, -40)
	session.machine = self
	session.file_name = "antorchas.py"
	for b in braziers:
		_set_fire(b, false)
	connect_console(open_codex)


## Cada etapa trae sus piezas y cuántos braseros pide.
func set_stage(stage: Dictionary) -> void:
	is_solved = false
	goal = int(stage.get("goal", 1))
	session.title = String(stage.get("title", ""))
	session.code = String(stage.get("starter_code", ""))
	session.help = stage.get("help", [])
	session.set_blocks(stage.get("blocks", []))
	session.log.clear()
	show_code(session.code)


func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var torches := TorchAdapter.new(lit, braziers.size())
	var result := sandbox.run(source, {"antorchas": torches}, session.max_steps)
	report.output = result.output
	report.ok = result.ok
	report.error = result.error_text() if not result.ok else ""
	report.success = result.ok and torches.lit >= goal
	report.commands = [torches.lit]
	report.message = _text.call("torch_done" if report.success else "torch_missing", {"lit": torches.lit, "goal": goal})
	return report


func perform(report: CodeMachine.Report) -> void:
	var target: int = report.commands[0]
	while lit < target:
		_set_fire(braziers[lit], true)
		lit += 1
		await get_tree().create_timer(0.3).timeout
	while lit > target:
		lit -= 1
		_set_fire(braziers[lit], false)
		await get_tree().create_timer(0.3).timeout
	if report.success:
		await get_tree().create_timer(0.4).timeout
		mark_solved()


func status_text() -> String:
	return _text.call("torch_status", {"lit": lit, "total": braziers.size()})


static func _set_fire(brazier: Node, on: bool) -> void:
	(brazier.get_node("Fuego") as CPUParticles2D).emitting = on
	(brazier.get_node("Luz") as Node2D).visible = on
