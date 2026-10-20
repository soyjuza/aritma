@tool
## El Mural (Sala 2). Patrón Command: perform() prueba las filas (RootsCommand).
class_name MuralMachine
extends CodeMachine

const W := 200.0
const ROW_H := 18.0
const TOP := -112.0
const LEFT := -100.0

const OUTLINE := Color("14181c")
const STONE_DARK := Color("27342e")
const STONE := Color("3e5246")
const STONE_LIGHT := Color("6a8070")
const BRONZE := Color("b48a4e")
const BRONZE_DARK := Color("6e5232")
const PLAQUE := Color("1b2226")
const CYAN := Color("3fe0ff")
const GOLD := Color("ffc857")
const GREEN := Color("6be38b")
const RED := Color("ff5a4e")

var trial: RootsTrial
var max_steps := 12000

var _kit: TileKit
var _bus: EventBus
var _data: Dictionary
var _text: Callable
var _rng := RandomNumberGenerator.new()
var _font: Font = load(UIKit.PIXEL_FONT)
var _rows: Array = []
var _active := -1

@onready var _light: PointLight2D = $Luz


func setup(kit: TileKit, bus: EventBus, data: Dictionary, text: Callable, open_codex: Callable) -> void:
	_kit = kit
	_bus = bus
	_data = data
	_text = text
	var seed_value := int(data.get("seed", 0))
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	max_steps = int(data.get("max_steps", 12000))
	view_focus = Vector2(0, -60)
	session.title = String(data.get("name", ""))
	session.file_name = String(data.get("file_name", "incognita.py"))
	session.code = String(data.get("starter_code", ""))
	session.help = data.get("help", [])
	session.max_steps = max_steps
	session.machine = self
	connect_console(open_codex)
	new_trial()


## Ecuaciones nuevas.
func new_trial() -> void:
	trial = RootsTrial.new(_data.get("cases", []), _rng)
	_rows.clear()
	for i in trial.cases.size():
		var c: Dictionary = trial.cases[i]
		_rows.append({"poly": RootsTrial.equation(c.a, c.b, c.c), "result": "", "color": Color("8d97a8"), "lamp": Color("2a3036"), "angle": 0.0, "revealed": i == 0})
	_active = -1


func status_text() -> String:
	return _text.call("mural_status", {"row": maxi(_active, 0) + 1, "of": _rows.size()})


# ------------------------------------------------------------------ evaluar (sin dibujar)

func evaluate(source: String, sandbox: ScriptSandbox) -> CodeMachine.Report:
	var report := CodeMachine.Report.new()
	var program := sandbox.run(source, {}, max_steps)
	report.output = program.output
	if not program.ok:
		report.ok = false
		report.error = program.error_text()
		return report
	var fn = program.context.globals.get("despejar")
	if not fn is ScriptCallable:
		report.ok = false
		report.error = _text.call("mural_no_function", {})
		return report
	report.success = true
	for i in trial.cases.size():
		var c: Dictionary = trial.cases[i]
		program.context.max_steps = max_steps
		var answer := sandbox.call_function(program, "despejar", [c.a, c.b, c.c])
		var steps: int = program.context.steps
		var verdict := RootsTrial.Verdict.ERROR
		var shown := ""
		if not answer[0]:
			var slow: bool = steps > max_steps
			verdict = RootsTrial.Verdict.TOO_SLOW if slow else RootsTrial.Verdict.ERROR
			shown = _text.call("mural_row_slow" if slow else "mural_row_error", {})
			report.message = _text.call("mural_too_slow" if slow else "mural_error", {"a": c.a, "b": c.b, "c": c.c, "max": max_steps, "error": answer[1]})
		else:
			verdict = RootsTrial.judge(c, answer[1])
			match verdict:
				RootsTrial.Verdict.RIGHT:
					shown = RootsTrial.answer(answer[1])
				RootsTrial.Verdict.BAD_SHAPE:
					shown = ScriptContext.to_text(answer[1])
					report.message = _text.call("mural_bad_shape", {"a": c.a, "b": c.b, "c": c.c, "got": shown})
				_:
					shown = RootsTrial.answer(answer[1])
					report.message = _text.call("mural_wrong", {"a": c.a, "b": c.b, "c": c.c, "got": ScriptContext.to_text(answer[1]), "eq": RootsTrial.equation(c.a, c.b, c.c), "want": c.x})
		report.commands.append(RootsCommand.new(i, verdict, shown, steps))
		if verdict != RootsTrial.Verdict.RIGHT:
			report.success = false
			break
	if report.success:
		report.message = _text.call("mural_solved", {})
	return report


# ------------------------------------------------------------------ mostrar (invocador)

func perform(report: CodeMachine.Report) -> void:
	for command: RootsCommand in report.commands:
		await command.run(self)
	_active = -1
	if report.success:
		_bus.publish(GameEvents.MACHINE_ROUND)
		var t := create_tween()
		t.tween_property(_light, "energy", 2.0, 0.4)
		t.tween_property(_light, "color", GOLD, 0.4)
		await t.finished
		mark_solved()
	else:
		await _wait(1.0)
		new_trial()


## Prueba una fila.
func test_row(index: int, verdict: RootsTrial.Verdict, shown: String, _steps: int) -> void:
	_active = index
	var row: Dictionary = _rows[index]
	row.revealed = true
	row.lamp = CYAN
	_bus.publish(GameEvents.MACHINE_STEP)
	var spin := create_tween()
	spin.tween_method(func(a: float): row.angle = a, 0.0, TAU * 1.5, 0.55)
	await spin.finished
	row.result = shown
	if verdict == RootsTrial.Verdict.RIGHT:
		row.color = GREEN
		row.lamp = GOLD
		_bus.publish(GameEvents.MACHINE_GOOD)
	else:
		row.color = RED
		row.lamp = RED
		_bus.publish(GameEvents.MACHINE_BAD)
		var sparks := _kit.particles(self, _gear_center(index), "Spark", 16, 0.7)
		sparks.emitting = true
		var smoke := _kit.particles(self, _gear_center(index), "Smoke", 8, 1.2)
		smoke.gravity = Vector2(0, -30)
		smoke.emitting = true
		await _wait(1.2)
		sparks.queue_free()
		smoke.queue_free()
	await _wait(0.25)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# ------------------------------------------------------------------ dibujo

func _gear_center(i: int) -> Vector2:
	return Vector2(LEFT + 14, TOP + 18 + i * ROW_H + ROW_H / 2.0)


func _draw() -> void:
	if Engine.is_editor_hint() and _rows.is_empty():
		_preview_rows()
	var height := 22 + _rows.size() * ROW_H + 10
	var panel := Rect2(LEFT, TOP, W, height)
	draw_rect(panel.grow(3), OUTLINE)
	draw_rect(panel.grow(2), BRONZE_DARK)
	draw_rect(panel, STONE)
	draw_rect(Rect2(LEFT, TOP, W, 3), STONE_LIGHT)
	draw_rect(Rect2(LEFT - 3, TOP - 6, W + 6, 4), BRONZE)
	var title := String(_data.get("mural_title", ""))
	_text_center(title, Vector2(0, TOP + 13), 8, GOLD)
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var y := TOP + 18 + i * ROW_H
		draw_rect(Rect2(LEFT + 4, y + 1, W - 8, ROW_H - 2), STONE_DARK if i != _active else STONE_DARK.lerp(CYAN, 0.12))
		_gear(_gear_center(i), row.angle, row.lamp)
		# Ecuación
		draw_rect(Rect2(LEFT + 26, y + 3, 78, ROW_H - 6), PLAQUE)
		var poly: String = row.poly if row.revealed else String(_data.get("hidden_label", "? ? ?"))
		_text_center(poly, Vector2(LEFT + 65, y + 12.5), 8, Color("e9f7ff") if row.revealed else Color("5a6672"))
		_text_center("=", Vector2(LEFT + 109, y + 12.5), 8, BRONZE)
		# Resultado
		draw_rect(Rect2(LEFT + 114, y + 3, 72, ROW_H - 6), PLAQUE)
		if row.result != "":
			_text_center(row.result, Vector2(LEFT + 150, y + 12.5), 8, row.color)
		# Lámpara
		draw_circle(Vector2(LEFT + W - 8, y + ROW_H / 2.0), 3.5, OUTLINE)
		draw_circle(Vector2(LEFT + W - 8, y + ROW_H / 2.0), 2.5, row.lamp)


## Filas vacías para verlo en el editor.
func _preview_rows() -> void:
	for i in 3:
		_rows.append({"poly": "", "result": "", "color": Color("8d97a8"), "lamp": Color("2a3036"), "angle": 0.0, "revealed": false})


func _gear(c: Vector2, angle: float, glow: Color) -> void:
	var teeth := 8
	var pts := PackedVector2Array()
	for k in teeth * 2:
		var a := angle + k * PI / teeth
		pts.append(c + Vector2.RIGHT.rotated(a) * (7.0 if k % 2 == 0 else 5.5))
	draw_colored_polygon(pts, BRONZE)
	draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 1.0)
	draw_circle(c, 2.2, glow)


## Texto centrado y nítido.
func _text_center(text: String, at: Vector2, size: int, color: Color) -> void:
	var big := size * 2
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	draw_set_transform(at.round(), 0.0, Vector2(0.5, 0.5))
	draw_string_outline(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, 4, OUTLINE)
	draw_string(_font, Vector2(-w / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, big, color)
	draw_set_transform(Vector2.ZERO)
