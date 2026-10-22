## Atril de la práctica de funciones: llama a la función del jugador y muestra lo que devuelve.
class_name FunctionMachine
extends CodeMachine

const W := 150.0
const ROW_H := 18.0
const TOP := -96.0
const OUTLINE := Color("14181c")
const STONE := Color("3e5246")
const STONE_DARK := Color("27342e")
const BRONZE := Color("b48a4e")
const PLAQUE := Color("1b2226")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")

var function_name := ""
var cases: Array = []    # [[argumentos], esperado]
var rows: Array = []    # lo que muestra cada fila

var _text: Callable
var _font: Font = load(UIKit.PIXEL_FONT)


func setup(text: Callable, open_codex: Callable) -> void:
	_text = text
	view_focus = Vector2(0, -50)
	session.machine = self
	connect_console(open_codex)


func set_stage(stage: Dictionary) -> void:
	is_solved = false
	function_name = String(stage.get("function", ""))
	cases = stage.get("cases", [])
	session.title = String(stage.get("title", ""))
	session.file_name = function_name + ".py"
	session.code = String(stage.get("starter_code", ""))
	session.help = stage.get("help", [])
	session.set_blocks(stage.get("blocks", []))
	session.log.clear()
	rows = cases.map(func(_c): return {"result": "?", "color": Color("8d97a8")})
	show_code(session.code)


## "doble(3)"
func call_text(args: Array) -> String:
	return "%s(%s)" % [function_name, ", ".join(args.map(func(a): return str(a)))]


func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var program := sandbox.run(source, {}, session.max_steps)
	report.output = program.output
	if not program.ok:
		report.ok = false
		report.error = program.error_text()
		return report
	if not program.context.globals.get(function_name) is ScriptCallable:
		report.ok = false
		report.error = _text.call("function_missing", {"name": function_name})
		return report
	report.success = true
	for c in cases:
		var answer := sandbox.call_function(program, function_name, c[0])
		var got = answer[1] if answer[0] else null
		var right: bool = answer[0] and typeof(got) in [TYPE_INT, TYPE_FLOAT] and is_equal_approx(float(got), float(c[1]))
		report.commands.append([ScriptContext.to_text(got) if answer[0] else "error", right])
		if not right:
			report.success = false
			if answer[0]:
				report.message = _text.call("function_wrong", {"call": call_text(c[0]), "got": ScriptContext.to_text(got), "want": c[1]})
			else:
				report.message = _text.call("function_error", {"call": call_text(c[0]), "error": answer[1]})
			break
	if report.success:
		report.message = _text.call("function_right", {"name": function_name})
	return report


func perform(report: CodeMachine.Report) -> void:
	for i in rows.size():
		rows[i] = {"result": "?", "color": Color("8d97a8")}
	for i in report.commands.size():
		var shown: Array = report.commands[i]
		rows[i] = {"result": shown[0], "color": GREEN if shown[1] else RED}
		await get_tree().create_timer(0.5).timeout
	if report.success:
		await get_tree().create_timer(0.3).timeout
		mark_solved()


func status_text() -> String:
	return _text.call("function_status", {"name": function_name})


func _draw() -> void:
	if rows.is_empty():
		return
	var panel := Rect2(-W / 2, TOP, W, 20 + rows.size() * ROW_H)
	draw_rect(panel.grow(3), OUTLINE)
	draw_rect(panel.grow(2), BRONZE)
	draw_rect(panel, STONE)
	_text_center(session.title, Vector2(0, TOP + 12), GOLD)
	for i in rows.size():
		var y := TOP + 17 + i * ROW_H
		draw_rect(Rect2(-W / 2 + 4, y + 1, W - 8, ROW_H - 2), STONE_DARK)
		draw_rect(Rect2(-W / 2 + 8, y + 3, 76, ROW_H - 6), PLAQUE)
		_text_center(call_text(cases[i][0]), Vector2(-W / 2 + 46, y + 12.5), Color("e9f7ff"))
		_text_center("→", Vector2(-W / 2 + 92, y + 12.5), BRONZE)
		draw_rect(Rect2(-W / 2 + 100, y + 3, 42, ROW_H - 6), PLAQUE)
		_text_center(String(rows[i].result), Vector2(-W / 2 + 121, y + 12.5), rows[i].color)


func _text_center(text: String, at: Vector2, color: Color) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, OUTLINE)
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
	draw_set_transform(Vector2.ZERO)
