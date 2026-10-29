## Atril de práctica: corre la consulta sobre la tabla de la etapa y muestra fila por fila lo que trajo.
class_name QueryMachine
extends CodeMachine

const OUTLINE := Color("14181c")
const GOOD := Color("6be38b")
const BAD := Color("ff5a4e")

var tables: Array = []    # SqlTable de la etapa
var answer := ""
var ordered := false
var rows: Array = []    # lo que muestra cada fila: {"text", "color"}

var _text: Callable
var _font: Font = load(UIKit.PIXEL_FONT)


func setup(text: Callable, open_codex: Callable) -> void:
	_text = text
	view_focus = Vector2(0, -50)
	session.machine = self
	connect_console(open_codex)


## Cada etapa trae su tabla, sus piezas y su respuesta (practices.json).
func set_stage(stage: Dictionary) -> void:
	is_solved = false
	tables = (stage.get("tables", []) as Array).map(func(t): return SqlTable.from_data(t))
	answer = String(stage.get("answer", ""))
	ordered = bool(stage.get("ordered", false))
	session.title = String(stage.get("title", ""))
	session.file_name = String(stage.get("file_name", "consulta.sql"))
	session.code = String(stage.get("starter_code", ""))
	session.help = stage.get("help", [])
	session.tables = tables
	session.set_blocks(stage.get("blocks", []))
	session.log.clear()
	rows.clear()
	show_code(session.code)


func evaluate(source: String, engine: SqlEngine) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var result := engine.run(source, tables)
	if not result.ok:
		report.ok = false
		report.error = result.error_text()
		return report
	report.output = SqlEngine.result_lines(result)
	var want := engine.run(answer, tables)
	var diff := SqlCheck.compare(result, want, ordered)
	report.success = diff.is_empty()
	for i in result.rows.size():
		var mine := " · ".join((result.rows[i] as Array).map(func(v): return SqlEngine.show(v)))
		var right: bool = i < want.rows.size() and mine == " · ".join((want.rows[i] as Array).map(func(v): return SqlEngine.show(v)))
		report.commands.append({"text": mine, "color": GOOD if right or (report.success and not ordered) else BAD})
	report.message = _text.call("query_right", {}) if report.success else _text.call(String(diff.key), diff)
	return report


func perform(report: CodeMachine.Report) -> void:
	rows.clear()
	for c: Dictionary in report.commands:
		rows.append(c)
		await get_tree().create_timer(0.3).timeout
	if report.success:
		await get_tree().create_timer(0.3).timeout
		mark_solved()


func status_text() -> String:
	return _text.call("query_status", {})


func _draw() -> void:
	if tables.is_empty():
		return
	var t: SqlTable = tables[0]
	var size := TableSign.measure(_font, t.columns, t.rows, 7, t.name)
	var top := -40.0 - size.y
	TableSign.draw(self, _font, t.columns, t.rows, Vector2(-size.x - 6, top), 7, t.name)
	# Lo que trajo la consulta, a la derecha
	var y := top
	TableSign.text(self, _font, "→", Vector2(2, y + 30), 9, Color("b48a4e"))
	for r: Dictionary in rows:
		TableSign.text(self, _font, String(r.text), Vector2(16, y + 12), 7, r.color)
		y += 11
