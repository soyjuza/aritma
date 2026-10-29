## Atril de la práctica de piezas: enciende un brasero por cada fila que trae la consulta.
class_name TorchMachine
extends CodeMachine

var braziers: Array = []
var lit := 0
var tables: Array = []    # SqlTable de la etapa
var answer := ""

var _text: Callable


func setup(text: Callable, p_braziers: Array, open_codex: Callable) -> void:
	_text = text
	braziers = p_braziers
	view_focus = Vector2(0, -40)
	session.machine = self
	for b in braziers:
		_set_fire(b, false)
	connect_console(open_codex)


## Cada etapa trae su tabla, sus piezas y su respuesta (practices.json).
func set_stage(stage: Dictionary) -> void:
	is_solved = false
	tables = (stage.get("tables", []) as Array).map(func(t): return SqlTable.from_data(t))
	answer = String(stage.get("answer", ""))
	session.title = String(stage.get("title", ""))
	session.file_name = String(stage.get("file_name", "braseros.sql"))
	session.code = String(stage.get("starter_code", ""))
	session.help = stage.get("help", [])
	session.tables = tables
	session.set_blocks(stage.get("blocks", []))
	session.log.clear()
	show_code(session.code)


func evaluate(source: String, engine: SqlEngine) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var result := engine.run(source, tables)
	if not result.ok:
		report.ok = false
		report.error = result.error_text()
		return report
	report.output = SqlEngine.result_lines(result)
	var diff := SqlCheck.compare(result, engine.run(answer, tables), false)
	report.success = diff.is_empty()
	report.commands = [mini(result.rows.size(), braziers.size())]
	report.message = _text.call("torch_done", {"lit": result.rows.size()}) if report.success else _text.call(String(diff.key), diff)
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
